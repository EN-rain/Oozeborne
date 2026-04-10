extends Node
class_name RoomLobbyMatchFlow

var _room_code_button: Button
var _leave_button: Button
var _start_button: Button
var _main_game_scene_path: String = ""
var _main_menu_scene_path: String = ""
var _join_game_button_text: String = "Join Quest"
var _party_controller: RoomLobbyPartyController
var _title_controller: Node
var _is_transitioning: bool = false


func setup(
	room_code_button: Button,
	leave_button: Button,
	start_button: Button,
	main_game_scene_path: String,
	main_menu_scene_path: String,
	join_game_button_text: String,
	party_controller: RoomLobbyPartyController,
	title_controller: Node
) -> void:
	_room_code_button = room_code_button
	_leave_button = leave_button
	_start_button = start_button
	_main_game_scene_path = main_game_scene_path
	_main_menu_scene_path = main_menu_scene_path
	_join_game_button_text = join_game_button_text
	_party_controller = party_controller
	_title_controller = title_controller


func enter_lobby() -> void:
	if is_instance_valid(_room_code_button):
		_room_code_button.text = MultiplayerManager.room_code
		_party_controller.bootstrap_party_entries()

	if not MultiplayerManager.player_joined.is_connected(_on_player_joined_signal):
		MultiplayerManager.player_joined.connect(_on_player_joined_signal)
	if not MultiplayerManager.player_left.is_connected(_on_player_left_signal):
		MultiplayerManager.player_left.connect(_on_player_left_signal)
	if not MultiplayerManager.match_phase_changed.is_connected(_on_match_phase_changed):
		MultiplayerManager.match_phase_changed.connect(_on_match_phase_changed)

	if MultiplayerManager.socket:
		if not MultiplayerManager.socket.received_match_state.is_connected(_on_match_state):
			MultiplayerManager.socket.received_match_state.connect(_on_match_state)
		MultiplayerManager.send_match_state({
			"type": "player_info",
			"user_id": MultiplayerManager.session.user_id,
			"ign": MultiplayerManager.player_ign,
			"is_host": MultiplayerManager.is_host
		})
		if MultiplayerManager.is_host and _title_controller != null and _title_controller.has_method("broadcast_lobby_name"):
			_title_controller.broadcast_lobby_name()


func cleanup() -> void:
	if MultiplayerManager.player_joined.is_connected(_on_player_joined_signal):
		MultiplayerManager.player_joined.disconnect(_on_player_joined_signal)
	if MultiplayerManager.player_left.is_connected(_on_player_left_signal):
		MultiplayerManager.player_left.disconnect(_on_player_left_signal)
	if MultiplayerManager.match_phase_changed.is_connected(_on_match_phase_changed):
		MultiplayerManager.match_phase_changed.disconnect(_on_match_phase_changed)
	if MultiplayerManager.socket and MultiplayerManager.socket.received_match_state.is_connected(_on_match_state):
		MultiplayerManager.socket.received_match_state.disconnect(_on_match_state)


func show_join_game_ui() -> void:
	if is_instance_valid(_room_code_button):
		_room_code_button.text = MultiplayerManager.room_code
	if is_instance_valid(_start_button):
		_start_button.text = _join_game_button_text
		_start_button.visible = true
		_start_button.disabled = false
	_party_controller.bootstrap_party_entries()
	if MultiplayerManager.socket and not MultiplayerManager.socket.received_match_state.is_connected(_on_match_state):
		MultiplayerManager.socket.received_match_state.connect(_on_match_state)


func on_start_pressed() -> void:
	if not MultiplayerManager.is_host:
		return
	if _party_controller.get_player_count() < 2:
		_party_controller.refresh_start_button_state()
		return
	if MultiplayerManager.is_socket_open() and not MultiplayerManager.match_id.is_empty():
		await MultiplayerManager.socket.send_match_state_async(
			MultiplayerManager.match_id,
			MultiplayerUtils.OP_START_GAME,
			JSON.stringify({"type": "start_game"}),
			null
		)
		if is_instance_valid(_start_button):
			_start_button.disabled = true


func on_join_game_pressed() -> void:
	_transition_to_game_scene("join_game_button")


func on_back_pressed() -> void:
	MultiplayerManager.disconnect_server()
	var tree := get_tree()
	if tree != null:
		tree.change_scene_to_file(_main_menu_scene_path)


func on_copy_code_pressed() -> void:
	DisplayServer.clipboard_set(MultiplayerManager.room_code)


func _transition_to_game_scene(source: String) -> void:
	if _is_transitioning or not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	_is_transitioning = true
	print("[Lobby] Transitioning to game scene from ", source, "...")
	tree.change_scene_to_file(_main_game_scene_path)


func _on_player_joined_signal(user_id: String, ign: String, is_host_flag: bool) -> void:
	_party_controller.add_player_entry(user_id, ign, "?? " if is_host_flag else "", is_host_flag)
	_party_controller.refresh_start_button_state()


func _on_player_left_signal(user_id: String) -> void:
	_party_controller.remove_player_entry(user_id)


func _on_match_state(match_state) -> void:
	if match_state.op_code == MultiplayerUtils.OP_START_GAME:
		_transition_to_game_scene("op_code_5")
		return

	if match_state.op_code == MultiplayerUtils.OP_STATE:
		return

	var data = JSON.parse_string(match_state.data)
	if data == null:
		return

	if data.has("players") and data.has("tick"):
		if str(data.get("phase", "lobby")) == "in_game":
			_transition_to_game_scene("snapshot_phase")
			return
		_party_controller.handle_snapshot_players(data.players)
		return

	var msg_type := str(data.get("type", ""))
	match msg_type:
		"player_info":
			_party_controller.handle_player_info_state(data)
		"request_players":
			# Send our own info
			MultiplayerManager.send_match_state({
				"type": "player_info",
				"user_id": MultiplayerManager.session.user_id,
				"ign": MultiplayerManager.player_ign,
				"is_host": MultiplayerManager.is_host
			})
			# If host, also send info for all other known players
			if MultiplayerManager.is_host:
				for user_id in MultiplayerManager.players:
					if user_id != MultiplayerManager.session.user_id:
						var info = MultiplayerManager.players[user_id]
						var ign = str(info.get("ign", ""))
						if not ign.is_empty():
							MultiplayerManager.send_match_state({
								"type": "player_info",
								"user_id": user_id,
								"ign": ign,
								"is_host": bool(info.get("is_host", false))
							})
				if _title_controller != null and _title_controller.has_method("broadcast_lobby_name"):
					_title_controller.broadcast_lobby_name()
		"lobby_name":
			MultiplayerManager.lobby_name = str(data.get("name", "")).strip_edges()
			if _title_controller != null and _title_controller.has_method("refresh_title"):
				_title_controller.refresh_title()
		"chat_message":
			var sender := str(data.get("sender", "Unknown"))
			var message := str(data.get("message", ""))
			if not message.is_empty():
				_party_controller.add_chat_message(sender, message, Color(0.7, 0.65, 0.85))
		"class_selected":
			_party_controller.handle_remote_class_selected(str(data.get("user_id", "")), str(data.get("class_name", "")))


func _on_match_phase_changed(new_phase: String) -> void:
	if new_phase == "in_game":
		if not MultiplayerManager.is_host and is_instance_valid(_start_button) and _start_button.visible:
			show_join_game_ui()
		else:
			_transition_to_game_scene("manager_phase")
