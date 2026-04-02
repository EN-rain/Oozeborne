extends CanvasLayer

@onready var pause_panel: Panel = $PausePanel
@onready var overlay: ColorRect = $Overlay
@onready var resume_button: Button = $PausePanel/VBoxContainer/ResumeButton
@onready var restart_button: Button = $PausePanel/VBoxContainer/RestartButton
@onready var menu_button: Button = $PausePanel/VBoxContainer/MenuButton

const MAIN_MENU_SCENE = "res://scenes/ui/main_menu.tscn"

func _ready():
	pause_panel.hide()
	overlay.hide()
	
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _input(event):
	if event.is_action_pressed("pause"):
		_toggle_pause()

func _toggle_pause():
	if get_tree().paused:
		_resume()
	else:
		_pause()

func _pause():
	get_tree().paused = true
	pause_panel.show()
	overlay.show()

func _resume():
	get_tree().paused = false
	pause_panel.hide()
	overlay.hide()

func _on_resume_pressed():
	_resume()

func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed():
	get_tree().paused = false
	await MultiplayerManager.disconnect_server()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
