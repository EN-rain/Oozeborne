extends PanelContainer

# Admin Tools Panel - appears in lobby for admin users

@onready var admin_title: Label = %AdminTitle
@onready var players_list: ItemList = %PlayersList
@onready var kick_button: Button = %KickButton
@onready var ban_button: Button = %BanButton
@onready var promote_host_button: Button = %PromoteHostButton
@onready var teleport_button: Button = %TeleportButton
@onready var broadcast_input: LineEdit = %BroadcastInput
@onready var broadcast_button: Button = %BroadcastButton
@onready var force_start_button: Button = %ForceStartButton
@onready var close_lobby_button: Button = %CloseLobbyButton
@onready var reason_input: LineEdit = %ReasonInput
@onready var toggle_button: Button = %ToggleButton

var _selected_player_id: String = ""
var _is_visible: bool = false


func _ready() -> void:
	_setup_signals()
	_check_admin_status()
	hide()


func _setup_signals() -> void:
	if toggle_button != null:
		toggle_button.pressed.connect(_toggle_panel)
	if kick_button != null:
		kick_button.pressed.connect(_on_kick_pressed)
	if ban_button != null:
		ban_button.pressed.connect(_on_ban_pressed)
	if promote_host_button != null:
		promote_host_button.pressed.connect(_on_promote_host_pressed)
	if teleport_button != null:
		teleport_button.pressed.connect(_on_teleport_pressed)
	if broadcast_button != null:
		broadcast_button.pressed.connect(_on_broadcast_pressed)
	if force_start_button != null:
		force_start_button.pressed.connect(_on_force_start_pressed)
	if close_lobby_button != null:
		close_lobby_button.pressed.connect(_on_close_lobby_pressed)
	if players_list != null:
		players_list.item_selected.connect(_on_player_selected)
	
	AdminManager.admin_mode_changed.connect(_on_admin_mode_changed)


func _check_admin_status() -> void:
	if MultiplayerManager.session != null:
		AdminManager.check_admin_status(MultiplayerManager.session.user_id)
	
	# Sync admin status to MultiplayerManager so chat commands can check it
	MultiplayerManager.is_admin = AdminManager.is_admin()
	
	if AdminManager.is_admin():
		if toggle_button != null:
			toggle_button.show()
		_refresh_players_list()


func _toggle_panel() -> void:
	_is_visible = not _is_visible
	if _is_visible:
		show()
		_refresh_players_list()
	else:
		hide()


func _on_admin_mode_changed(enabled: bool) -> void:
	if enabled:
		if toggle_button != null:
			toggle_button.show()
	else:
		hide()
		if toggle_button != null:
			toggle_button.hide()


func _refresh_players_list() -> void:
	if players_list == null:
		return
	
	players_list.clear()
	
	for user_id in MultiplayerManager.players:
		var player_info: Dictionary = MultiplayerManager.players[user_id]
		var ign: String = str(player_info.get("ign", "Unknown"))
		var is_host: bool = player_info.get("is_host", false)
		var display_text := ign
		if is_host:
			display_text += " [HOST]"
		if user_id == MultiplayerManager.session.user_id:
			display_text += " (You)"
		players_list.add_item(display_text)
		players_list.set_item_metadata(players_list.item_count - 1, user_id)


func _on_player_selected(index: int) -> void:
	var metadata = players_list.get_item_metadata(index)
	if metadata != null:
		_selected_player_id = str(metadata)


func _on_kick_pressed() -> void:
	if _selected_player_id.is_empty():
		return
	var reason := reason_input.text.strip_edges() if reason_input != null else ""
	AdminManager.admin_kick_player(_selected_player_id, reason)
	_selected_player_id = ""
	_refresh_players_list()


func _on_ban_pressed() -> void:
	if _selected_player_id.is_empty():
		return
	var reason := reason_input.text.strip_edges() if reason_input != null else ""
	AdminManager.admin_ban_player(_selected_player_id, reason)
	_selected_player_id = ""
	_refresh_players_list()


func _on_promote_host_pressed() -> void:
	if _selected_player_id.is_empty():
		return
	AdminManager.admin_change_host(_selected_player_id)
	_selected_player_id = ""
	_refresh_players_list()


func _on_teleport_pressed() -> void:
	if _selected_player_id.is_empty():
		return
	# Teleport to center for now
	AdminManager.admin_teleport_player(_selected_player_id, 400.0, 300.0)


func _on_broadcast_pressed() -> void:
	if broadcast_input == null:
		return
	var message := broadcast_input.text.strip_edges()
	if message.is_empty():
		return
	AdminManager.admin_broadcast_message(message)
	broadcast_input.text = ""


func _on_force_start_pressed() -> void:
	AdminManager.admin_force_start_game()


func _on_close_lobby_pressed() -> void:
	var reason := reason_input.text.strip_edges() if reason_input != null else "Admin closed lobby"
	AdminManager.admin_close_lobby(reason)


func show_panel() -> void:
	_is_visible = true
	show()
	_refresh_players_list()


func hide_panel() -> void:
	_is_visible = false
	hide()
