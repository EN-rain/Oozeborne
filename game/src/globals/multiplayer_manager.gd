extends Node

var client: NakamaClient
var session: NakamaSession
var socket: NakamaSocket
var match_id: String = ""
var player_ign: String = ""
var room_code: String = ""  # 9-char alphanumeric display code
var is_host: bool = false
var match_phase: String = "lobby"
var players: Dictionary = {}  # user_id -> {ign, is_host}

const SERVER_KEY = "defaultkey"
const SERVER_HOST = "127.0.0.1"
const SERVER_PORT = 7350
const SCHEME = "http"
const TIMEOUT = 10
const ROOM_COLLECTION = "room_registry"

signal player_joined(user_id: String, ign: String, is_host_flag: bool)
signal player_left(user_id: String)
signal match_joined()
signal match_phase_changed(new_phase: String)

func _ready():
	print("MultiplayerManager ready")

func _reset_match_state() -> void:
	match_id = ""
	room_code = ""
	is_host = false
	match_phase = "lobby"
	players.clear()

func _cleanup_connection() -> void:
	if socket != null:
		if socket.received_match_presence.is_connected(_on_match_presence):
			socket.received_match_presence.disconnect(_on_match_presence)
		if socket.received_match_state.is_connected(_on_match_state):
			socket.received_match_state.disconnect(_on_match_state)
		socket.close()
		socket = null

	for child_name in ["NakamaHTTPAdapter", "NakamaSocketAdapter"]:
		var child = get_node_or_null(child_name)
		if child != null:
			child.queue_free()

	client = null
	session = null

func is_socket_open() -> bool:
	return socket != null and socket.is_connected_to_host()

func _generate_room_code() -> String:
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var code = ""
	for i in range(6):  # Shorter 6-char code for easier sharing
		code += chars[randi() % chars.length()]
	return code

func connect_to_server(device_id: String) -> bool:
	_cleanup_connection()
	_reset_match_state()

	# Create HTTP adapter for the client
	var http_adapter = NakamaHTTPAdapter.new()
	http_adapter.name = "NakamaHTTPAdapter"
	add_child(http_adapter)
	
	# Create Nakama client
	client = NakamaClient.new(http_adapter, SERVER_KEY, SCHEME, SERVER_HOST, SERVER_PORT, TIMEOUT)
	
	# Authenticate with device ID
	var result = await client.authenticate_device_async(device_id, null, true, null)
	
	if result.is_exception():
		print("Failed to authenticate: " + result.get_exception().message)
		return false
	
	session = result
	print("Connected to Nakama! Session: " + session.token)
	
	# Create socket adapter for real-time communication
	var socket_adapter = NakamaSocketAdapter.new()
	socket_adapter.name = "NakamaSocketAdapter"
	add_child(socket_adapter)
	
	# Create socket
	socket = NakamaSocket.new(socket_adapter, SERVER_HOST, SERVER_PORT, "ws")
	
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
	_cleanup_connection()
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
