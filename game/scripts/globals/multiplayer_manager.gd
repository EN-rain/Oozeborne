extends Node

 
class MatchState:
	var data: String
	var op_code: int
	var presence: Presence = null

class Presence:
	var user_id: String

# --- Custom Networking (Replaces Nakama) ---
var auth_token: String = ""
var user_id: String = ""
var username: String = ""
var player_ign: String = ""
var account_email: String = ""

var socket: WebSocketPeer = WebSocketPeer.new()
var match_id: String = ""
var room_code: String = ""
var lobby_name: String = ""
var is_host: bool = false
var is_admin: bool = false
var players: Dictionary = {}  # user_id -> {ign, is_host, slime_variant}
var player_classes: Dictionary = {} # user_id -> PlayerClass
var player_subclasses: Dictionary = {} # user_id -> PlayerClass
var player_slime_variant: String = "blue"
var player_class: PlayerClass = null
var player_subclass: PlayerClass = null
var subclass_choice_made: bool = false
var player_level: int = 1
var match_phase: String = "lobby"

# Configuration
const SERVER_CONFIG_FILE = "server_config.cfg"
const TOKEN_SAVE_PATH = "user://auth_session.json"
var _base_url: String = "http://35.247.150.45:3000"

# Signals
signal player_joined(user_id: String, ign: String, is_host_flag: bool)
signal player_left(user_id: String)
signal match_joined()
signal auth_state_changed(is_authenticated: bool, username: String, email: String)
signal connection_lost()
signal received_match_state(match_state)

func _ready():
	_load_config()
	set_process(true)

func _load_config():
	var config = ConfigFile.new()
	if config.load("res://" + SERVER_CONFIG_FILE) == OK:
		var host = config.get_value("server", "host", "35.247.150.45")
		var port = config.get_value("server", "port", 3000)
		var scheme = config.get_value("server", "scheme", "http")
		_base_url = "%s://%s:%d" % [scheme, host, port]

func _process(_delta):
	socket.poll()
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count() > 0:
			var packet = socket.get_packet()
			_on_data_received(packet.get_string_from_utf8())
	elif state == WebSocketPeer.STATE_CLOSED:
		# Handle unexpected close
		pass

# --- Auth Methods (API Compatibility) ---

func is_authenticated() -> bool:
	return not auth_token.is_empty()

func clear_session():
	auth_token = ""
	user_id = ""
	username = ""
	if FileAccess.file_exists(TOKEN_SAVE_PATH):
		DirAccess.remove_absolute(TOKEN_SAVE_PATH)
	auth_state_changed.emit(false, "", "")

func restore_saved_session():
	if not FileAccess.file_exists(TOKEN_SAVE_PATH):
		return {"success": false}
	
	var file = FileAccess.open(TOKEN_SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	if data and data.has("token"):
		auth_token = data.token
		user_id = data.user_id
		username = data.username
		player_ign = data.username
		auth_state_changed.emit(true, username, "")
		return {"success": true}
	return {"success": false}

func login_with_email(p_email, p_password):
	var uname = p_email
	# Normalize username/email if it's not a full email (to match normalized DB usernames)
	# However, if it's a full email, we should probably keep it as is since the DB email column isn't normalized
	if not "@" in uname:
		var regex = RegEx.new()
		regex.compile("[^a-zA-Z0-9_]")
		uname = regex.sub(uname, "_", true)
		
	var body = JSON.stringify({"username": uname, "password": p_password})
	var result = await _http_request("/auth/login", HTTPClient.METHOD_POST, body)
	if result.has("token"):
		auth_token = result.token
		user_id = result.user_id
		username = result.username
		player_ign = result.username
		_save_session(result)
		auth_state_changed.emit(true, username, p_email)
		return {"success": true}
	
	var error_msg = "Login failed"
	if result.has("error"):
		error_msg = result.error
	elif result.has("errors") and result.errors is Array:
		error_msg = ", ".join(result.errors)
		
	return {"success": false, "error": error_msg}

func register_with_email(p_email, p_password, p_username = ""):
	var uname = p_username if not p_username.is_empty() else p_email.split("@")[0]
	# Normalize username to meet API requirements (alphanumeric and underscores only)
	var regex = RegEx.new()
	regex.compile("[^a-zA-Z0-9_]")
	uname = regex.sub(uname, "_", true)
	
	if uname.length() < 3:
		uname += "_usr"
		
	var body = JSON.stringify({"username": uname, "email": p_email, "password": p_password})
	var result = await _http_request("/auth/register", HTTPClient.METHOD_POST, body)
	if result.has("token"):
		auth_token = result.token
		user_id = result.user_id
		username = result.username
		player_ign = result.username
		_save_session(result)
		auth_state_changed.emit(true, username, p_email)
		return {"success": true}
	
	var error_msg = "Registration failed"
	if result.has("error"):
		error_msg = result.error
	elif result.has("errors") and result.errors is Array:
		error_msg = ", ".join(result.errors)
	
	return {"success": false, "error": error_msg}

# --- Room Methods ---

func create_room(title = "Moon Room"):
	var body = JSON.stringify({"title": title})
	var result = await _http_request("/rooms/create", HTTPClient.METHOD_POST, body)
	if result.has("ws_url"):
		room_code = result.room_code
		match_id = result.room_id
		is_host = true
		_connect_to_game_server(result.ws_url)
		return room_code
	return ""

func logout():
	clear_session()

func disconnect_server():
	socket.close()
	match_id = ""
	room_code = ""
	is_host = false
	players.clear()

func get_server_endpoint_summary() -> String:
	return _base_url

func get_last_room_error() -> String:
	return ""

func resolve_player_scene() -> PackedScene:
	var variant_path = SlimePaletteRegistry.get_scene_path(player_slime_variant)
	if variant_path.is_empty():
		return null
	return load(variant_path) as PackedScene

func is_socket_open() -> bool:
	return socket.get_ready_state() == WebSocketPeer.STATE_OPEN

func join_room(p_room_code):
	var body = JSON.stringify({"room_code": p_room_code})
	var result = await _http_request("/rooms/join", HTTPClient.METHOD_POST, body)
	if result.has("ws_url"):
		room_code = result.room_code
		match_id = result.room_id
		is_host = false
		_connect_to_game_server(result.ws_url)
		return true
	return false

# --- Internal Helpers ---

func connect_to_server(_p_room_code: String) -> bool:
	# In our custom system, we don't need a separate connect call before creating/joining
	# but we return true to satisfy the UI flow.
	return true

func get_player_class(p_user_id: String):
	return player_classes.get(p_user_id, null)

func set_player_class(p_user_id: String, p_class: PlayerClass):
	player_classes[p_user_id] = p_class

func get_player_subclass(p_user_id: String):
	return player_subclasses.get(p_user_id, null)

func set_player_subclass(p_user_id: String, p_subclass: PlayerClass):
	player_subclasses[p_user_id] = p_subclass

func _save_session(data):
	var file = FileAccess.open(TOKEN_SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))

func _http_request(path: String, method: int, body: String = ""):
	var http = HTTPRequest.new()
	add_child(http)
	var headers = ["Content-Type: application/json"]
	if not auth_token.is_empty():
		headers.append("Authorization: Bearer " + auth_token)
	
	http.request(_base_url + path, headers, method, body)
	var response = await http.request_completed
	var status_code = response[1]
	var response_body = response[3].get_string_from_utf8()
	http.queue_free()
	
	var json = JSON.parse_string(response_body)
	if json == null:
		if status_code >= 400:
			return {"error": "Server error (%d): %s" % [status_code, response_body.substr(0, 100)]}
		return {}
		
	return json

func _connect_to_game_server(url: String):
	var ws_url = url
	if not auth_token.is_empty():
		ws_url += "&token=" + auth_token
	socket.connect_to_url(ws_url)
	match_joined.emit()

func _on_data_received(data_str: String):
	var data = JSON.parse_string(data_str)
	if data == null: return
	
	# Emit raw match state for compatibility
	var ms = MatchState.new()
	ms.data = data_str
	ms.op_code = data.get("op_code", 0)
	if data.has("user_id"):
		ms.presence = Presence.new()
		ms.presence.user_id = data.get("user_id", "")
	received_match_state.emit(ms)

	match data.get("type"):
		"player_joined":
			var pid = data.user_id
			players[pid] = {"ign": data.ign, "is_host": data.is_host}
			player_joined.emit(pid, data.ign, data.is_host)
		"player_left":
			players.erase(data.user_id)
			player_left.emit(data.user_id)
		"chat":
			pass

func send_match_state(data: Dictionary):
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.send_text(JSON.stringify(data))
