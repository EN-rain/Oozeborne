extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var host_button: Button = $VBoxContainer/HostButton
@onready var connect_button: Button = $VBoxContainer/ConnectButton
@onready var code_input: LineEdit = $VBoxContainer/CodeInput
@onready var ign_input: LineEdit = $VBoxContainer/IGNInput
@onready var title_label: Label = $TitleLabel

const MAIN_GAME_SCENE = "res://scenes/levels/main.tscn"
const ROOM_LOBBY_SCENE = "res://scenes/ui/room_lobby.tscn"

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	host_button.pressed.connect(_on_host_pressed)
	connect_button.pressed.connect(_on_connect_pressed)

func _on_start_pressed():
	get_tree().change_scene_to_file(MAIN_GAME_SCENE)

func _on_host_pressed():
	await MultiplayerManager.disconnect_server()

	var ign = ign_input.text.strip_edges()
	if ign.is_empty():
		ign = "Player" + str(randi_range(1000, 9999))
		print("Generated random IGN: " + ign)
	
	MultiplayerManager.player_ign = ign
	print("Hosting with IGN: " + ign)
	
	# Connect to Nakama and create a room
	var connected = await MultiplayerManager.connect_to_server("host_" + str(Time.get_unix_time_from_system()))
	print("Connection result: " + str(connected))
	if connected:
		var room_id = await MultiplayerManager.create_room()
		print("Room created: " + room_id)
		if not room_id.is_empty():
			get_tree().change_scene_to_file(ROOM_LOBBY_SCENE)
		else:
			print("Failed to create room - empty room ID")
	else:
		print("Failed to connect to server")

func _on_connect_pressed():
	await MultiplayerManager.disconnect_server()

	var room_code = code_input.text.strip_edges()
	var ign = ign_input.text.strip_edges()
	
	if room_code.is_empty():
		print("Please enter a room code")
		return
	
	if ign.is_empty():
		ign = "Player" + str(randi_range(1000, 9999))
		print("Generated random IGN: " + ign)
	
	MultiplayerManager.player_ign = ign
	
	# Connect to Nakama and join room
	var connected = await MultiplayerManager.connect_to_server("guest_" + str(Time.get_unix_time_from_system()))
	if connected:
		var joined = await MultiplayerManager.join_room(room_code)
		if joined:
			print("Joined room: " + room_code)
			get_tree().change_scene_to_file(ROOM_LOBBY_SCENE)
		else:
			print("Failed to join room")
	else:
		print("Failed to connect to server")
