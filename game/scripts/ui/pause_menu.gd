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
	await _restart_current_run()

func _on_menu_pressed():
	if get_tree() != null and get_tree().root != null and get_tree().root.has_node("SkillTreeManager"):
		get_tree().root.get_node("SkillTreeManager").call("persist_to_disk")
	get_tree().paused = false
	await MultiplayerManager.disconnect_server()
	get_tree().change_scene_to_file(main_menu_scene_path)


func _restart_current_run() -> void:
	var tree := get_tree()
	if tree == null:
		return

	get_tree().paused = false
	restart_button.disabled = true
	menu_button.disabled = true
	resume_button.disabled = true
	pause_panel.hide()
	overlay.hide()

	var current_scene := tree.current_scene
	var scene_path := current_scene.scene_file_path if current_scene != null else ""
	if scene_path.is_empty():
		push_error("[PauseMenu] Cannot restart run without a valid current scene path.")
		restart_button.disabled = false
		menu_button.disabled = false
		resume_button.disabled = false
		return

	var preserved_class: PlayerClass = MultiplayerManager.player_class
	if tree.root != null and tree.root.has_node("SkillTreeManager"):
		tree.root.get_node("SkillTreeManager").call("persist_to_disk")
	await MultiplayerManager.disconnect_server()
	MultiplayerManager.player_class = preserved_class
	MultiplayerManager.player_subclass = null
	MultiplayerManager.subclass_choice_made = false
	MultiplayerManager.player_level = 1
	CoinManager.reset_coins()
	LevelSystem.reset_run_state()

	await tree.process_frame
	tree.call_deferred("change_scene_to_file", scene_path)
