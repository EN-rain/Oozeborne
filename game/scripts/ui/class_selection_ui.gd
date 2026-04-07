extends Control
class_name ClassSelectionUI

## Main-class-only selection screen.
## Subclass is chosen later in-game at level 10.

const CLASS_MANAGER_SCRIPT := preload("res://scripts/globals/class_manager.gd")


signal class_selected(p_class, sub_class)


@export var auto_start_solo_game: bool = false
@export_range(1, 11) var max_main_class_options: int = 5

@export_file("*.tscn") var solo_game_scene_path: String

@onready var main_classes_vbox: VBoxContainer = %MainClassesVBox
@onready var subclasses_vbox: VBoxContainer = %SubclassesVBox
@onready var class_name_label: Label = %ClassNameLabel
@onready var class_desc_label: Label = %ClassDescLabel
@onready var stats_label: Label = %StatsLabel
@onready var ability_label: Label = %AbilityLabel
@onready var passive_label: Label = %PassiveLabel
@onready var select_button: Button = %SelectButton
@onready var right_panel: PanelContainer = $RightPanel
@onready var subclasses_subtitle_label: Label = $RightPanel/VBox/SubtitleLabel

var available_main_classes: Array[PlayerClass] = []
var selected_class: PlayerClass = null
var player_level: int = 1

var _active_main_class_button: Button = null
var _hovered_main_class_button: Button = null

const DEFAULT_MAIN_BUTTON_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const HOVERED_MAIN_BUTTON_COLOR := Color(1.08, 1.05, 0.92, 1.0)
const ACTIVE_MAIN_BUTTON_COLOR := Color(1.18, 1.1, 0.88, 1.0)
const SUBCLASS_HINT := "Subclasses unlock in-game at Level 10"


func _ready() -> void:
	player_level = max(MultiplayerManager.player_level, 1)
	_load_available_classes()
	_setup_ui()


func _load_available_classes() -> void:
	available_main_classes = CLASS_MANAGER_SCRIPT.get_main_classes()
	if available_main_classes.size() > max_main_class_options:
		available_main_classes = available_main_classes.slice(0, max_main_class_options)


func _setup_ui() -> void:
	if main_classes_vbox == null or select_button == null or right_panel == null:
		push_error("ClassSelectionUI is missing required UI nodes.")
		return
	_populate_main_classes()
	_set_subclass_panel_visible(false)
	select_button.disabled = true


func _populate_main_classes() -> void:
	for child in main_classes_vbox.get_children():
		child.queue_free()

	_active_main_class_button = null
	for p_class in available_main_classes:
		var card := Button.new()
		card.custom_minimum_size = Vector2(0, 42)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.toggle_mode = true
		card.text = p_class.display_name
		card.pressed.connect(_on_main_class_button_pressed.bind(p_class, card))
		card.mouse_entered.connect(_on_main_class_hovered.bind(p_class, card))
		card.mouse_exited.connect(_on_main_class_hover_exited.bind(card))
		main_classes_vbox.add_child(card)

	_refresh_main_class_button_visuals()


func _on_main_class_button_pressed(player_class: PlayerClass, btn: Button) -> void:
	if _active_main_class_button and is_instance_valid(_active_main_class_button) and _active_main_class_button != btn:
		_active_main_class_button.button_pressed = false
	_active_main_class_button = btn
	selected_class = player_class
	_update_class_info(selected_class)
	_refresh_main_class_button_visuals()
	select_button.disabled = false
	select_button.text = "Confirm " + player_class.display_name


func _on_main_class_hovered(player_class: PlayerClass, btn: Button) -> void:
	_hovered_main_class_button = btn
	_refresh_main_class_button_visuals()
	_update_class_info(player_class)


func _on_main_class_hover_exited(btn: Button) -> void:
	if _hovered_main_class_button == btn:
		_hovered_main_class_button = null
	_refresh_main_class_button_visuals()
	if selected_class != null:
		_update_class_info(selected_class)


func _refresh_main_class_button_visuals() -> void:
	for child in main_classes_vbox.get_children():
		var button := child as Button
		if button == null:
			continue
		if button == _active_main_class_button:
			button.modulate = ACTIVE_MAIN_BUTTON_COLOR
		elif button == _hovered_main_class_button:
			button.modulate = HOVERED_MAIN_BUTTON_COLOR
		else:
			button.modulate = DEFAULT_MAIN_BUTTON_COLOR


func _set_subclass_panel_visible(panel_visible: bool) -> void:
	if right_panel == null:
		return
	right_panel.modulate = Color(1.0, 1.0, 1.0, 1.0 if panel_visible else 0.72)
	if subclasses_vbox != null:
		subclasses_vbox.visible = panel_visible
	if subclasses_subtitle_label != null:
		subclasses_subtitle_label.text = SUBCLASS_HINT


func _populate_subclass_preview(main_class: PlayerClass) -> void:
	if subclasses_vbox == null:
		return
	for child in subclasses_vbox.get_children():
		child.queue_free()
	if main_class == null:
		return

	var subclasses := CLASS_MANAGER_SCRIPT.get_subclasses_for_main_class(main_class)
	for subclass in subclasses:
		var card := Label.new()
		card.custom_minimum_size = Vector2(0, 42)
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.text = "%s - %s" % [subclass.display_name, subclass.description]
		subclasses_vbox.add_child(card)


func _update_class_info(target_class: PlayerClass) -> void:
	if target_class == null:
		return

	_set_subclass_panel_visible(true)
	_populate_subclass_preview(target_class)

	class_name_label.text = target_class.display_name
	class_desc_label.text = target_class.description

	var stats_parts: Array = []
	if target_class.modifiers_hp != 1.0:
		stats_parts.append("HP %+.0f%%" % [(target_class.modifiers_hp - 1.0) * 100])
	if target_class.modifiers_speed != 1.0:
		stats_parts.append("SPD %+.0f%%" % [(target_class.modifiers_speed - 1.0) * 100])
	if target_class.modifiers_damage != 1.0:
		stats_parts.append("DMG %+.0f%%" % [(target_class.modifiers_damage - 1.0) * 100])
	if target_class.modifiers_defense != 1.0:
		stats_parts.append("DEF %+.0f%%" % [(target_class.modifiers_defense - 1.0) * 100])
	if target_class.modifiers_attack_speed != 1.0:
		stats_parts.append("ATKSPD %+.0f%%" % [(target_class.modifiers_attack_speed - 1.0) * 100])
	if target_class.modifiers_crit_chance != 1.0:
		stats_parts.append("CRIT %+.0f%%" % [(target_class.modifiers_crit_chance - 1.0) * 100])

	stats_label.text = "Stats: " + (" | ".join(stats_parts) if stats_parts.size() > 0 else "Base values")
	ability_label.text = "Ability: " + target_class.ability_name + "\n" + target_class.ability_description if target_class.ability_name else ""
	passive_label.text = "Passive: " + target_class.passive_name + "\n" + target_class.passive_description if target_class.passive_name else ""


func _on_select_pressed() -> void:
	if selected_class == null:
		return
	await _on_select_pressed_for_class(selected_class)
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(select_button):
		select_button.disabled = false
		select_button.text = "Confirm " + selected_class.display_name


func set_player_level(level: int) -> void:
	player_level = level


func get_selected_class() -> PlayerClass:
	return selected_class


func get_selected_subclass() -> PlayerClass:
	return null


func auto_select_random_class() -> PlayerClass:
	if available_main_classes.is_empty():
		return null
	var random_class: PlayerClass = available_main_classes[randi() % available_main_classes.size()]
	await _on_select_pressed_for_class(random_class)
	return random_class


func _on_select_pressed_for_class(player_class: PlayerClass) -> void:
	selected_class = player_class
	_update_class_info(selected_class)
	MultiplayerManager.player_class = selected_class
	MultiplayerManager.player_subclass = null
	MultiplayerManager.subclass_choice_made = false
	class_selected.emit(selected_class, null)

	if auto_start_solo_game:
		select_button.text = "Starting..."
		select_button.disabled = true
		await get_tree().process_frame
		get_tree().change_scene_to_file(solo_game_scene_path)
		return

	select_button.text = selected_class.display_name + " Selected!"
	select_button.disabled = true
