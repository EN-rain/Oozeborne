extends Node
class_name MobSpawner
## MobSpawner - Handles spawning and management of mobs
## Encapsulates common and elite mob spawning logic

signal mob_spawned(mob: Node)
signal mob_died(mob: Node, score_value: int, xp_value: int)

@export var common_mob_scene: PackedScene
@export var elite_mob_lancer_scene: PackedScene
@export var elite_mob_archer_scene: PackedScene

@export var initial_common_mob_count: int = 5
@export var max_total_common_mob: int = 5
@export var initial_elite_mob_count: int = 5
@export var max_total_elite_mob: int = 15

@export var spawn_area_size: Vector2 = Vector2(800, 600)
@export var min_distance_from_player: float = 150.0
@export var offscreen_margin: float = 8.0
@export var offscreen_spawn_band: float = 24.0

var current_common_mob_count := 0
var total_common_mob_spawned := 0

var current_elite_mob_count := 0
var total_elite_mob_spawned := 0

var _parent: Node
var _player: Node
var _round_manager: RoundManager
var _has_spawned_initial_mobs := false


func initialize(parent: Node, player: Node):
	_parent = parent
	_player = player


func set_round_manager(round_manager: RoundManager) -> void:
	_round_manager = round_manager


func spawn_initial_mobs():
	if _has_spawned_initial_mobs:
		return
	_has_spawned_initial_mobs = true
	spawn_initial_common_mobs()
	spawn_initial_elite_mobs()


func spawn_initial_common_mobs():
	for i in range(initial_common_mob_count):
		spawn_common_mob()


func spawn_common_mob():
	if total_common_mob_spawned >= max_total_common_mob:
		return
	
	if common_mob_scene == null:
		return
	
	var mob = common_mob_scene.instantiate()
	mob.global_position = get_random_spawn_position()
	mob.tree_exiting.connect(_on_common_mob_died.bind(mob))
	
	_parent.add_child(mob)
	if _round_manager != null:
		_round_manager.register_mob(mob)
	mob_spawned.emit(mob)
	
	current_common_mob_count += 1
	total_common_mob_spawned += 1


func _on_common_mob_died(_mob):
	current_common_mob_count -= 1
	var xp = _mob.xp_value if _mob.has_method("get") or "xp_value" in _mob else 10
	mob_died.emit(_mob, 1, xp)
	
	if total_common_mob_spawned < max_total_common_mob:
		await _parent.get_tree().create_timer(0.5).timeout
		spawn_common_mob()


func spawn_initial_elite_mobs():
	for i in range(initial_elite_mob_count):
		spawn_elite_mob()


func spawn_elite_mob():
	if total_elite_mob_spawned >= max_total_elite_mob:
		return
	
	if elite_mob_lancer_scene == null or elite_mob_archer_scene == null:
		return
	
	var elite_scene = elite_mob_lancer_scene if randf() < 0.5 else elite_mob_archer_scene
	
	var elite = elite_scene.instantiate()
	elite.global_position = get_random_spawn_position()
	elite.tree_exiting.connect(_on_elite_mob_died.bind(elite))
	
	_parent.add_child(elite)
	if _round_manager != null:
		_round_manager.register_mob(elite)
	mob_spawned.emit(elite)
	
	current_elite_mob_count += 1
	total_elite_mob_spawned += 1


func _on_elite_mob_died(_elite):
	current_elite_mob_count -= 1
	var xp = _elite.xp_value if _elite.has_method("get") or "xp_value" in _elite else 25
	mob_died.emit(_elite, 5, xp)
	
	if total_elite_mob_spawned < max_total_elite_mob:
		await _parent.get_tree().create_timer(1.0).timeout
		spawn_elite_mob()


func get_random_spawn_position() -> Vector2:
	if not is_instance_valid(_player):
		return Vector2.ZERO
	return _get_forced_offscreen_spawn_position()


func _is_outside_visible_area(world_pos: Vector2) -> bool:
	var camera := _player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return true

	var half_visible := _get_half_visible_world_size(camera)
	if half_visible == Vector2.ZERO:
		return true

	var player_pos: Vector2 = _player.global_position
	return abs(world_pos.x - player_pos.x) > half_visible.x or abs(world_pos.y - player_pos.y) > half_visible.y


func _get_forced_offscreen_spawn_position() -> Vector2:
	if not is_instance_valid(_player):
		return Vector2.ZERO

	var camera := _player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return _player.global_position + Vector2(min_distance_from_player + offscreen_margin, 0)

	var half_visible := _get_half_visible_world_size(camera)
	if half_visible == Vector2.ZERO:
		return _player.global_position + Vector2(min_distance_from_player + offscreen_margin, 0)
	var spawn_from_horizontal_edge := randf() < 0.5
	var offset := Vector2.ZERO

	if spawn_from_horizontal_edge:
		offset.x = randf_range(half_visible.x, half_visible.x + offscreen_spawn_band)
		offset.x *= -1 if randf() < 0.5 else 1
		offset.y = randf_range(-half_visible.y * 0.45, half_visible.y * 0.45)
	else:
		offset.y = randf_range(half_visible.y, half_visible.y + offscreen_spawn_band)
		offset.y *= -1 if randf() < 0.5 else 1
		offset.x = randf_range(-half_visible.x * 0.45, half_visible.x * 0.45)

	if offset.length() < min_distance_from_player:
		offset = offset.normalized() * min_distance_from_player

	return _player.global_position + offset


func _get_half_visible_world_size(camera: Camera2D) -> Vector2:
	var viewport_size := camera.get_viewport().get_visible_rect().size if camera.get_viewport() != null else Vector2.ZERO
	if viewport_size == Vector2.ZERO:
		return Vector2.ZERO

	var zoom := camera.zoom
	var safe_zoom := Vector2(
		maxf(absf(zoom.x), 0.001),
		maxf(absf(zoom.y), 0.001)
	)
	return Vector2(
		viewport_size.x * 0.5 / safe_zoom.x + offscreen_margin,
		viewport_size.y * 0.5 / safe_zoom.y + offscreen_margin
	)
