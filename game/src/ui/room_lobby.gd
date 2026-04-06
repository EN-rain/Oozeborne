extends Control


# ── Node References (matching new prototype layout) ──────────────────────────
@onready var room_code_button: Button = %RoomCode
@onready var leave_button: Button = %LeaveLobby
@onready var start_button: Button = %StartGame
@onready var select_class_button: Button = %SelectClass
@onready var left_button: Button = %LeftButton
@onready var right_button: Button = %RightButton
@onready var title_label: Label = %Label
@onready var title_edit: LineEdit = %LobbyNameEdit
@onready var subclass_hint_label: Label = $Label/Label
@onready var players_title: Label = %PlayersTitle
@onready var players_list: VBoxContainer = %PlayersList
@onready var stats_content: RichTextLabel = %StatsContent
@onready var subclass_content: RichTextLabel = %SubclassContent
@onready var hp_value_label: Label = $ClassStats/StatsVBox/StatsCards/HPCard/Margin/VBox/Value
@onready var atk_value_label: Label = $ClassStats/StatsVBox/StatsCards/AttackCard/Margin/VBox/Value
@onready var def_value_label: Label = $ClassStats/StatsVBox/StatsCards/DefenseCard/Margin/VBox/Value
@onready var spd_value_label: Label = $ClassStats/StatsVBox/StatsCards/SpeedCard/Margin/VBox/Value
@onready var crit_value_label: Label = $ClassStats/StatsVBox/StatsCards/CritCard/Margin/VBox/Value
@onready var evade_value_label: Label = $ClassStats/StatsVBox/StatsCards/EvadeCard/Margin/VBox/Value
@onready var hp_card: PanelContainer = $ClassStats/StatsVBox/StatsCards/HPCard
@onready var attack_card: PanelContainer = $ClassStats/StatsVBox/StatsCards/AttackCard
@onready var defense_card: PanelContainer = $ClassStats/StatsVBox/StatsCards/DefenseCard
@onready var speed_card: PanelContainer = $ClassStats/StatsVBox/StatsCards/SpeedCard
@onready var crit_card: PanelContainer = $ClassStats/StatsVBox/StatsCards/CritCard
@onready var evade_card: PanelContainer = $ClassStats/StatsVBox/StatsCards/EvadeCard
@onready var power_fill: ColorRect = get_node_or_null("ClassStats/StatsVBox/PowerRow/PowerTrack/PowerFill") as ColorRect
@onready var power_rank_label: Label = get_node_or_null("ClassStats/StatsVBox/PowerRow/PowerRank") as Label
@onready var talent_cards: VBoxContainer = %TalentCards
@onready var title_controller = $LobbyTitleController
@onready var carousel_controller = $LobbyCarouselController
@onready var chat_box = %ChatBox

# ── Chat nodes ──────────────────────────────────────────────────────────────
@onready var chat_log: RichTextLabel = %ChatLog
@onready var chat_input: LineEdit = %ChatInput
@onready var send_button: Button = %SendButton

# ── Class slot nodes ─────────────────────────────────────────────────────────
@onready var class_slots: Array = [
	$Class1, $Class2, $Class3, $Class4, $Class5
]

const CROWN_EMOJI = "👑 "

@export_file("*.tscn") var main_game_scene_path: String
@export_file("*.tscn") var main_menu_scene_path: String

var _player_entries: Dictionary = {}
var _last_state_log_time: int = 0
var _last_btn_log_time: int = 0
var _is_transitioning: bool = false
var _selected_class: PlayerClass = null
var _view: RoomLobbyView

func _get_player_count() -> int:
	return MultiplayerManager.players.size()

func _get_host_ign() -> String:
	if MultiplayerManager.is_host and not MultiplayerManager.player_ign.strip_edges().is_empty():
		return MultiplayerManager.player_ign

	for entry in _player_entries.values():
		if bool(entry.get("is_host", false)):
			var host_ign: String = str(entry.get("ign", "")).replace(" (You)", "").strip_edges()
			if not host_ign.is_empty():
				return host_ign

	if not MultiplayerManager.player_ign.strip_edges().is_empty():
		return MultiplayerManager.player_ign
	return "Player"

func _build_default_lobby_name(host_ign: String) -> String:
	var safe_host_ign: String = host_ign.strip_edges()
	if safe_host_ign.is_empty():
		safe_host_ign = "Player"
	return "%s's Lobby" % safe_host_ign

func _get_current_lobby_name() -> String:
	var current_name: String = MultiplayerManager.lobby_name.strip_edges()
	if current_name.is_empty():
		return _build_default_lobby_name(_get_host_ign())
	return current_name

func _refresh_lobby_title() -> void:
	title_controller.refresh_title()

func _begin_lobby_title_edit() -> void:
	if not MultiplayerManager.is_host or not is_instance_valid(title_edit):
		return
	title_edit.text = _get_current_lobby_name()
	title_edit.visible = true
	title_label.visible = false
	title_edit.grab_focus()
	title_edit.select_all()

func _finish_lobby_title_edit(cancel: bool = false) -> void:
	if not is_instance_valid(title_edit):
		return
	if cancel:
		title_edit.text = _get_current_lobby_name()
	else:
		var next_name: String = title_edit.text.strip_edges()
		if next_name.is_empty():
			next_name = _build_default_lobby_name(_get_host_ign())
		MultiplayerManager.lobby_name = next_name
	title_edit.visible = false
	title_label.visible = true
	_refresh_lobby_title()

func _broadcast_lobby_name() -> void:
	title_controller.broadcast_lobby_name()

func _commit_lobby_title_edit() -> void:
	if not MultiplayerManager.is_host or not is_instance_valid(title_edit) or not title_edit.visible:
		return
	_finish_lobby_title_edit(false)
	_broadcast_lobby_name()

func _on_title_label_gui_input(event: InputEvent) -> void:
	if not MultiplayerManager.is_host:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_begin_lobby_title_edit()
		get_viewport().set_input_as_handled()

func _on_title_edit_text_submitted(_new_text: String) -> void:
	_commit_lobby_title_edit()

func _on_title_edit_focus_exited() -> void:
	if title_edit.visible:
		_commit_lobby_title_edit()

func _on_title_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_finish_lobby_title_edit(true)
		get_viewport().set_input_as_handled()

func _refresh_start_button_state() -> void:
	if not is_instance_valid(start_button):
		return

	start_button.visible = MultiplayerManager.is_host
	start_button.disabled = not MultiplayerManager.is_host or _get_player_count() < 2
	
	if MultiplayerManager.is_host:
		var current_time = Time.get_ticks_msec()
		if current_time - _last_btn_log_time > 2000:
			_last_btn_log_time = current_time
			print("[Lobby] Start button state: visible=", start_button.visible, " disabled=", start_button.disabled, " players=", _get_player_count())

func _update_player_count():
	_refresh_party_cards()

func _ready():
	# Check if game is already in progress - late joiner scenario
	if MultiplayerManager.match_phase == "in_game":
		_show_join_game_ui()
		return

	_view = RoomLobbyView.new({
		"players_title": players_title,
		"players_list": players_list,
		"stats_content": stats_content,
		"subclass_content": subclass_content,
		"hp_value_label": hp_value_label,
		"atk_value_label": atk_value_label,
		"def_value_label": def_value_label,
		"spd_value_label": spd_value_label,
		"crit_value_label": crit_value_label,
		"evade_value_label": evade_value_label,
		"power_fill": power_fill,
		"power_rank_label": power_rank_label,
		"talent_cards": talent_cards,
		"stat_cards": [hp_card, attack_card, defense_card, speed_card, crit_card, evade_card],
	})
	_view.setup_right_panels()
	title_controller.setup(Callable(self, "_get_host_ign"))
	carousel_controller.setup(_view, class_slots, left_button, right_button)
	_refresh_lobby_title()
	chat_box.focus_input()

	_add_chat_message("System", "Welcome to the lobby!", Color(0.9, 0.75, 0.3))

	room_code_button.text = MultiplayerManager.room_code
	
	if MultiplayerManager.session == null:
		_refresh_party_cards()
		return

	# Add self with crown if host
	var prefix = CROWN_EMOJI if MultiplayerManager.is_host else ""
	_add_player_entry(MultiplayerManager.session.user_id, MultiplayerManager.player_ign + " (You)", prefix, MultiplayerManager.is_host)
	
	# Add any players already stored
	for user_id in MultiplayerManager.players:
		if user_id != MultiplayerManager.session.user_id:
			var info = MultiplayerManager.players[user_id]
			var is_host_flag = info.get("is_host", false)
			var ign = info.get("ign", "Unknown")
			_add_player_entry(user_id, ign, CROWN_EMOJI if is_host_flag else "", is_host_flag)

	_refresh_start_button_state()
	
	# Listen for signals
	if not MultiplayerManager.player_joined.is_connected(_on_player_joined_signal):
		MultiplayerManager.player_joined.connect(_on_player_joined_signal)
	if not MultiplayerManager.player_left.is_connected(_on_player_left_signal):
		MultiplayerManager.player_left.connect(_on_player_left_signal)
	if not MultiplayerManager.match_phase_changed.is_connected(_on_match_phase_changed):
		MultiplayerManager.match_phase_changed.connect(_on_match_phase_changed)
	
	# Listen for match state events
	if MultiplayerManager.socket:
		if not MultiplayerManager.socket.received_match_state.is_connected(_on_match_state):
			MultiplayerManager.socket.received_match_state.connect(_on_match_state)
		# Announce ourselves
		MultiplayerManager.send_match_state({"type": "player_info", "user_id": MultiplayerManager.session.user_id, "ign": MultiplayerManager.player_ign, "is_host": MultiplayerManager.is_host})
		if MultiplayerManager.is_host:
			_broadcast_lobby_name()
	print("[Lobby] Ready, is_host: ", MultiplayerManager.is_host, " match_id: ", MultiplayerManager.match_id, " socket_connected: ", MultiplayerManager.socket.is_connected_to_host() if MultiplayerManager.socket else false)
	
	# Highlight current selected class slot
	_update_class_highlight()
	_refresh_party_cards()

func _process(_delta: float) -> void:
	pass

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
	tree.change_scene_to_file(main_game_scene_path)

# ── Player list management ───────────────────────────────────────────────────
func _add_player_entry(user_id: String, ign: String, _prefix: String, is_host_flag: bool):
	# If entry exists, update it
	if _player_entries.has(user_id):
		var entry = _player_entries[user_id]
		entry.ign = ign
		entry.is_host = is_host_flag
		_refresh_party_cards()
		return
	
	# Check if player already exists by IGN
	for entry in _player_entries.values():
		if entry.ign == ign:
			return
	
	var accent_color = _view.get_next_player_accent(_player_entries.size())
	
	_player_entries[user_id] = {"ign": ign, "is_host": is_host_flag, "accent_color": accent_color}
	_refresh_party_cards()
	_refresh_lobby_title()
	
	# Chat notification
	_add_chat_message("System", ign + " joined the lobby.", Color(0.35, 0.65, 0.45))

func _on_player_joined_signal(user_id: String, ign: String, is_host_flag: bool):
	print("[Lobby] Player joined signal: ", ign)
	_add_player_entry(user_id, ign, CROWN_EMOJI if is_host_flag else "", is_host_flag)
	_refresh_start_button_state()

func _on_player_left_signal(user_id: String):
	print("[Lobby] Player left signal")
	if _player_entries.has(user_id):
		var entry = _player_entries[user_id]
		_add_chat_message("System", entry.ign + " left the lobby.", Color(0.75, 0.35, 0.35))
		_player_entries.erase(user_id)
	_refresh_start_button_state()
	_refresh_party_cards()
	_refresh_lobby_title()

func _refresh_party_cards() -> void:
	if _view == null:
		return
	_view.refresh_party_cards(_player_entries)

func _get_active_class_name() -> String:
	return carousel_controller.get_active_class_name()


# ── Chat system ──────────────────────────────────────────────────────────────
func _escape_chat_bbcode(value: String) -> String:
	return value.replace("[", "[lb]").replace("]", "[rb]")

func _get_chat_sender_name() -> String:
	if MultiplayerManager.player_ign.strip_edges().is_empty():
		return "You"
	return MultiplayerManager.player_ign

func _add_chat_message(sender: String, message: String, color: Color = Color(0.7, 0.65, 0.85)):
	chat_box.add_message(sender, message, color)

func _on_send_chat():
	chat_box.send_current_message()

func _on_chat_submitted(_msg: String):
	chat_box.send_current_message()

# ── Class navigation ─────────────────────────────────────────────────────────
func _on_left_pressed():
	carousel_controller.move_left()

func _on_right_pressed():
	carousel_controller.move_right()

func _update_class_highlight():
	carousel_controller.render_carousel(0.0)

func _on_select_class_pressed():
	var active_class: String = _get_active_class_name()
	_selected_class = _get_player_class_for_name(active_class)
	if _selected_class:
		_selected_class.player_scene = MultiplayerManager.resolve_player_scene()
		MultiplayerManager.player_class = _selected_class
		_add_chat_message("System", "Selected class: " + active_class, Color(0.4, 0.7, 0.9))
		print("[Lobby] Selected class: ", active_class, " with player_scene: ", _selected_class.player_scene)
		# Broadcast class selection to other players
		if MultiplayerManager.is_socket_open() and not MultiplayerManager.match_id.is_empty():
			MultiplayerManager.send_match_state({
				"type": "class_selected",
				"user_id": MultiplayerManager.session.user_id,
				"class_name": active_class
			})
	else:
		_add_chat_message("System", "Selected class: " + active_class, Color(0.4, 0.7, 0.9))
		print("[Lobby] Selected class: ", active_class)

func _get_player_class_for_name(selected_name: String) -> PlayerClass:
	var class_id := ClassManager.display_name_to_class_id(selected_name)
	if not class_id.is_empty():
		return ClassManager.create_class_instance(class_id)
	return null

func _get_slime_scene_path_for_class(selected_name: String) -> String:
	return carousel_controller.get_slime_scene_path_for_class(selected_name)

# ── Match state handling ─────────────────────────────────────────────────────
func _on_match_state(match_state):
	# Handle start game
	if match_state.op_code == MultiplayerUtils.OP_START_GAME:
		print("[Lobby] >>> RECEIVED START_GAME OP_CODE 5 <<<")
		_transition_to_game_scene("op_code_5")
		return
	
	# Rate limit op_code 2 (state snapshots)
	if match_state.op_code == MultiplayerUtils.OP_STATE:
		var current_time = Time.get_ticks_msec()
		if current_time - _last_state_log_time > 2000:
			_last_state_log_time = current_time
			var tick_value = "?"
			if match_state.data:
				var parsed_snapshot = JSON.parse_string(match_state.data)
				if parsed_snapshot is Dictionary:
					tick_value = parsed_snapshot.get("tick", "?")
			print("[Lobby] State snapshot tick: ", tick_value)
	
	elif match_state.op_code != MultiplayerUtils.OP_STATE:
		print("[Lobby] >>> MATCH STATE RECEIVED: op_code=", match_state.op_code, " data=", match_state.data)
	
	var data = JSON.parse_string(match_state.data)
	if data == null:
		return
	
	# Handle server state snapshots
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
			
			if MultiplayerManager.players.has(entry_id):
				MultiplayerManager.players[entry_id]["ign"] = ign
				MultiplayerManager.players[entry_id]["is_host"] = is_host
			else:
				MultiplayerManager.players[entry_id] = {"ign": ign, "is_host": is_host, "presence": null}
			
			_add_player_entry(entry_id, ign, CROWN_EMOJI if is_host else "", is_host)
			_refresh_start_button_state()
		
		"request_players":
			MultiplayerManager.send_match_state({
				"type": "player_info",
				"user_id": MultiplayerManager.session.user_id,
				"ign": MultiplayerManager.player_ign,
				"is_host": MultiplayerManager.is_host
			})
			if MultiplayerManager.is_host:
				_broadcast_lobby_name()
		
		"lobby_name":
			MultiplayerManager.lobby_name = str(data.get("name", "")).strip_edges()
			_refresh_lobby_title()

		"chat_message":
			# Receive chat from other players
			var sender = data.get("sender", "Unknown")
			var message = data.get("message", "")
			if not message.is_empty():
				_add_chat_message(sender, message, Color(0.7, 0.65, 0.85))
		
		"start_game":
			pass
		
		"class_selected":
			# Another player selected their class
			var sender_id = data.get("user_id", "")
			var selected_name = data.get("class_name", "")
			if not sender_id.is_empty() and sender_id != MultiplayerManager.session.user_id:
				var player_class = _get_player_class_for_name(selected_name)
				if player_class:
					MultiplayerManager.set_player_class(sender_id, player_class)
					print("[Lobby] Player ", sender_id.substr(0, 8), " selected class: ", selected_name)

func _on_start_pressed():
	print("[Lobby] ========== START BUTTON PRESSED ==========")
	print("[Lobby] is_host: ", MultiplayerManager.is_host)
	print("[Lobby] socket: ", MultiplayerManager.socket != null)
	print("[Lobby] match_id: ", MultiplayerManager.match_id)
	
	if MultiplayerManager.is_host:
		if _get_player_count() < 2:
			print("[Lobby] Cannot start game with fewer than 2 players")
			_refresh_start_button_state()
			return
		if MultiplayerManager.is_socket_open() and not MultiplayerManager.match_id.is_empty():
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

func _show_join_game_ui():
	"""Show UI for late joiners - game is already in progress"""
	print("[Lobby] Game already in progress - showing Join Game UI")
	room_code_button.text = MultiplayerManager.room_code
	
	leave_button.pressed.connect(_on_back_pressed)
	room_code_button.pressed.connect(_on_copy_code_pressed)
	
	# Repurpose start button as join button
	start_button.text = "⚡ Join Quest"
	start_button.visible = true
	start_button.disabled = false
	if not start_button.pressed.is_connected(_on_join_game_pressed):
		start_button.pressed.connect(_on_join_game_pressed)
	
	_add_player_entry(MultiplayerManager.session.user_id, MultiplayerManager.player_ign + " (You)", "", false)
	
	for user_id in MultiplayerManager.players:
		if user_id != MultiplayerManager.session.user_id:
			var info = MultiplayerManager.players[user_id]
			var is_host_flag = info.get("is_host", false)
			var ign = info.get("ign", "Unknown")
			_add_player_entry(user_id, ign, CROWN_EMOJI if is_host_flag else "", is_host_flag)
	
	if MultiplayerManager.socket:
		if not MultiplayerManager.socket.received_match_state.is_connected(_on_match_state):
			MultiplayerManager.socket.received_match_state.connect(_on_match_state)

func _on_join_game_pressed():
	print("[Lobby] ========== JOIN GAME BUTTON PRESSED ==========")
	_transition_to_game_scene("join_game_button")

func _on_back_pressed():
	MultiplayerManager.disconnect_server()
	var tree := get_tree()
	if tree != null:
		tree.change_scene_to_file(main_menu_scene_path)

func _on_copy_code_pressed():
	DisplayServer.clipboard_set(MultiplayerManager.room_code)
	print("Room code copied: " + MultiplayerManager.room_code)

func _on_match_phase_changed(new_phase: String) -> void:
	if new_phase == "in_game":
		print("[Lobby] Manager phase changed to in_game")
		if not MultiplayerManager.is_host and start_button.visible:
			print("[Lobby] Game started while in lobby - switching to Join Game UI")
			_show_join_game_ui()
		else:
			_transition_to_game_scene("manager_phase")

# ── Preserved class selection API ────────────────────────────────────────────
func get_selected_class() -> PlayerClass:
	return _selected_class

func get_selected_subclass() -> PlayerClass:
	return null
