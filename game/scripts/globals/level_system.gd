extends Node

signal xp_gained(entity_id: int, amount: int, total: int)
signal level_up(entity_id: int, new_level: int, stats: Dictionary)
signal stats_updated(entity_id: int, stats: Dictionary)

@export var player_stats: PlayerStats

var player_data: Dictionary = {}


func _ready() -> void:
	if player_stats == null:
		player_stats = PlayerStats.new()


func register_player(player: Node, starting_level: int = 1) -> void:
	if player == null or not is_instance_valid(player):
		return
	var entity_id := player.get_instance_id()
	player_data[entity_id] = {
		"level": max(1, starting_level),
		"xp": 0,
		"xp_to_next": player_stats.get_xp_for_level(max(1, starting_level) + 1),
		"player_ref": player,
	}
	_apply_current_stats(entity_id)


func unregister_player(player: Node) -> void:
	if player == null:
		return
	var entity_id := player.get_instance_id()
	if player_data.has(entity_id):
		player_data.erase(entity_id)


func has_player(player: Node) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	return player_data.has(player.get_instance_id())


func reset_run_state() -> void:
	player_data.clear()
	if get_tree() != null and get_tree().root != null and get_tree().root.has_node("SkillTreeManager"):
		var skill_tree_manager := get_tree().root.get_node("SkillTreeManager")
		if skill_tree_manager != null:
			skill_tree_manager.call("reset_run_state")


func add_xp(player: Node, amount: int) -> void:
	if amount <= 0 or player == null or not is_instance_valid(player):
		return
	var entity_id := player.get_instance_id()
	if not player_data.has(entity_id):
		return
	var data: Dictionary = player_data[entity_id]
	data.xp += amount
	xp_gained.emit(entity_id, amount, data.xp)
	while data.xp >= data.xp_to_next:
		_level_up(entity_id)


func add_xp_from_kill(player: Node, mob_xp_value: int) -> void:
	add_xp(player, mob_xp_value)


func get_level(player: Node) -> int:
	if player == null or not is_instance_valid(player):
		return 1
	var entity_id := player.get_instance_id()
	if not player_data.has(entity_id):
		return 1
	return int(player_data[entity_id].level)


func get_xp(player: Node) -> int:
	if player == null or not is_instance_valid(player):
		return 0
	var entity_id := player.get_instance_id()
	if not player_data.has(entity_id):
		return 0
	return int(player_data[entity_id].xp)


func get_xp_progress(player: Node) -> float:
	if player == null or not is_instance_valid(player):
		return 0.0
	var entity_id := player.get_instance_id()
	if not player_data.has(entity_id):
		return 0.0
	var data: Dictionary = player_data[entity_id]
	if int(data.xp_to_next) <= 0:
		return 1.0
	return float(data.xp) / float(data.xp_to_next)


func get_current_stats(player: Node) -> Dictionary:
	if player == null or not is_instance_valid(player):
		return {}
	var entity_id := player.get_instance_id()
	if not player_data.has(entity_id):
		return {}
	return player_stats.get_stats_at_level(int(player_data[entity_id].level))


func get_player_state(player: Node) -> Dictionary:
	if player == null or not is_instance_valid(player):
		return {}
	var entity_id := player.get_instance_id()
	if not player_data.has(entity_id):
		return {}
	return {
		"level": int(player_data[entity_id].level),
		"xp": int(player_data[entity_id].xp),
	}


func load_player_state(player: Node, state: Dictionary) -> void:
	if player == null or not is_instance_valid(player):
		return
	if not has_player(player):
		register_player(player, int(state.get("level", 1)))
	var entity_id := player.get_instance_id()
	player_data[entity_id].level = maxi(1, int(state.get("level", 1)))
	player_data[entity_id].xp = max(0, int(state.get("xp", 0)))
	player_data[entity_id].xp_to_next = player_stats.get_xp_for_level(int(player_data[entity_id].level) + 1)
	_apply_current_stats(entity_id)
	level_up.emit(entity_id, int(player_data[entity_id].level), player_stats.get_stats_at_level(int(player_data[entity_id].level)))


func set_level(player: Node, level: int) -> void:
	if player == null or not is_instance_valid(player):
		return
	if not has_player(player):
		register_player(player, maxi(1, level))
	var entity_id := player.get_instance_id()
	var resolved_level: int = maxi(1, level)
	player_data[entity_id].level = resolved_level
	player_data[entity_id].xp = 0
	player_data[entity_id].xp_to_next = player_stats.get_xp_for_level(resolved_level + 1)
	_apply_current_stats(entity_id)
	level_up.emit(entity_id, resolved_level, player_stats.get_stats_at_level(resolved_level))


func _level_up(entity_id: int) -> void:
	if not player_data.has(entity_id):
		return
	var data: Dictionary = player_data[entity_id]
	data.xp -= data.xp_to_next
	data.level += 1
	data.xp_to_next = player_stats.get_xp_for_level(int(data.level) + 1)
	var new_stats: Dictionary = player_stats.get_stats_at_level(int(data.level))
	level_up.emit(entity_id, int(data.level), new_stats)
	_apply_current_stats(entity_id)


func _apply_current_stats(entity_id: int) -> void:
	if not player_data.has(entity_id):
		return
	var data: Dictionary = player_data[entity_id]
	var player: Node = data.player_ref
	if not is_instance_valid(player) or player_stats == null:
		return
	var stats: Dictionary = player_stats.get_stats_at_level(int(data.level))
	if "speed" in player:
		player.speed = stats.speed
	if "dash_speed" in player:
		player.dash_speed = stats.dash_speed
	if "dash_cooldown" in player:
		player.dash_cooldown = stats.dash_cooldown
	if player.has_node("Health"):
		var health_comp = player.get_node("Health")
		var previous_max_health: int = max(int(health_comp.max_health), 1)
		var previous_health_ratio: float = float(health_comp.current_health) / float(previous_max_health)
		health_comp.max_health = stats.max_health
		health_comp.current_health = int(stats.max_health * clampf(previous_health_ratio, 0.0, 1.0))
		health_comp.health_changed.emit(health_comp.current_health, health_comp.max_health)
	if "attack_damage" not in player:
		player.set_meta("attack_damage", stats.attack_damage)
	else:
		player.attack_damage = stats.attack_damage
	if player.has_method("reapply_class_modifiers_after_level_sync"):
		player.reapply_class_modifiers_after_level_sync(stats)
	stats_updated.emit(entity_id, stats)
