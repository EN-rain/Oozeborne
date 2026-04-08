extends Node

## DamageNumberManager - Singleton for spawning damage numbers
## Add to AutoLoad as "DamageNumbers"

@export var damage_number_scene: PackedScene

# Colors for different damage types
const COLOR_NORMAL := Color.WHITE
const COLOR_CRIT := Color(1.0, 0.85, 0.2)  # Gold
const COLOR_HEAL := Color(0.3, 1.0, 0.5)   # Green
const COLOR_PLAYER_DAMAGE := Color(1.0, 0.3, 0.3)  # Red for player taking damage
const COLOR_ENEMY_DAMAGE := Color(1.0, 1.0, 1.0)  # White for enemy damage
const DUPLICATE_WINDOW_MS := 90
const DUPLICATE_POSITION_TOLERANCE := 10.0

var _recent_spawns: Dictionary = {}


func spawn_damage(at_position: Vector2, damage: int, is_crit: bool = false, is_player: bool = false) -> void:
	if _is_duplicate_spawn(at_position, str(damage), is_crit, is_player):
		return

	var instance = _create_damage_number_instance()
	if instance == null:
		return
	var host := _get_damage_number_host()
	if host == null:
		return
	host.add_child(instance)
	instance.position = _world_to_screen(at_position)
	
	var color = COLOR_PLAYER_DAMAGE if is_player else COLOR_ENEMY_DAMAGE
	instance.setup(damage, is_crit, color)


func spawn_heal(at_position: Vector2, amount: int) -> void:
	if _is_duplicate_spawn(at_position, "heal_%d" % amount, false, false):
		return

	var instance = _create_damage_number_instance()
	if instance == null:
		return
	var host := _get_damage_number_host()
	if host == null:
		return
	host.add_child(instance)
	instance.position = _world_to_screen(at_position)
	instance.setup(-amount, false, COLOR_HEAL)  # Negative = heal


func spawn_custom(at_position: Vector2, text: String, color: Color = Color.WHITE, font_size: int = 20) -> void:
	if _is_duplicate_spawn(at_position, text, false, false):
		return

	var instance = _create_damage_number_instance()
	if instance == null:
		return
	var host := _get_damage_number_host()
	if host == null:
		return
	host.add_child(instance)
	instance.position = _world_to_screen(at_position)

	if instance.has_method("setup_custom"):
		instance.setup_custom(text, color, font_size)


func _create_damage_number_instance() -> Node:
	if damage_number_scene == null:
		push_error("[DamageNumbers] damage_number_scene is not assigned.")
		return null
	return damage_number_scene.instantiate()


func _get_damage_number_host() -> Node:
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return null

	var hud := tree.current_scene.get_node_or_null("HUD")
	if hud != null:
		return hud
	return tree.current_scene


func _world_to_screen(world_position: Vector2) -> Vector2:
	var viewport := get_viewport()
	if viewport == null:
		return world_position
	return viewport.get_canvas_transform() * world_position


func _is_duplicate_spawn(at_position: Vector2, payload: String, is_crit: bool, is_player: bool) -> bool:
	var now_ms := Time.get_ticks_msec()
	var rounded_x := int(round(at_position.x / DUPLICATE_POSITION_TOLERANCE))
	var rounded_y := int(round(at_position.y / DUPLICATE_POSITION_TOLERANCE))
	var key := "%s|%s|%s|%d|%d" % [payload, is_crit, is_player, rounded_x, rounded_y]

	var previous_ms: int = int(_recent_spawns.get(key, -1000000))
	_recent_spawns[key] = now_ms

	var expired_keys: Array[String] = []
	for recent_key in _recent_spawns.keys():
		if now_ms - int(_recent_spawns[recent_key]) > DUPLICATE_WINDOW_MS:
			expired_keys.append(recent_key)
	for expired_key in expired_keys:
		_recent_spawns.erase(expired_key)

	return now_ms - previous_ms <= DUPLICATE_WINDOW_MS
