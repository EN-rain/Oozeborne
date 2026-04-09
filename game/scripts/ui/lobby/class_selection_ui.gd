extends Control
class_name ClassSelectionUI

const ClassManagerScript := preload("res://scripts/globals/class_manager.gd")
const ClassSelectionMainSlotScript := preload("res://scripts/ui/lobby/class_selection_main_slot.gd")

## Main-class-only selection screen.
## Subclass is chosen later in-game at level 10.

signal class_selected(p_class, sub_class)


@export var auto_start_solo_game: bool = false
@export_range(1, 11) var max_main_class_options: int = 5
@export_file("*.tscn") var solo_game_scene_path: String
@export var main_class_slot_paths: Array[NodePath] = []

@onready var class_name_label: Label = %ClassNameLabel
@onready var class_desc_label: Label = %ClassDescLabel
@onready var stats_label: Label = %StatsLabel
@onready var ability_label: Label = %AbilityLabel
@onready var passive_label: Label = %PassiveLabel
@onready var select_button: Button = %SelectButton
@onready var right_panel: PanelContainer = %RightPanel
@onready var subclasses_subtitle_label: Label = %SubtitleLabel
@onready var subclass_preview_label: Label = %SubclassPreviewLabel

var available_main_classes: Array[PlayerClass] = []
var selected_class: PlayerClass = null
var player_level: int = 1

var _main_class_slots: Array[Node] = []
var _active_main_class_slot = null
var _hovered_main_class_slot = null

const DEFAULT_MAIN_BUTTON_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const HOVERED_MAIN_BUTTON_COLOR := Color(1.08, 1.05, 0.92, 1.0)
const ACTIVE_MAIN_BUTTON_COLOR := Color(1.18, 1.1, 0.88, 1.0)
const SUBCLASS_HINT := "Subclasses unlock in-game at Level 10"

@export var default_main_button_color: Color = DEFAULT_MAIN_BUTTON_COLOR
@export var hovered_main_button_color: Color = HOVERED_MAIN_BUTTON_COLOR
@export var active_main_button_color: Color = ACTIVE_MAIN_BUTTON_COLOR
@export var subclass_hint_text: String = SUBCLASS_HINT
@export var confirm_button_format: String = "Confirm %s"
@export var starting_text: String = "Starting..."
@export var selected_button_format: String = "%s Selected!"
@export var stats_prefix: String = "Stats: "
@export var base_values_text: String = "Base values"
@export var ability_prefix: String = "Ability: "
@export var passive_prefix: String = "Passive: "


func _ready() -> void:
	player_level = maxi(MultiplayerManager.player_level, 1)
	_load_available_classes()
	_setup_ui()


func _load_available_classes() -> void:
	available_main_classes = ClassManagerScript.get_main_classes()
	if available_main_classes.size() > max_main_class_options:
		available_main_classes = available_main_classes.slice(0, max_main_class_options)


func _setup_ui() -> void:
	if select_button == null or right_panel == null or subclass_preview_label == null:
		push_error("ClassSelectionUI is missing required UI nodes.")
		return
	_resolve_main_class_slots()
	_populate_main_class_slots()
	_set_subclass_panel_visible(false)
	select_button.disabled = true


func _resolve_main_class_slots() -> void:
	_main_class_slots.clear()
	for slot_path in main_class_slot_paths:
		var slot: Node = get_node_or_null(slot_path)
		if slot == null:
			continue
		if not slot.slot_pressed.is_connected(_on_main_class_slot_pressed):
			slot.slot_pressed.connect(_on_main_class_slot_pressed)
		if not slot.slot_hovered.is_connected(_on_main_class_slot_hovered):
			slot.slot_hovered.connect(_on_main_class_slot_hovered)
		if not slot.slot_unhovered.is_connected(_on_main_class_slot_unhovered):
			slot.slot_unhovered.connect(_on_main_class_slot_unhovered)
		_main_class_slots.append(slot)


func _populate_main_class_slots() -> void:
	_active_main_class_slot = null
	_hovered_main_class_slot = null
	for index in range(_main_class_slots.size()):
		var slot: Node = _main_class_slots[index]
		var next_class: PlayerClass = available_main_classes[index] if index < available_main_classes.size() else null
		slot.configure(next_class)
	_refresh_main_class_slot_visuals()


func _on_main_class_slot_pressed(slot) -> void:
	_active_main_class_slot = slot
	selected_class = slot.player_class
	_update_class_info(selected_class)
	_refresh_main_class_slot_visuals()
	select_button.disabled = false
	select_button.text = confirm_button_format % selected_class.display_name


func _on_main_class_slot_hovered(slot) -> void:
	_hovered_main_class_slot = slot
	_refresh_main_class_slot_visuals()
	_update_class_info(slot.player_class)


func _on_main_class_slot_unhovered(slot) -> void:
	if _hovered_main_class_slot == slot:
		_hovered_main_class_slot = null
	_refresh_main_class_slot_visuals()
	if selected_class != null:
		_update_class_info(selected_class)


func _refresh_main_class_slot_visuals() -> void:
	for slot in _main_class_slots:
		if slot == _active_main_class_slot:
			slot.set_state_color(active_main_button_color)
		elif slot == _hovered_main_class_slot:
			slot.set_state_color(hovered_main_button_color)
		else:
			slot.set_state_color(default_main_button_color)


func _set_subclass_panel_visible(panel_visible: bool) -> void:
	if right_panel == null:
		return
	right_panel.modulate = Color(1.0, 1.0, 1.0, 1.0 if panel_visible else 0.72)
	if subclass_preview_label != null:
		subclass_preview_label.visible = panel_visible
	if subclasses_subtitle_label != null:
		subclasses_subtitle_label.text = subclass_hint_text


func _populate_subclass_preview(main_class: PlayerClass) -> void:
	if subclass_preview_label == null:
		return
	if main_class == null:
		subclass_preview_label.text = ""
		return

	var subclasses: Array[PlayerClass] = ClassManagerScript.get_subclasses_for_main_class(main_class)
	var lines: PackedStringArray = []
	for subclass in subclasses:
		lines.append("%s - %s" % [subclass.display_name, subclass.description])
	subclass_preview_label.text = "\n\n".join(lines)


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
	if target_class.modifiers_crit_damage != 1.0:
		stats_parts.append("CRIT DMG %+.0f%%" % [(target_class.modifiers_crit_damage - 1.0) * 100])

	stats_label.text = stats_prefix + (" | ".join(stats_parts) if stats_parts.size() > 0 else base_values_text)
	ability_label.text = ability_prefix + target_class.ability_name + "\n" + target_class.ability_description if target_class.ability_name else ""
	passive_label.text = passive_prefix + target_class.passive_name + "\n" + target_class.passive_description if target_class.passive_name else ""


func _on_select_pressed() -> void:
	if selected_class == null:
		return
	await _on_select_pressed_for_class(selected_class)
	var tree := get_tree()
	if tree == null:
		return
	await tree.create_timer(1.0).timeout
	if not is_inside_tree():
		return
	if is_instance_valid(select_button):
		select_button.disabled = false
		select_button.text = confirm_button_format % selected_class.display_name


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
	var class_id := ClassManagerScript.get_class_id(player_class)
	var resolved_class := ClassManagerScript.create_class_instance(class_id) if not class_id.is_empty() else player_class
	selected_class = resolved_class
	_update_class_info(selected_class)
	MultiplayerManager.player_class = selected_class
	MultiplayerManager.player_subclass = null
	MultiplayerManager.subclass_choice_made = false
	class_selected.emit(selected_class, null)

	if auto_start_solo_game:
		select_button.text = starting_text
		select_button.disabled = true
		await get_tree().process_frame
		get_tree().change_scene_to_file(solo_game_scene_path)
		return

	select_button.text = selected_button_format % selected_class.display_name
	select_button.disabled = true
