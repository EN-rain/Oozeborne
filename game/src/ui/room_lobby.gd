extends Control

@onready var room_code_label: Label = $VBoxContainer/RoomCodeLabel
@onready var copy_code_button: Button = $VBoxContainer/CopyCodeButton
@onready var players_list: VBoxContainer = $VBoxContainer/PlayersList
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var back_button: Button = $VBoxContainer/BackButton

const MAIN_GAME_SCENE = "res://scenes/levels/main.tscn"
const MAIN_MENU_SCENE = "res://scenes/ui/main_menu.tscn"
const CROWN_EMOJI = "👑 "

var _player_entries: Dictionary = {}
var _last_state_log_time: int = 0  # Rate limit op_code 2 logs
var _is_transitioning: bool = false

func _get_player_count() -> int:
	return MultiplayerManager.players.size()

func _refresh_start_button_state() -> void:
	if not is_instance_valid(start_button):
		return

	start_button.visible = MultiplayerManager.is_host
	start_button.disabled = not MultiplayerManager.is_host or _get_player_count() < 2
	if MultiplayerManager.is_host:
		print("[Lobby] Start button state: visible=", start_button.visible, " disabled=", start_button.disabled, " players=", _get_player_count())

func _ready():
	if MultiplayerManager.match_phase == "in_game":
		_transition_to_game_scene("ready")
		return

	room_code_label.text = "Room Code: " + MultiplayerManager.room_code
	
	# Add self with crown if host
	var prefix = CROWN_EMOJI if MultiplayerManager.is_host else ""
	_add_player_entry(MultiplayerManager.session.user_id, MultiplayerManager.player_ign + " (You)", prefix, MultiplayerManager.is_host)
	
	# Connect buttons
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	copy_code_button.pressed.connect(_on_copy_code_pressed)
	
	# Add any players already stored (e.g., from presence events during scene transition)
	for user_id in MultiplayerManager.players:
		if user_id != MultiplayerManager.session.user_id:
			var info = MultiplayerManager.players[user_id]
			var is_host_flag = info.get("is_host", false)
			var ign = info.get("ign", "Unknown")
			_add_player_entry(user_id, ign, CROWN_EMOJI if is_host_flag else "", is_host_flag)

	_refresh_start_button_state()
	
	# Listen for player_joined signal from MultiplayerManager (handles scene transition cases)
	if not MultiplayerManager.player_joined.is_connected(_on_player_joined_signal):
		MultiplayerManager.player_joined.connect(_on_player_joined_signal)
	if not MultiplayerManager.player_left.is_connected(_on_player_left_signal):
		MultiplayerManager.player_left.connect(_on_player_left_signal)
	if not MultiplayerManager.match_phase_changed.is_connected(_on_match_phase_changed):
		MultiplayerManager.match_phase_changed.connect(_on_match_phase_changed)
	
	# Listen for match state events (presence is handled by MultiplayerManager)
	if MultiplayerManager.socket:
		if not MultiplayerManager.socket.received_match_state.is_connected(_on_match_state):
			MultiplayerManager.socket.received_match_state.connect(_on_match_state)
		# Announce ourselves immediately
		MultiplayerManager.send_match_state({"type": "player_info", "user_id": MultiplayerManager.session.user_id, "ign": MultiplayerManager.player_ign, "is_host": MultiplayerManager.is_host})
	print("[Lobby] Ready, is_host: ", MultiplayerManager.is_host, " match_id: ", MultiplayerManager.match_id, " socket_connected: ", MultiplayerManager.socket.is_connected_to_host() if MultiplayerManager.socket else false)

func _exit_tree() -> void:
	if MultiplayerManager.player_joined.is_connected(_on_player_joined_signal):
		MultiplayerManager.player_joined.disconnect(_on_player_joined_signal)
	if MultiplayerManager.player_left.is_connected(_on_player_left_signal):
		MultiplayerManager.player_left.disconnect(_on_player_left_signal)
	if MultiplayerManager.match_phase_changed.is_connected(_on_match_phase_changed):
		MultiplayerManager.match_phase_changed.disconnect(_on_match_phase_changed)
	if MultiplayerManager.socket and MultiplayerManager.socket.received_match_state.is_connected(_on_match_state):
		MultiplayerManager.socket.received_match_state.disconnect(_on_match_state)

func _transition_to_game_scene(source: String) -> void:
	if _is_transitioning or not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	_is_transitioning = true
	print("[Lobby] Transitioning to game scene from ", source, "...")
	tree.change_scene_to_file(MAIN_GAME_SCENE)

func _add_player_entry(user_id: String, ign: String, _prefix: String, is_host_flag: bool):
	# If entry exists, update it instead of creating new
	if _player_entries.has(user_id):
		var entry = _player_entries[user_id]
		entry.name.text = ign
		entry.ign = ign
		entry.crown.text = CROWN_EMOJI if is_host_flag else "    "
		entry.is_host = is_host_flag
		return
	
	# Check if player already exists by IGN (prevents duplicates from different keys)
	for entry in _player_entries.values():
		if entry.ign == ign:
			return
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var crown = Label.new()
	crown.text = CROWN_EMOJI if is_host_flag else "    "
	crown.add_theme_font_size_override("font_size", 20)
	hbox.add_child(crown)
	
	var name_label = Label.new()
	name_label.text = ign
	name_label.add_theme_font_size_override("font_size", 20)
	hbox.add_child(name_label)
	
	players_list.add_child(hbox)
	_player_entries[user_id] = {"hbox": hbox, "name": name_label, "crown": crown, "ign": ign, "is_host": is_host_flag}

func _on_player_joined_signal(user_id: String, ign: String, is_host_flag: bool):
	# Handle player_joined signal from MultiplayerManager
	print("[Lobby] Player joined signal: ", ign)
	_add_player_entry(user_id, ign, CROWN_EMOJI if is_host_flag else "", is_host_flag)
	_refresh_start_button_state()

func _on_player_left_signal(user_id: String):
	# Handle player_left signal from MultiplayerManager
	print("[Lobby] Player left signal")
	if _player_entries.has(user_id):
		_player_entries[user_id].hbox.queue_free()
		_player_entries.erase(user_id)
	_refresh_start_button_state()

func _on_match_state(match_state):
	# ALWAYS print OP_START_GAME for debugging
	if match_state.op_code == MultiplayerUtils.OP_START_GAME:
		print("[Lobby] >>> RECEIVED START_GAME OP_CODE 5 <<<")
		_transition_to_game_scene("op_code_5")
		return
	
	# Rate limit op_code 2 (state snapshots) - only log every 2 seconds
	if match_state.op_code == 2:
		var current_time = Time.get_ticks_msec()
		if current_time - _last_state_log_time > 2000:
			_last_state_log_time = current_time
			print("[Lobby] State snapshot tick: ", JSON.parse_string(match_state.data).get("tick", "?") if match_state.data else "?")
	
	# Always log other op codes
	elif match_state.op_code != MultiplayerUtils.OP_STATE:
		print("[Lobby] >>> MATCH STATE RECEIVED: op_code=", match_state.op_code, " data=", match_state.data)
	
	var data = JSON.parse_string(match_state.data)
	if data == null:
		return
	
	# Handle server state snapshots (have "players" array and "tick")
	if data.has("players") and data.has("tick"):
		if str(data.get("phase", "lobby")) == "in_game":
			print("[Lobby] Snapshot reports in_game phase")
			_transition_to_game_scene("snapshot_phase")
			return

		for player_data in data.players:
			var user_id = player_data.get("user_id", "")
			var ign = player_data.get("ign", "")
			var is_host = player_data.get("is_host", false)
			
			if user_id.is_empty() or user_id == MultiplayerManager.session.user_id:
				continue
			
			# Update stored player info
			if MultiplayerManager.players.has(user_id):
				MultiplayerManager.players[user_id]["ign"] = ign
				MultiplayerManager.players[user_id]["is_host"] = is_host
			
			_add_player_entry(user_id, ign, CROWN_EMOJI if is_host else "", is_host)
		_refresh_start_button_state()
		return
	
	var msg_type = data.get("type", "")
	
	match msg_type:
		"player_info":
			var ign = data.get("ign", "")
			var is_host = data.get("is_host", false)
			var entry_id = data.get("user_id", "")
			
			if entry_id.is_empty():
				return
			
			# Add or update player - preserve presence if already stored
			if MultiplayerManager.players.has(entry_id):
				# Update existing entry but keep presence
				MultiplayerManager.players[entry_id]["ign"] = ign
				MultiplayerManager.players[entry_id]["is_host"] = is_host
			else:
				# New player without presence yet (will be added by presence event)
				MultiplayerManager.players[entry_id] = {"ign": ign, "is_host": is_host, "presence": null}
			
			_add_player_entry(entry_id, ign, CROWN_EMOJI if is_host else "", is_host)
			_refresh_start_button_state()
		
		"request_players":
			# Someone is requesting player info - send ours with user_id
			MultiplayerManager.send_match_state({
				"type": "player_info",
				"user_id": MultiplayerManager.session.user_id,
				"ign": MultiplayerManager.player_ign,
				"is_host": MultiplayerManager.is_host
			})
		
		"start_game":
			# Legacy - handled by op code 5 now
			pass

func _on_start_pressed():
	print("[Lobby] ========== START BUTTON PRESSED ==========")
	print("[Lobby] is_host: ", MultiplayerManager.is_host)
	print("[Lobby] socket: ", MultiplayerManager.socket != null)
	print("[Lobby] match_id: ", MultiplayerManager.match_id)
	
	# Only host can start the game
	if MultiplayerManager.is_host:
		if _get_player_count() < 2:
			print("[Lobby] Cannot start game with fewer than 2 players")
			_refresh_start_button_state()
			return
		# Send start_game with op code 5 (server will forward to all players)
		if MultiplayerManager.socket and not MultiplayerManager.match_id.is_empty():
			print("[Lobby] >>> SENDING START_GAME OP_CODE 5 <<<")
			await MultiplayerManager.socket.send_match_state_async(
				MultiplayerManager.match_id,
				MultiplayerUtils.OP_START_GAME,
				JSON.stringify({"type": "start_game"}),
				null
			)
			print("[Lobby] Sent start_game with op_code 5 (awaited)")
		else:
			print("[Lobby] ERROR: Cannot send - socket or match_id missing!")
			return
		start_button.disabled = true
		print("[Lobby] Waiting for authoritative phase change from server...")
	else:
		print("[Lobby] Only host can start the game")

func _on_back_pressed():
	MultiplayerManager.disconnect_server()
	var tree := get_tree()
	if tree != null:
		tree.change_scene_to_file(MAIN_MENU_SCENE)

func _on_copy_code_pressed():
	DisplayServer.clipboard_set(MultiplayerManager.room_code)
	print("Room code copied: " + MultiplayerManager.room_code)

func _on_match_phase_changed(new_phase: String) -> void:
	if new_phase == "in_game":
		print("[Lobby] Manager phase changed to in_game")
		_transition_to_game_scene("manager_phase")
