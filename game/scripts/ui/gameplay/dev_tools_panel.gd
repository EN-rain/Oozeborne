extends Control

## DevToolsPanel - Debug panel for testing gameplay features
## Allows modifying level, spawning mobs, and changing class

signal closed
const MAX_DEBUG_LEVEL := 100
const MAX_SPAWN_COUNT := 50
const DEBUG_LOG_PREFIX := "[DevToolsPanel]"
const DEBUG_LOGS := false
const DEBUG_COMMON_MOB_SCENE_PATH := "res://scenes/entities/enemies/blue_slime.tscn"
const DEBUG_ELITE_LANCER_SCENE_PATH := "res://scenes/entities/enemies/plagued_lancer.tscn"
const DEBUG_ELITE_ARCHER_SCENE_PATH := "res://scenes/entities/enemies/archer.tscn"
const ClassManagerScript := preload("res://scripts/globals/class_manager.gd")

@onready var close_button: Button = %CloseButton
@onready var level_input: LineEdit = %LevelInput
@onready var set_level_button: Button = %SetLevelButton
@onready var max_level_button: Button = %MaxLevelButton
@onready var reset_level_button: Button = %ResetLevelButton
@onready var add_coins_button: Button = %AddCoinsButton
@onready var spawn_common_button: Button = %SpawnCommonButton
@onready var spawn_elite_button: Button = %SpawnEliteButton
@onready var spawn_count_input: LineEdit = %SpawnCountInput
@onready var class_option: OptionButton = %ClassOption
@onready var apply_class_button: Button = %ApplyClassButton
@onready var panel: PanelContainer = $Panel

var _player_ref: CharacterBody2D = null
var _mob_spawner_ref: MobSpawner = null

func _ready() -> void:
	_log("ready")
	_populate_class_options()
	_connect_debug_signals()
	hide()

func _populate_class_options() -> void:
	if class_option == null:
		return
	class_option.clear()
	
	# Add main classes
	var main_classes := ClassManagerScript.get_main_classes()
	for player_class in main_classes:
		class_option.add_item(player_class.display_name)
	
	# Add separator
	class_option.add_separator()
	
	# Add subclasses
	var subclasses := ClassManagerScript.get_subclasses()
	for player_class in subclasses:
		class_option.add_item(player_class.display_name)

func set_player(player: CharacterBody2D) -> void:
	_player_ref = player
	var player_name := "null"
	if player != null:
		player_name = player.name
	_log("set_player player=%s" % [player_name])
	if level_input and _player_ref:
		level_input.text = str(_sanitize_level(LevelSystem.get_level(_player_ref)))

func set_mob_spawner(spawner: MobSpawner) -> void:
	_mob_spawner_ref = spawner
	var spawner_name := "null"
	if spawner != null:
		spawner_name = spawner.name
	_log("set_mob_spawner spawner=%s" % [spawner_name])

func open() -> void:
	_ensure_debug_targets()
	_log("open visible_before=%s" % visible)
	show()
	if panel != null:
		panel.z_index = 100
	move_to_front()
	if _player_ref and level_input:
		level_input.text = str(_sanitize_level(LevelSystem.get_level(_player_ref)))
	if level_input != null:
		level_input.grab_focus.call_deferred()
		level_input.select_all()
	var hovered := get_viewport().gui_get_hovered_control()
	var level_text := "<missing>"
	if level_input != null:
		level_text = level_input.text
	var hovered_name := "<none>"
	if hovered != null:
		hovered_name = hovered.name
	_log("open complete level_text=%s hovered=%s" % [level_text, hovered_name])

func close() -> void:
	_log("close visible_before=%s" % visible)
	hide()
	closed.emit()

func _on_close_pressed() -> void:
	_log("close button pressed")
	close()

func _on_level_input_submitted(_text: String) -> void:
	_log("level submitted text=%s" % [level_input.text if level_input != null else "<missing>"])
	_on_set_level_pressed()

func _on_set_level_pressed() -> void:
	_ensure_debug_targets()
	_log("set level pressed text=%s" % [level_input.text if level_input != null else "<missing>"])
	if _player_ref == null or level_input == null:
		_log("set level aborted player_ref=%s level_input=%s" % [_player_ref != null, level_input != null])
		return
	var target_level := _parse_level_input()
	level_input.text = str(target_level)
	LevelSystem.set_level(_player_ref, target_level)
	_refresh_hud_level_display()
	_log("Set player level to %d" % target_level)

func _on_max_level_pressed() -> void:
	_ensure_debug_targets()
	_log("max level pressed")
	if _player_ref == null or level_input == null:
		_log("max level aborted player_ref=%s level_input=%s" % [_player_ref != null, level_input != null])
		return
	level_input.text = str(MAX_DEBUG_LEVEL)
	LevelSystem.set_level(_player_ref, MAX_DEBUG_LEVEL)
	_refresh_hud_level_display()
	_log("Set player level to %d" % MAX_DEBUG_LEVEL)

func _on_reset_level_pressed() -> void:
	_ensure_debug_targets()
	_log("reset level pressed")
	if _player_ref == null or level_input == null:
		_log("reset level aborted player_ref=%s level_input=%s" % [_player_ref != null, level_input != null])
		return
	level_input.text = "1"
	LevelSystem.set_level(_player_ref, 1)
	_refresh_hud_level_display()
	_log("Reset player level to 1")


func _on_add_coins_pressed() -> void:
	_ensure_debug_targets()
	CoinManager.add_coins(100)
	_log("Added 100 coins")

func _on_spawn_count_input_submitted(_text: String) -> void:
	_log("spawn count submitted text=%s" % [spawn_count_input.text if spawn_count_input != null else "<missing>"])
	if spawn_count_input == null:
		return
	spawn_count_input.text = str(_parse_spawn_count())

func _on_spawn_common_pressed() -> void:
	_ensure_debug_targets()
	_log("spawn common pressed text=%s" % [spawn_count_input.text if spawn_count_input != null else "<missing>"])
	var count := _parse_spawn_count()
	if spawn_count_input != null:
		spawn_count_input.text = str(count)
	if _mob_spawner_ref == null:
		if _spawn_debug_mobs(false, count):
			_log("Spawned %d common mobs" % count)
			return
		push_warning("[DevTools] MobSpawner not set, cannot spawn mobs")
		_log("spawn common aborted no spawner")
		return
	for i in range(count):
		_mob_spawner_ref.spawn_common_mob()
	_log("Spawned %d common mobs" % count)

func _on_spawn_elite_pressed() -> void:
	_ensure_debug_targets()
	_log("spawn elite pressed text=%s" % [spawn_count_input.text if spawn_count_input != null else "<missing>"])
	var count := _parse_spawn_count()
	if spawn_count_input != null:
		spawn_count_input.text = str(count)
	if _mob_spawner_ref == null:
		if _spawn_debug_mobs(true, count):
			_log("Spawned %d elite mobs" % count)
			return
		push_warning("[DevTools] MobSpawner not set, cannot spawn mobs")
		_log("spawn elite aborted no spawner")
		return
	for i in range(count):
		_mob_spawner_ref.spawn_elite_mob()
	_log("Spawned %d elite mobs" % count)

func _on_apply_class_pressed() -> void:
	_ensure_debug_targets()
	_log("apply class pressed selected=%s" % [class_option.selected if class_option != null else -999])
	if _player_ref == null or class_option == null:
		_log("apply class aborted player_ref=%s class_option=%s" % [_player_ref != null, class_option != null])
		return

	var selected_idx := class_option.selected
	if selected_idx < 0:
		return

	var selected_name := class_option.get_item_text(selected_idx)
	var class_id := ClassManagerScript.display_name_to_class_id(selected_name)

	if class_id.is_empty():
		push_warning("[DevTools] Could not find class ID for: %s" % selected_name)
		return

	var new_class := ClassManagerScript.create_class_instance(class_id)
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

	_log("Applied class: %s (%s)" % [selected_name, class_id])

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		_log("ui_cancel received")
		close()
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	_log_input("panel gui_input", event)


func _parse_level_input() -> int:
	if level_input == null:
		return 1
	var normalized_text := level_input.text.strip_edges()
	if not normalized_text.is_valid_int():
		var digits := ""
		for character in normalized_text:
			if character >= "0" and character <= "9":
				digits += character
		normalized_text = digits
	var parsed_level := 1
	if normalized_text.is_valid_int():
		parsed_level = int(normalized_text)
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


func _spawn_debug_mobs(use_elite_scene: bool, count: int) -> bool:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false

	for i in range(count):
		var mob_scene := _resolve_debug_mob_scene(current_scene, use_elite_scene)
		if mob_scene == null:
			return false
		var mob := mob_scene.instantiate() as Node2D
		if mob == null:
			return false
		mob.global_position = _get_debug_spawn_position(i)
		current_scene.add_child(mob)
		if current_scene.has_method("_on_mob_spawned"):
			current_scene.call("_on_mob_spawned", mob)

	return true


func _resolve_debug_mob_scene(current_scene: Node, use_elite_scene: bool) -> PackedScene:
	if not use_elite_scene:
		var common_scene := current_scene.get("common_mob_scene") as PackedScene
		if common_scene != null:
			return common_scene
		return load(DEBUG_COMMON_MOB_SCENE_PATH) as PackedScene

	var elite_lancer := current_scene.get("elite_lancer_scene") as PackedScene
	var elite_archer := current_scene.get("elite_archer_scene") as PackedScene
	if elite_lancer == null:
		elite_lancer = load(DEBUG_ELITE_LANCER_SCENE_PATH) as PackedScene
	if elite_archer == null:
		elite_archer = load(DEBUG_ELITE_ARCHER_SCENE_PATH) as PackedScene
	if elite_lancer != null and elite_archer != null:
		return elite_lancer if randf() < 0.5 else elite_archer
	return elite_lancer if elite_lancer != null else elite_archer


func _get_debug_spawn_position(index: int) -> Vector2:
	if _mob_spawner_ref != null and is_instance_valid(_mob_spawner_ref):
		return _mob_spawner_ref.get_random_spawn_position()

	var origin := _player_ref.global_position if _player_ref != null and is_instance_valid(_player_ref) else Vector2.ZERO
	var angle := randf() * TAU
	var radius := 180.0 + float(index) * 18.0
	return origin + Vector2.RIGHT.rotated(angle) * radius


func _refresh_hud_level_display() -> void:
	var hud := get_parent()
	if hud == null:
		var current_scene := get_tree().current_scene
		if current_scene != null:
			hud = current_scene.get_node_or_null("HUD")
	if hud != null and hud.has_method("refresh_player_level_display"):
		hud.call("refresh_player_level_display")
	if hud != null and hud.has_method("refresh_player_stat_cards"):
		hud.call("refresh_player_stat_cards")


func _ensure_debug_targets() -> void:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return

	if _player_ref == null or not is_instance_valid(_player_ref):
		var resolved_player := current_scene.get_node_or_null("Player") as CharacterBody2D
		if resolved_player != null:
			_player_ref = resolved_player
			_log("resolved player from scene path=%s" % [str(resolved_player.get_path())])
			if level_input != null:
				level_input.text = str(_sanitize_level(LevelSystem.get_level(_player_ref)))

	if _mob_spawner_ref == null or not is_instance_valid(_mob_spawner_ref):
		var resolved_spawner := current_scene.get_node_or_null("MobSpawner") as MobSpawner
		if resolved_spawner == null:
			resolved_spawner = current_scene.find_child("MobSpawner", true, false) as MobSpawner
		if resolved_spawner != null:
			_mob_spawner_ref = resolved_spawner
			_log("resolved spawner from scene path=%s" % [str(resolved_spawner.get_path())])


func _connect_debug_signals() -> void:
	if level_input != null:
		if not level_input.focus_entered.is_connected(_on_level_input_focus_entered):
			level_input.focus_entered.connect(_on_level_input_focus_entered)
		if not level_input.focus_exited.is_connected(_on_level_input_focus_exited):
			level_input.focus_exited.connect(_on_level_input_focus_exited)
		if not level_input.text_changed.is_connected(_on_level_input_text_changed):
			level_input.text_changed.connect(_on_level_input_text_changed)
		if not level_input.gui_input.is_connected(_on_level_input_gui_input):
			level_input.gui_input.connect(_on_level_input_gui_input)
	if spawn_count_input != null:
		if not spawn_count_input.focus_entered.is_connected(_on_spawn_count_focus_entered):
			spawn_count_input.focus_entered.connect(_on_spawn_count_focus_entered)
		if not spawn_count_input.focus_exited.is_connected(_on_spawn_count_focus_exited):
			spawn_count_input.focus_exited.connect(_on_spawn_count_focus_exited)
		if not spawn_count_input.text_changed.is_connected(_on_spawn_count_text_changed):
			spawn_count_input.text_changed.connect(_on_spawn_count_text_changed)
		if not spawn_count_input.gui_input.is_connected(_on_spawn_count_gui_input):
			spawn_count_input.gui_input.connect(_on_spawn_count_gui_input)
	if class_option != null and not class_option.item_selected.is_connected(_on_class_option_item_selected):
		class_option.item_selected.connect(_on_class_option_item_selected)
	if class_option != null and not class_option.gui_input.is_connected(_on_class_option_gui_input):
		class_option.gui_input.connect(_on_class_option_gui_input)
	if close_button != null and not close_button.gui_input.is_connected(_on_close_button_gui_input):
		close_button.gui_input.connect(_on_close_button_gui_input)
	if set_level_button != null and not set_level_button.gui_input.is_connected(_on_set_level_button_gui_input):
		set_level_button.gui_input.connect(_on_set_level_button_gui_input)
	if max_level_button != null and not max_level_button.gui_input.is_connected(_on_max_level_button_gui_input):
		max_level_button.gui_input.connect(_on_max_level_button_gui_input)
	if reset_level_button != null and not reset_level_button.gui_input.is_connected(_on_reset_level_button_gui_input):
		reset_level_button.gui_input.connect(_on_reset_level_button_gui_input)
	if add_coins_button != null and not add_coins_button.gui_input.is_connected(_on_add_coins_button_gui_input):
		add_coins_button.gui_input.connect(_on_add_coins_button_gui_input)
	if spawn_common_button != null and not spawn_common_button.gui_input.is_connected(_on_spawn_common_button_gui_input):
		spawn_common_button.gui_input.connect(_on_spawn_common_button_gui_input)
	if spawn_elite_button != null and not spawn_elite_button.gui_input.is_connected(_on_spawn_elite_button_gui_input):
		spawn_elite_button.gui_input.connect(_on_spawn_elite_button_gui_input)
	if apply_class_button != null and not apply_class_button.gui_input.is_connected(_on_apply_class_button_gui_input):
		apply_class_button.gui_input.connect(_on_apply_class_button_gui_input)


func _on_level_input_focus_entered() -> void:
	_log("level input focus entered")
	if level_input != null:
		level_input.select_all()


func _on_level_input_focus_exited() -> void:
	_log("level input focus exited")


func _on_level_input_text_changed(new_text: String) -> void:
	_log("level input text changed=%s" % new_text)


func _on_level_input_gui_input(event: InputEvent) -> void:
	_log_input("level input gui_input", event)


func _on_spawn_count_focus_entered() -> void:
	_log("spawn count focus entered")


func _on_spawn_count_focus_exited() -> void:
	_log("spawn count focus exited")


func _on_spawn_count_text_changed(new_text: String) -> void:
	_log("spawn count text changed=%s" % new_text)


func _on_spawn_count_gui_input(event: InputEvent) -> void:
	_log_input("spawn count gui_input", event)


func _on_class_option_item_selected(index: int) -> void:
	var selected_text := "<invalid>"
	if class_option != null and index >= 0:
		selected_text = class_option.get_item_text(index)
	_log("class option selected index=%d text=%s" % [index, selected_text])


func _on_class_option_gui_input(event: InputEvent) -> void:
	_log_input("class option gui_input", event)


func _on_close_button_gui_input(event: InputEvent) -> void:
	_log_input("close button gui_input", event)


func _on_set_level_button_gui_input(event: InputEvent) -> void:
	_log_input("set level button gui_input", event)


func _on_max_level_button_gui_input(event: InputEvent) -> void:
	_log_input("max level button gui_input", event)


func _on_reset_level_button_gui_input(event: InputEvent) -> void:
	_log_input("reset level button gui_input", event)


func _on_add_coins_button_gui_input(event: InputEvent) -> void:
	_log_input("add coins button gui_input", event)


func _on_spawn_common_button_gui_input(event: InputEvent) -> void:
	_log_input("spawn common button gui_input", event)


func _on_spawn_elite_button_gui_input(event: InputEvent) -> void:
	_log_input("spawn elite button gui_input", event)


func _on_apply_class_button_gui_input(event: InputEvent) -> void:
	_log_input("apply class button gui_input", event)


func _log(message: String) -> void:
	if DEBUG_LOGS:
		print("%s %s" % [DEBUG_LOG_PREFIX, message])


func _log_input(prefix: String, event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		_log("%s mouse_button index=%d pressed=%s position=%s" % [prefix, mouse_event.button_index, mouse_event.pressed, mouse_event.position])
	elif event is InputEventKey:
		var key_event := event as InputEventKey
		_log("%s key physical=%d pressed=%s echo=%s" % [prefix, key_event.physical_keycode, key_event.pressed, key_event.echo])
