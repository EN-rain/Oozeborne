extends PanelContainer

## DevToolsPanel - Debug panel for testing gameplay features
## Allows modifying level, spawning mobs, and changing class

signal closed

@onready var close_button: Button = $VBoxContainer/Header/CloseButton
@onready var level_spinbox: SpinBox = $VBoxContainer/LevelSection/LevelSpinbox
@onready var set_level_button: Button = $VBoxContainer/LevelSection/SetLevelButton
@onready var spawn_common_button: Button = $VBoxContainer/SpawnSection/SpawnCommonButton
@onready var spawn_elite_button: Button = $VBoxContainer/SpawnSection/SpawnEliteButton
@onready var spawn_count_spinbox: SpinBox = $VBoxContainer/SpawnSection/SpawnCountSpinbox
@onready var class_option: OptionButton = $VBoxContainer/ClassSection/ClassOption
@onready var apply_class_button: Button = $VBoxContainer/ClassSection/ApplyClassButton

var _player_ref: CharacterBody2D = null
var _mob_spawner_ref: MobSpawner = null

func _ready() -> void:
	_setup_signals()
	_populate_class_options()
	hide()

func _setup_signals() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if set_level_button:
		set_level_button.pressed.connect(_on_set_level_pressed)
	if spawn_common_button:
		spawn_common_button.pressed.connect(_on_spawn_common_pressed)
	if spawn_elite_button:
		spawn_elite_button.pressed.connect(_on_spawn_elite_pressed)
	if apply_class_button:
		apply_class_button.pressed.connect(_on_apply_class_pressed)

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
	if level_spinbox and _player_ref:
		level_spinbox.value = LevelSystem.get_level(_player_ref)

func set_mob_spawner(spawner: MobSpawner) -> void:
	_mob_spawner_ref = spawner

func open() -> void:
	show()
	if _player_ref and level_spinbox:
		level_spinbox.value = LevelSystem.get_level(_player_ref)

func close() -> void:
	hide()
	closed.emit()

func _on_close_pressed() -> void:
	close()

func _on_set_level_pressed() -> void:
	if _player_ref == null or level_spinbox == null:
		return
	var target_level := int(level_spinbox.value)
	LevelSystem.set_level(_player_ref, target_level)
	print("[DevTools] Set player level to %d" % target_level)

func _on_spawn_common_pressed() -> void:
	if _mob_spawner_ref == null:
		push_warning("[DevTools] MobSpawner not set, cannot spawn mobs")
		return
	var count := int(spawn_count_spinbox.value) if spawn_count_spinbox else 1
	for i in range(count):
		_mob_spawner_ref.spawn_common_mob()
	print("[DevTools] Spawned %d common mobs" % count)

func _on_spawn_elite_pressed() -> void:
	if _mob_spawner_ref == null:
		push_warning("[DevTools] MobSpawner not set, cannot spawn mobs")
		return
	var count := int(spawn_count_spinbox.value) if spawn_count_spinbox else 1
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
