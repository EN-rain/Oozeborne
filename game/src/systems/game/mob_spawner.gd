extends Node
## MobSpawner - Handles spawning and management of mobs
## Encapsulates common and elite mob spawning logic

signal mob_spawned(mob: Node)
signal mob_died(mob: Node, score_value: int, xp_value: int)

@export var common_mob_scene: PackedScene
@export var elite_mob_lancer_scene: PackedScene
@export var elite_mob_archer_scene: PackedScene

@export var initial_common_mob_count: int = 0
@export var max_total_common_mob: int = 0
@export var initial_elite_mob_count: int = 0
@export var max_total_elite_mob: int = 0

@export var spawn_area_size: Vector2 = Vector2(800, 600)
@export var min_distance_from_player: float = 150.0

var current_common_mob_count := 0
var total_common_mob_spawned := 0

var current_elite_mob_count := 0
var total_elite_mob_spawned := 0

var _parent: Node
var _player: Node


func initialize(parent: Node, player: Node):
	_parent = parent
	_player = player


func spawn_initial_mobs():
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
	var pos := Vector2.ZERO
	var attempts := 0
	
	while attempts < 50:
		pos = Vector2(
			randf_range(-spawn_area_size.x / 2, spawn_area_size.x / 2),
			randf_range(-spawn_area_size.y / 2, spawn_area_size.y / 2)
		)
		
		# Check player is valid before accessing position
		if not is_instance_valid(_player):
			return pos
		
		if _player.global_position.distance_to(pos) >= min_distance_from_player:
			return pos
		
		attempts += 1
	
	return pos
