extends PanelContainer

## DevToolsPanel - Debug panel for testing gameplay features
## Allows modifying level, spawning mobs, and changing class

signal closed
const MAX_DEBUG_LEVEL := 100
const MAX_SPAWN_COUNT := 50

@onready var close_button: Button = %CloseButton
@onready var level_input: LineEdit = %LevelInput
@onready var set_level_button: Button = %SetLevelButton
@onready var max_level_button: Button = %MaxLevelButton
@onready var reset_level_button: Button = %ResetLevelButton
@onready var spawn_common_button: Button = %SpawnCommonButton
@onready var spawn_elite_button: Button = %SpawnEliteButton
@onready var spawn_count_input: LineEdit = %SpawnCountInput
@onready var class_option: OptionButton = %ClassOption
@onready var apply_class_button: Button = %ApplyClassButton

var _player_ref: CharacterBody2D = null
var _mob_spawner_ref: MobSpawner = null

func _ready() -> void:
	_populate_class_options()
	hide()

func _populate_class_options() -> void:
	if class_option == null:
		return
	class_option.clear()
	
	# Add main classes
	var main_classes := ClassManager.get_main_classes()
	for player_class in main_classes:
		class_option.add_item(player_class.display_name)
	
	# Add separator
	class_option.add_separator()
	
	# Add subclasses
	var subclasses := ClassManager.get_subclasses()
	for player_class in subclasses:
		class_option.add_item(player_class.display_name)

func set_player(player: CharacterBody2D) -> void:
	_player_ref = player
	if level_input and _player_ref:
		level_input.text = str(_sanitize_level(LevelSystem.get_level(_player_ref)))

func set_mob_spawner(spawner: MobSpawner) -> void:
	_mob_spawner_ref = spawner

func open() -> void:
	show()
	if _player_ref and level_input:
		level_input.text = str(_sanitize_level(LevelSystem.get_level(_player_ref)))
	if close_button != null:
		close_button.grab_focus.call_deferred()

func close() -> void:
	hide()
	closed.emit()

func _on_close_pressed() -> void:
	close()

func _on_level_input_submitted(_text: String) -> void:
	_on_set_level_pressed()

func _on_set_level_pressed() -> void:
	if _player_ref == null or level_input == null:
		return
	var target_level := _parse_level_input()
	level_input.text = str(target_level)
	LevelSystem.set_level(_player_ref, target_level)
	print("[DevTools] Set player level to %d" % target_level)

func _on_max_level_pressed() -> void:
	if _player_ref == null or level_input == null:
		return
	level_input.text = str(MAX_DEBUG_LEVEL)
	LevelSystem.set_level(_player_ref, MAX_DEBUG_LEVEL)
	print("[DevTools] Set player level to %d" % MAX_DEBUG_LEVEL)

func _on_reset_level_pressed() -> void:
	if _player_ref == null or level_input == null:
		return
	level_input.text = "1"
	LevelSystem.set_level(_player_ref, 1)
	print("[DevTools] Reset player level to 1")

func _on_spawn_count_input_submitted(_text: String) -> void:
	if spawn_count_input == null:
		return
	spawn_count_input.text = str(_parse_spawn_count())

func _on_spawn_common_pressed() -> void:
	if _mob_spawner_ref == null:
		push_warning("[DevTools] MobSpawner not set, cannot spawn mobs")
		return
	var count := _parse_spawn_count()
	if spawn_count_input != null:
		spawn_count_input.text = str(count)
	for i in range(count):
		_mob_spawner_ref.spawn_common_mob()
	print("[DevTools] Spawned %d common mobs" % count)

func _on_spawn_elite_pressed() -> void:
	if _mob_spawner_ref == null:
		push_warning("[DevTools] MobSpawner not set, cannot spawn mobs")
		return
	var count := _parse_spawn_count()
	if spawn_count_input != null:
		spawn_count_input.text = str(count)
	for i in range(count):
		_mob_spawner_ref.spawn_elite_mob()
	print("[DevTools] Spawned %d elite mobs" % count)

func _on_apply_class_pressed() -> void:
	if _player_ref == null or class_option == null:
		return

	var selected_idx := class_option.selected
	if selected_idx < 0:
		return

	var selected_name := class_option.get_item_text(selected_idx)
	var class_id := ClassManager.display_name_to_class_id(selected_name)

	if class_id.is_empty():
		push_warning("[DevTools] Could not find class ID for: %s" % selected_name)
		return

	var new_class := ClassManager.create_class_instance(class_id)
	if new_class == null:
		push_warning("[DevTools] Could not create class instance for: %s" % class_id)
		return

	# Set the class
	MultiplayerManager.player_class = new_class

	# Apply class modifiers to player
	if _player_ref.has_method("_apply_class_modifiers"):
		_player_ref.call("_apply_class_modifiers")

	# Reapply level stats
	LevelSystem.set_level(_player_ref, LevelSystem.get_level(_player_ref))

	print("[DevTools] Applied class: %s (%s)" % [selected_name, class_id])

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		close()
		get_viewport().set_input_as_handled()


func _parse_level_input() -> int:
	if level_input == null:
		return 1
	var parsed_level := 1
	if level_input.text.is_valid_int():
		parsed_level = int(level_input.text)
	return _sanitize_level(parsed_level)


func _sanitize_level(level: int) -> int:
	return clampi(level, 1, MAX_DEBUG_LEVEL)


func _parse_spawn_count() -> int:
	if spawn_count_input == null:
		return 1
	var parsed_count := 1
	if spawn_count_input.text.is_valid_int():
		parsed_count = int(spawn_count_input.text)
	return clampi(parsed_count, 1, MAX_SPAWN_COUNT)
