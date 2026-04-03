extends Node

var client: NakamaClient
var session: NakamaSession
var socket: NakamaSocket
var match_id: String = ""
var player_ign: String = ""
var account_email: String = ""
var room_code: String = ""  # 9-char alphanumeric display code
var lobby_name: String = ""
var is_host: bool = false
var match_phase: String = "lobby"
var players: Dictionary = {}  # user_id -> {ign, is_host}
var player_class: PlayerClass = null  # Selected main class
var player_subclass: PlayerClass = null  # Selected subclass (unlocked at level 10)
var player_level: int = 1  # Player level for subclass unlock

const SERVER_CONFIG_FILE = "server_config.cfg"
const SERVER_CONFIG_SECTION = "server"
const DEFAULT_SERVER_KEY = "defaultkey"
const DEFAULT_SERVER_HOST = "127.0.0.1"
const DEFAULT_SERVER_PORT = 7350
const DEFAULT_SCHEME = "http"
const TIMEOUT = 10
const ROOM_COLLECTION = "room_registry"
const AUTH_SESSION_FILE = "user://auth_session.json"

var _server_config: Dictionary = {
	"host": DEFAULT_SERVER_HOST,
	"port": DEFAULT_SERVER_PORT,
	"scheme": DEFAULT_SCHEME,
	"server_key": DEFAULT_SERVER_KEY,
	"source": "built_in_defaults"
}

signal player_joined(user_id: String, ign: String, is_host_flag: bool)
signal player_left(user_id: String)
signal match_joined()
signal match_phase_changed(new_phase: String)
signal auth_state_changed(is_authenticated: bool, username: String, email: String)

func _ready():
	_server_config = _resolve_server_config()
	print("MultiplayerManager ready")

func _reset_match_state() -> void:
	match_id = ""
	room_code = ""
	lobby_name = ""
	is_host = false
	match_phase = "lobby"
	players.clear()

func _cleanup_socket_connection() -> void:
	if socket != null:
		if socket.received_match_presence.is_connected(_on_match_presence):
			socket.received_match_presence.disconnect(_on_match_presence)
		if socket.received_match_state.is_connected(_on_match_state):
			socket.received_match_state.disconnect(_on_match_state)
		socket.close()
		socket = null

	var socket_adapter = get_node_or_null("NakamaSocketAdapter")
	if socket_adapter != null:
		socket_adapter.queue_free()

func _cleanup_client() -> void:
	var http_adapter = get_node_or_null("NakamaHTTPAdapter")
	if http_adapter != null:
		http_adapter.queue_free()
	client = null

func _clear_auth_state() -> void:
	session = null
	account_email = ""

func _set_authenticated_session(new_session: NakamaSession, email: String = "") -> void:
	session = new_session
	account_email = email
	if player_ign.is_empty() and session != null and not session.username.is_empty():
		player_ign = session.username
	_emit_auth_state()

func _emit_auth_state() -> void:
	var username = ""
	if session != null:
		username = session.username
	if username.is_empty():
		username = player_ign
	auth_state_changed.emit(is_authenticated(), username, account_email)

func _ensure_client() -> void:
	_server_config = _resolve_server_config()
	if client != null:
		return

	print("[Manager] Resolved server config from ", _server_config["source"], ": ", get_server_endpoint_summary())
	var http_adapter = get_node_or_null("NakamaHTTPAdapter")
	if http_adapter == null:
		http_adapter = NakamaHTTPAdapter.new()
		http_adapter.name = "NakamaHTTPAdapter"
		add_child(http_adapter)

	client = NakamaClient.new(
		http_adapter,
		_server_config["server_key"],
		_server_config["scheme"],
		_server_config["host"],
		_server_config["port"],
		TIMEOUT
	)

func _save_auth_session() -> void:
	if session == null or session.token.is_empty():
		return

	var auth_payload = {
		"token": session.token,
		"refresh_token": session.refresh_token,
		"email": account_email,
		"username": session.username if not session.username.is_empty() else player_ign
	}
	var auth_file = FileAccess.open(AUTH_SESSION_FILE, FileAccess.WRITE)
	if auth_file == null:
		push_warning("Failed to persist auth session")
		return
	auth_file.store_string(JSON.stringify(auth_payload))

func _clear_saved_auth_session() -> void:
	if FileAccess.file_exists(AUTH_SESSION_FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(AUTH_SESSION_FILE))

func _load_saved_auth_session() -> Dictionary:
	if not FileAccess.file_exists(AUTH_SESSION_FILE):
		return {}

	var auth_file = FileAccess.open(AUTH_SESSION_FILE, FileAccess.READ)
	if auth_file == null:
		return {}

	var parsed = JSON.parse_string(auth_file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

func is_authenticated() -> bool:
	return session != null and not session.is_exception() and session.is_valid() and not session.is_expired()

func get_last_auth_error(session_result: NakamaSession) -> String:
	if session_result == null:
		return "Authentication failed"
	if session_result.is_exception():
		return str(session_result.get_exception().message)
	if not session_result.is_valid():
		return "Authentication failed"
	return ""

func authenticate_email(email: String, password: String, username: String = "", create_account: bool = false) -> Dictionary:
	_ensure_client()
	var normalized_email = email.strip_edges().to_lower()
	var normalized_username = username.strip_edges()
	var auth_session: NakamaSession

	if create_account:
		auth_session = await client.authenticate_email_async(normalized_email, password, normalized_username, true, null)
	else:
		auth_session = await client.authenticate_email_async(normalized_email, password, null, false, null)

	var auth_error = get_last_auth_error(auth_session)
	if not auth_error.is_empty():
		return {"success": false, "error": auth_error}

	_set_authenticated_session(auth_session, normalized_email)
	if create_account and not normalized_username.is_empty():
		player_ign = normalized_username
	_save_auth_session()
	return {"success": true, "error": ""}

func login_with_email(email: String, password: String) -> Dictionary:
	return await authenticate_email(email, password, "", false)

func register_with_email(email: String, password: String, username: String) -> Dictionary:
	return await authenticate_email(email, password, username, true)

func restore_saved_session() -> Dictionary:
	_ensure_client()
	var saved_auth = _load_saved_auth_session()
	if saved_auth.is_empty():
		return {"success": false, "error": "No saved session"}

	var restored_session = NakamaSession.new(
		str(saved_auth.get("token", "")),
		false,
		str(saved_auth.get("refresh_token", ""))
	)
	if not restored_session.is_valid():
		_clear_saved_auth_session()
		return {"success": false, "error": "Saved session is invalid"}

	if restored_session.is_expired():
		if restored_session.refresh_token.is_empty() or restored_session.is_refresh_expired():
			_clear_saved_auth_session()
			return {"success": false, "error": "Saved session expired"}

		restored_session = await client.session_refresh_async(restored_session)
		var refresh_error = get_last_auth_error(restored_session)
		if not refresh_error.is_empty():
			_clear_saved_auth_session()
			return {"success": false, "error": refresh_error}

	_set_authenticated_session(restored_session, str(saved_auth.get("email", "")))
	if player_ign.is_empty():
		player_ign = str(saved_auth.get("username", ""))
	_save_auth_session()
	return {"success": true, "error": ""}

func logout() -> void:
	_cleanup_socket_connection()
	if client != null and session != null and not session.refresh_token.is_empty():
		await client.session_logout_async(session)
	_clear_saved_auth_session()
	_clear_auth_state()
	_reset_match_state()
	_emit_auth_state()

func is_socket_open() -> bool:
	return socket != null and socket.is_connected_to_host()

func _generate_room_code() -> String:
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var code = ""
	for i in range(6):  # Shorter 6-char code for easier sharing
		code += chars[randi() % chars.length()]
	return code

func get_server_config() -> Dictionary:
	return _server_config.duplicate(true)

func get_server_endpoint_summary() -> String:
	return "%s://%s:%d" % [_server_config["scheme"], _server_config["host"], _server_config["port"]]

func _merge_server_config(resolved: Dictionary, path: String, source_name: String) -> bool:
	if not FileAccess.file_exists(path):
		return false

	var config := ConfigFile.new()
	if config.load(path) != OK:
		push_warning("Failed to load server config: " + path)
		return false

	resolved["host"] = str(config.get_value(SERVER_CONFIG_SECTION, "host", resolved["host"]))
	resolved["port"] = int(config.get_value(SERVER_CONFIG_SECTION, "port", resolved["port"]))
	resolved["scheme"] = str(config.get_value(SERVER_CONFIG_SECTION, "scheme", resolved["scheme"]))
	resolved["server_key"] = str(config.get_value(SERVER_CONFIG_SECTION, "server_key", resolved["server_key"]))
	resolved["source"] = source_name
	return true

func _resolve_server_config() -> Dictionary:
	var resolved := {
		"host": DEFAULT_SERVER_HOST,
		"port": DEFAULT_SERVER_PORT,
		"scheme": DEFAULT_SCHEME,
		"server_key": DEFAULT_SERVER_KEY,
		"source": "built_in_defaults"
	}

	var project_config_path := ProjectSettings.globalize_path("res://" + SERVER_CONFIG_FILE)
	_merge_server_config(resolved, project_config_path, "project_config")

	if not OS.has_feature("editor"):
		var external_config_path := OS.get_executable_path().get_base_dir().path_join(SERVER_CONFIG_FILE)
		_merge_server_config(resolved, external_config_path, "external_release_config")

	return resolved

func connect_to_server(device_id: String = "") -> bool:
	_cleanup_socket_connection()
	_reset_match_state()
	_ensure_client()

	if not is_authenticated():
		var fallback_device_id = device_id
		if fallback_device_id.is_empty():
			fallback_device_id = "guest_" + str(Time.get_unix_time_from_system())
		var result = await client.authenticate_device_async(fallback_device_id, null, true, null)
		var auth_error = get_last_auth_error(result)
		if not auth_error.is_empty():
			print("Failed to authenticate: " + auth_error)
			return false
		_set_authenticated_session(result)

	# Create socket adapter for real-time communication
	var socket_adapter = NakamaSocketAdapter.new()
	socket_adapter.name = "NakamaSocketAdapter"
	add_child(socket_adapter)
	
	# Create socket
	socket = NakamaSocket.new(socket_adapter, _server_config["host"], _server_config["port"], "ws")
	
	# Connect to server using session
	await socket.connect_async(session)
	
	if not socket.is_connected_to_host():
		print("Failed to connect socket")
		return false
	
	print("Socket connected!")

	# Connect match signals here so we never miss events between scene transitions
	socket.received_match_presence.connect(_on_match_presence)
	socket.received_match_state.connect(_on_match_state)
	print("[Manager] Socket signals connected, waiting for match state...")

	return true

func create_room() -> String:
	if session == null or socket == null:
		return ""
	
	_reset_match_state()

	# Generate short room code
	room_code = _generate_room_code()
	lobby_name = "%s's Lobby" % player_ign
	is_host = true
	players[session.user_id] = {"ign": player_ign, "is_host": true}

	# Call RPC to create authoritative match and register room
	var payload = JSON.stringify({
		"room_code": room_code,
		"host_ign": player_ign
	})
	var rpc_result = await client.rpc_async(session, "create_room", payload)
	
	if rpc_result.is_exception():
		return ""
	
	var result_data = JSON.parse_string(rpc_result.payload)
	if result_data == null or not result_data.get("success", false):
		print("RPC returned failure")
		return ""
	
	match_id = result_data.get("match_id", "")
	if match_id.is_empty():
		print("No match_id in RPC response")
		return ""
	
	print("Created room: " + room_code + " | Match: " + match_id)
	
	# Join the match we just created
	var join_result = await socket.join_match_async(match_id, {"ign": player_ign})
	if join_result.is_exception():
		print("Failed to join created match: " + join_result.get_exception().message)
		return ""
	
	# Store our own presence
	if join_result.self_user != null:
		players[session.user_id]["presence"] = join_result.self_user
	
	send_match_state({"type": "player_info", "user_id": session.user_id, "ign": player_ign, "is_host": true})
	match_joined.emit()
	return room_code

func join_room(join_code: String) -> bool:
	if session == null or socket == null:
		return false
	
	_reset_match_state()

	# Normalize the join code
	join_code = join_code.strip_edges().to_upper()
	print("Attempting to join room: '" + join_code + "'")

	# Call RPC to look up room code and get match_id
	var payload = JSON.stringify({"room_code": join_code})
	var rpc_result = await client.rpc_async(session, "join_room", payload)
	
	if rpc_result.is_exception():
		print("RPC join_room failed: " + rpc_result.get_exception().message)
		return false
	
	var result_data = JSON.parse_string(rpc_result.payload)
	if result_data == null:
		print("Invalid RPC response")
		return false
	
	var target_match_id = result_data.get("match_id", "")
	if target_match_id.is_empty():
		print("No match_id in RPC response")
		return false
	
	var host_ign = result_data.get("host_ign", "Unknown")
	lobby_name = result_data.get("lobby_name", "%s's Lobby" % host_ign)
	print("Found room, host: " + host_ign + ", joining match: " + target_match_id)

	var join_result = await socket.join_match_async(target_match_id, {"ign": player_ign})
	if join_result.is_exception():
		print("Failed to join match: " + join_result.get_exception().message)
		return false

	match_id = target_match_id
	room_code = join_code
	is_host = false
	
	print("Joined room: " + room_code + " | Match: " + match_id)
	
	# Add ourselves to players list
	players[session.user_id] = {"ign": player_ign, "is_host": false}
	
	# Store our own presence from join result
	if join_result.self_user != null:
		players[session.user_id]["presence"] = join_result.self_user
	
	# Store existing players from join result (they're already in the match)
	if join_result.presences != null:
		for presence in join_result.presences:
			if presence.user_id != session.user_id:
				print("Found existing player presence: " + presence.user_id.substr(0, 8))
				players[presence.user_id] = {"ign": "", "is_host": false, "presence": presence}
	
	# Send player info to others
	send_match_state({"type": "player_info", "user_id": session.user_id, "ign": player_ign, "is_host": false})
	# Request other players' info
	send_match_state({"type": "request_players"})
	
	match_joined.emit()
	return true

func _on_match_presence(p_presence):
	# Handle players joining/leaving - this is connected in connect_to_server() so we never miss events
	for join in p_presence.joins:
		# Skip if this is ourselves
		if join.user_id == session.user_id:
			continue
		print("[Manager] Player joined match: ", join.user_id.substr(0, 8))
		if not players.has(join.user_id):
			players[join.user_id] = {"ign": "", "is_host": false, "presence": join}
			var display_name = join.username if not join.username.is_empty() else "Player"
			player_joined.emit(join.user_id, display_name, false)
		else:
			players[join.user_id]["presence"] = join
		# Send our info to the new player immediately
		send_match_state({"type": "player_info", "user_id": session.user_id, "ign": player_ign, "is_host": is_host})
	
	for leave in p_presence.leaves:
		# Skip if this is ourselves (Nakama sometimes sends our own leave event)
		if leave.user_id == session.user_id:
			continue
		print("[Manager] Player left match: ", leave.username)
		if players.has(leave.user_id):
			players.erase(leave.user_id)
			player_left.emit(leave.user_id)

func disconnect_server():
	if client != null and session != null and is_host and not room_code.is_empty():
		# Call RPC to delete room
		var payload = JSON.stringify({"room_code": room_code})
		await client.rpc_async(session, "delete_room", payload)
	_cleanup_socket_connection()
	_reset_match_state()
	print("Disconnected from server")

func send_match_state(data: Dictionary):
	if not is_socket_open() or match_id.is_empty():
		return
	
	var json = JSON.stringify(data)
	
	# Rate limit: only print debug once every 2 seconds (2000ms)
	var current_time = Time.get_ticks_msec()
	if current_time - _last_debug_print_time > 2000:
		_last_debug_print_time = current_time
		print("[Manager] Sending match state: ", json)
	
	# Always broadcast to entire match (null = all players)
	# This is more reliable than targeting specific presences
	socket.send_match_state_async(match_id, 0, json, null)

var _last_debug_print_time: int = 0  # Rate limit debug prints

func _set_match_phase(new_phase: String) -> void:
	if new_phase.is_empty() or match_phase == new_phase:
		return
	match_phase = new_phase
	print("[Manager] Match phase -> ", new_phase)
	match_phase_changed.emit(new_phase)

func _on_match_state(match_state) -> void:
	if match_state.op_code == MultiplayerUtils.OP_START_GAME:
		_set_match_phase("in_game")
		return
	
	# Handle OP_PLAYER_JOIN (op code 3) - server broadcasts this when players join
	if match_state.op_code == MultiplayerUtils.OP_PLAYER_JOIN:
		var join_payload = JSON.parse_string(match_state.data)
		if join_payload != null:
			# Capture phase from server - critical for late joiners
			var server_phase = join_payload.get("phase", "lobby")
			if server_phase == "in_game":
				_set_match_phase("in_game")
		return
	
	var data = JSON.parse_string(match_state.data)
	if data == null:
		return

	if match_state.op_code == MultiplayerUtils.OP_STATE:
		if data.has("phase"):
			_set_match_phase(str(data.phase))

		for player_data in data.get("players", []):
			var user_id := str(player_data.get("user_id", ""))
			if user_id.is_empty():
				continue

			var existing = players.get(user_id, {})
			var authoritative_ign = str(player_data.get("ign", existing.get("ign", "")))
			var authoritative_is_host = bool(player_data.get("is_host", existing.get("is_host", false)))
			var presence = existing.get("presence", null)

			var was_known = players.has(user_id)
			var previous_ign = str(existing.get("ign", ""))
			players[user_id] = {
				"ign": authoritative_ign,
				"is_host": authoritative_is_host,
				"presence": presence
			}

			if user_id != session.user_id and (not was_known or previous_ign != authoritative_ign):
				player_joined.emit(user_id, authoritative_ign if not authoritative_ign.is_empty() else "Player", authoritative_is_host)
		return

	if data.get("type", "") == "player_info":
		var entry_id := str(data.get("user_id", ""))
		if entry_id.is_empty():
			return

		var existing = players.get(entry_id, {})
		var authoritative_ign = str(data.get("ign", existing.get("ign", "")))
		var authoritative_is_host = bool(data.get("is_host", existing.get("is_host", false)))
		var previous_ign = str(existing.get("ign", ""))
		var was_known = players.has(entry_id)
		players[entry_id] = {
			"ign": authoritative_ign,
			"is_host": authoritative_is_host,
			"presence": existing.get("presence", null)
		}

		if session != null and entry_id != session.user_id and (not was_known or previous_ign != authoritative_ign):
			player_joined.emit(entry_id, authoritative_ign if not authoritative_ign.is_empty() else "Player", authoritative_is_host)
