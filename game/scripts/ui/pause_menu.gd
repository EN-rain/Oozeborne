extends CanvasLayer

@onready var pause_panel: Panel = %PausePanel
@onready var overlay: ColorRect = %Overlay
@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var menu_button: Button = %MenuButton

@export_file("*.tscn") var main_menu_scene_path: String

func _ready():
	pause_panel.hide()
	overlay.hide()

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
	get_tree().change_scene_to_file(main_menu_scene_path)
