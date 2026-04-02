extends Control

@onready var start_button: Button = %StartButton
@onready var host_button: Button = %HostButton
@onready var connect_button: Button = %ConnectButton
@onready var code_input: LineEdit = %CodeInput
@onready var ign_input: LineEdit = %IGNInput
@onready var status_label: Label = %StatusLabel
@onready var quit_button: Button = %QuitButton

const MAIN_GAME_SCENE = "res://scenes/levels/main.tscn"
const ROOM_LOBBY_SCENE = "res://scenes/ui/room_lobby.tscn"

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	host_button.pressed.connect(_on_host_pressed)
	connect_button.pressed.connect(_on_connect_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _set_status(text: String, color: Color = Color(0.6, 0.62, 0.75, 0.7)):
	status_label.text = text
	status_label.add_theme_color_override("font_color", color)

func _set_buttons_enabled(enabled: bool):
	start_button.disabled = !enabled
	host_button.disabled = !enabled
	connect_button.disabled = !enabled

func _get_ign() -> String:
	var ign = ign_input.text.strip_edges()
	if ign.is_empty():
		ign = "Player" + str(randi_range(1000, 9999))
		print("Generated random IGN: " + ign)
	return ign

func _on_start_pressed():
	_set_status("Loading...", Color(0.55, 0.75, 0.95))
	get_tree().change_scene_to_file(MAIN_GAME_SCENE)

func _on_host_pressed():
	_set_buttons_enabled(false)
	_set_status("Connecting...", Color(0.7, 0.55, 0.95))
	await MultiplayerManager.disconnect_server()

	var ign = _get_ign()
	MultiplayerManager.player_ign = ign
	print("Hosting with IGN: " + ign)
	
	var connected = await MultiplayerManager.connect_to_server("host_" + str(Time.get_unix_time_from_system()))
	print("Connection result: " + str(connected))
	if connected:
		_set_status("Creating room...", Color(0.7, 0.55, 0.95))
		var room_id = await MultiplayerManager.create_room()
		print("Room created: " + room_id)
		if not room_id.is_empty():
			get_tree().change_scene_to_file(ROOM_LOBBY_SCENE)
		else:
			_set_status("Failed to create room", Color(0.9, 0.4, 0.4))
			print("Failed to create room - empty room ID")
	else:
		_set_status("Connection failed", Color(0.9, 0.4, 0.4))
		print("Failed to connect to server")
	_set_buttons_enabled(true)

func _on_connect_pressed():
	var room_code = code_input.text.strip_edges()
	if room_code.is_empty():
		_set_status("Enter a room code first", Color(0.9, 0.7, 0.3))
		return
	
	_set_buttons_enabled(false)
	_set_status("Connecting...", Color(0.2, 0.8, 0.55))
	await MultiplayerManager.disconnect_server()

	var ign = _get_ign()
	MultiplayerManager.player_ign = ign
	
	var connected = await MultiplayerManager.connect_to_server("guest_" + str(Time.get_unix_time_from_system()))
	if connected:
		_set_status("Joining room...", Color(0.2, 0.8, 0.55))
		var joined = await MultiplayerManager.join_room(room_code)
		if joined:
			print("Joined room: " + room_code)
			get_tree().change_scene_to_file(ROOM_LOBBY_SCENE)
		else:
			_set_status("Failed to join room", Color(0.9, 0.4, 0.4))
			print("Failed to join room")
	else:
		_set_status("Connection failed", Color(0.9, 0.4, 0.4))
		print("Failed to connect to server")
	_set_buttons_enabled(true)

func _on_quit_pressed():
	get_tree().quit()
