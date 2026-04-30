extends Node

# --- Custom Networking (Replaces Nakama) ---
var auth_token: String = ""
var user_id: String = ""
var username: String = ""
var player_ign: String = ""
var account_email: String = ""

var socket: WebSocketPeer = WebSocketPeer.new()
var match_id: String = ""
var room_code: String = ""
var is_host: bool = false
var is_admin: bool = false
var players: Dictionary = {}  # user_id -> {ign, is_host, slime_variant}

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
	# Our custom backend uses 'username' for the unique identifier in /auth/login
	# But the UI sends email. We will use the prefix as username or check both.
	var body = JSON.stringify({"username": p_email, "password": p_password})
	var result = await _http_request("/auth/login", HTTPClient.METHOD_POST, body)
	if result.has("token"):
		auth_token = result.token
		user_id = result.user_id
		username = result.username
		player_ign = result.username
		_save_session(result)
		auth_state_changed.emit(true, username, p_email)
		return {"success": true}
	return {"success": false, "error": result.get("error", "Login failed")}

func register_with_email(p_email, p_password, p_username = ""):
	var uname = p_username if not p_username.is_empty() else p_email.split("@")[0]
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
	return {"success": false, "error": result.get("error", "Registration failed")}

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
	var json = JSON.parse_string(response[3].get_string_from_utf8())
	http.queue_free()
	return json if json != null else {}

func _connect_to_game_server(url: String):
	socket.connect_to_url(url)
	match_joined.emit()

func _on_data_received(data_str: String):
	var data = JSON.parse_string(data_str)
	if data == null: return
	
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
