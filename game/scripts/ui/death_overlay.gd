extends Control

@onready var color_rect: ColorRect = $ColorRect
@onready var death_card: PanelContainer = $DeathCard
@onready var death_card_animation_player: AnimationPlayer = $DeathCard/AnimationPlayer
@onready var death_title_label: Label = $DeathCard/VBoxContainer/YouDiedLabel
@onready var death_message_label: Label = $DeathCard/VBoxContainer/KillerLabel
@onready var death_card_content: VBoxContainer = $DeathCard/VBoxContainer
@onready var final_score_label: Label = $DeathCard/VBoxContainer/FinalScore
@onready var restart_button: Button = $DeathCard/VBoxContainer/Restart
@onready var menu_button: Button = $DeathCard/VBoxContainer/MenuButton

@export var main_menu_scene: PackedScene
@export_file("*.json") var death_messages_json_path: String = "res://resources/data/death_messages.json"

var _funny_suffixes: Array[String] = [
	"That was not your best shift.",
	"The respawn desk has questions.",
	"An extremely avoidable tragedy.",
	"That creature now has confidence.",
	"The guild will pretend this never happened."
]


func _ready() -> void:
	visible = false
	_load_death_messages()


func show_death_screen(final_score: int, killer_name: String) -> void:
	if death_title_label:
		death_title_label.text = "Run Over"
	if death_message_label:
		death_message_label.text = _build_death_message(killer_name)
	if final_score_label:
		final_score_label.text = "Final Score: %d" % final_score

	visible = true
	_play_slide_in_animation()


func _play_slide_in_animation() -> void:
	# Reset to initial state for animation (card below screen)
	if color_rect:
		color_rect.color = Color(0, 0, 0, 0)
	if death_card:
		death_card.modulate = Color(1, 1, 1, 0)
		death_card.anchor_top = 1.2
		death_card.anchor_bottom = 1.2
	if death_card_content:
		death_card_content.modulate = Color(1, 1, 1, 0)

	# Use Tween for animation (works with pause mode)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	
	# Animate ColorRect fade to black
	if color_rect:
		tween.tween_property(color_rect, "color", Color(0, 0, 0, 0.6), 0.3)
	
	# Animate DeathCard sliding up and fading in
	if death_card:
		tween.parallel().tween_property(death_card, "anchor_top", 0.5, 0.5)
		tween.parallel().tween_property(death_card, "anchor_bottom", 0.5, 0.5)
		tween.parallel().tween_property(death_card, "modulate", Color(1, 1, 1, 1), 0.5)
	
	# Also animate content to visible
	if death_card_content:
		tween.parallel().tween_property(death_card_content, "modulate", Color(1, 1, 1, 1), 0.5)


func _build_death_message(killer_name: String) -> String:
	var resolved_killer := killer_name.strip_edges()
	if resolved_killer.is_empty():
		resolved_killer = "something rude"
	return "You were killed by %s. %s" % [resolved_killer, _funny_suffixes[randi() % _funny_suffixes.size()]]


func _load_death_messages() -> void:
	if death_messages_json_path.is_empty():
		return

	if not FileAccess.file_exists(death_messages_json_path):
		push_warning("[DeathOverlay] Missing death messages JSON: %s" % death_messages_json_path)
		return

	var file := FileAccess.open(death_messages_json_path, FileAccess.READ)
	if file == null:
		push_warning("[DeathOverlay] Failed to open death messages JSON: %s" % death_messages_json_path)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_warning("[DeathOverlay] Invalid death messages JSON format: %s" % death_messages_json_path)
		return

	var funny_suffixes: Variant = parsed.get("funny_suffixes", [])
	if not (funny_suffixes is Array) or funny_suffixes.is_empty():
		push_warning("[DeathOverlay] Missing funny_suffixes in death messages JSON: %s" % death_messages_json_path)
		return

	var loaded_suffixes: Array[String] = []
	for suffix in funny_suffixes:
		var text := str(suffix).strip_edges()
		if not text.is_empty():
			loaded_suffixes.append(text)

	if loaded_suffixes.is_empty():
		push_warning("[DeathOverlay] No valid death message suffixes found in: %s" % death_messages_json_path)
		return

	_funny_suffixes = loaded_suffixes


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	await MultiplayerManager.disconnect_server()
	if main_menu_scene != null:
		get_tree().change_scene_to_packed(main_menu_scene)
