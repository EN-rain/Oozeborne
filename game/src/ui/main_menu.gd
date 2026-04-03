extends Control

@onready var account_label: Label = %AccountLabel
@onready var logout_button: Button = %LogoutButton
@onready var start_button: Button = %StartButton
@onready var host_button: Button = %HostButton
@onready var connect_button: Button = %ConnectButton
@onready var code_input: LineEdit = %CodeInput
@onready var ign_input: LineEdit = %IGNInput
@onready var status_label: Label = %StatusLabel
@onready var quit_button: Button = %QuitButton

const AUTH_MENU_SCENE = "res://scenes/ui/auth_menu.tscn"
const MAIN_GAME_SCENE = "res://scenes/levels/main.tscn"
const ROOM_LOBBY_SCENE = "res://scenes/ui/room_lobby.tscn"

var _menu_busy: bool = false

func _ready() -> void:
	logout_button.pressed.connect(_on_logout_pressed)
	start_button.pressed.connect(_on_start_pressed)
	host_button.pressed.connect(_on_host_pressed)
	connect_button.pressed.connect(_on_connect_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	if ign_input.text.strip_edges().is_empty():
		ign_input.text = MultiplayerManager.player_ign if not MultiplayerManager.player_ign.is_empty() else "Player" + str(randi_range(1000, 9999))

	_update_auth_ui()

func _set_status(text: String, color: Color = Color(0.6, 0.62, 0.75, 0.7)) -> void:
	status_label.text = text
	status_label.add_theme_color_override("font_color", color)

func _set_menu_busy(busy: bool) -> void:
	_menu_busy = busy
	_update_auth_ui()

func _update_auth_ui() -> void:
	var authenticated = MultiplayerManager.is_authenticated()
	var account_name = MultiplayerManager.player_ign
	if account_name.is_empty() and MultiplayerManager.session != null:
		account_name = MultiplayerManager.session.username
	if account_name.is_empty():
		account_name = "Offline"

	account_label.text = "Account: %s" % account_name
	logout_button.disabled = _menu_busy or not authenticated
	start_button.disabled = _menu_busy
	host_button.disabled = _menu_busy or not authenticated
	connect_button.disabled = _menu_busy or not authenticated

	if authenticated:
		_set_status("Signed in. Multiplayer ready.", Color(0.2, 0.8, 0.55))
	else:
		_set_status("Offline mode. Multiplayer requires sign-in.", Color(0.9, 0.7, 0.3))

func _get_ign() -> String:
	var ign = ign_input.text.strip_edges()
	if ign.is_empty():
		ign = "Player" + str(randi_range(1000, 9999))
	return ign

func _go_to_auth_menu() -> void:
	call_deferred("_deferred_go_to_auth_menu")

func _deferred_go_to_auth_menu() -> void:
	if not is_inside_tree():
		return
	get_tree().change_scene_to_file(AUTH_MENU_SCENE)

func _on_logout_pressed() -> void:
	_set_menu_busy(true)
	await MultiplayerManager.logout()
	_set_menu_busy(false)
	_go_to_auth_menu()

func _on_start_pressed() -> void:
	MultiplayerManager.player_ign = _get_ign()
	get_tree().change_scene_to_file(MAIN_GAME_SCENE)

func _on_host_pressed() -> void:
	_set_menu_busy(true)
	_set_status("Connecting...", Color(0.7, 0.55, 0.95))
	await MultiplayerManager.disconnect_server()

	var ign = _get_ign()
	MultiplayerManager.player_ign = ign
	var connected = await MultiplayerManager.connect_to_server("host_" + str(Time.get_unix_time_from_system()))
	if connected:
		_set_status("Creating room on " + MultiplayerManager.get_server_endpoint_summary() + "...", Color(0.7, 0.55, 0.95))
		var room_id = await MultiplayerManager.create_room()
		if not room_id.is_empty():
			get_tree().change_scene_to_file(ROOM_LOBBY_SCENE)
		else:
			_set_status("Failed to create room", Color(0.9, 0.4, 0.4))
	else:
		_set_status("Connection failed: " + MultiplayerManager.get_server_endpoint_summary(), Color(0.9, 0.4, 0.4))
	_set_menu_busy(false)

func _on_connect_pressed() -> void:
	var room_code = code_input.text.strip_edges()
	if room_code.is_empty():
		_set_status("Enter a room code first", Color(0.9, 0.7, 0.3))
		return

	_set_menu_busy(true)
	_set_status("Connecting...", Color(0.2, 0.8, 0.55))
	await MultiplayerManager.disconnect_server()

	var ign = _get_ign()
	MultiplayerManager.player_ign = ign
	var connected = await MultiplayerManager.connect_to_server("guest_" + str(Time.get_unix_time_from_system()))
	if connected:
		_set_status("Joining via " + MultiplayerManager.get_server_endpoint_summary() + "...", Color(0.2, 0.8, 0.55))
		var joined = await MultiplayerManager.join_room(room_code)
		if joined:
			get_tree().change_scene_to_file(ROOM_LOBBY_SCENE)
		else:
			_set_status("Failed to join room", Color(0.9, 0.4, 0.4))
	else:
		_set_status("Connection failed: " + MultiplayerManager.get_server_endpoint_summary(), Color(0.9, 0.4, 0.4))
	_set_menu_busy(false)

func _on_quit_pressed() -> void:
	get_tree().quit()
