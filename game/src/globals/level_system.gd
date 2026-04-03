extends Node

## LevelSystem - Singleton that manages player XP, level ups, and stat application
## Add to AutoLoad as "LevelSystem"

signal xp_gained(entity_id: int, amount: int, total: int)
signal level_up(entity_id: int, new_level: int, stats: Dictionary)
signal stats_updated(entity_id: int, stats: Dictionary)

@export var player_stats: PlayerStats  # Resource defining stat scaling

# Dictionary: entity_id -> { level, xp, xp_to_next, player_ref }
var player_data: Dictionary = {}


func _ready():
	if player_stats == null:
		player_stats = PlayerStats.new()  # Use defaults


## Register a player with the level system
func register_player(player: Node, starting_level: int = 1) -> void:
	var entity_id = player.get_instance_id()
	
	player_data[entity_id] = {
		"level": starting_level,
		"xp": 0,
		"xp_to_next": player_stats.get_xp_for_level(starting_level + 1),
		"player_ref": player
	}
	
	_apply_current_stats(entity_id)
	print("[LevelSystem] Registered player %d at level %d" % [entity_id, starting_level])


## Unregister a player (call when player is freed)
func unregister_player(player: Node) -> void:
	var entity_id = player.get_instance_id()
	if player_data.has(entity_id):
		player_data.erase(entity_id)
		print("[LevelSystem] Unregistered player %d" % entity_id)


## Add XP to a player
func add_xp(player: Node, amount: int) -> void:
	if amount <= 0:
		return
	
	var entity_id = player.get_instance_id()
	if not player_data.has(entity_id):
		return
	
	var data = player_data[entity_id]
	data.xp += amount
	xp_gained.emit(entity_id, amount, data.xp)
	
	# Check for multiple level ups
	while data.xp >= data.xp_to_next:
		_level_up(entity_id)


## Add XP from killing a mob
func add_xp_from_kill(player: Node, mob_xp_value: int) -> void:
	add_xp(player, mob_xp_value)


## Get player's current level
func get_level(player: Node) -> int:
	var entity_id = player.get_instance_id()
	if not player_data.has(entity_id):
		return 1
	return player_data[entity_id].level


## Get player's current XP
func get_xp(player: Node) -> int:
	var entity_id = player.get_instance_id()
	if not player_data.has(entity_id):
		return 0
	return player_data[entity_id].xp


## Get XP progress (0.0 to 1.0)
func get_xp_progress(player: Node) -> float:
	var entity_id = player.get_instance_id()
	if not player_data.has(entity_id):
		return 0.0
	
	var data = player_data[entity_id]
	if data.xp_to_next <= 0:
		return 1.0
	return float(data.xp) / float(data.xp_to_next)


## Get current stats for a player
func get_current_stats(player: Node) -> Dictionary:
	var entity_id = player.get_instance_id()
	if not player_data.has(entity_id):
		return {}
	return player_stats.get_stats_at_level(player_data[entity_id].level)


## Force set level (for testing or saves)
func set_level(player: Node, level: int) -> void:
	var entity_id = player.get_instance_id()
	if not player_data.has(entity_id):
		return
	
	player_data[entity_id].level = max(1, level)
	player_data[entity_id].xp = 0
	player_data[entity_id].xp_to_next = player_stats.get_xp_for_level(level + 1)
	_apply_current_stats(entity_id)


## Internal: Handle level up
func _level_up(entity_id: int) -> void:
	if not player_data.has(entity_id):
		return
	
	var data = player_data[entity_id]
	data.xp -= data.xp_to_next
	data.level += 1
	data.xp_to_next = player_stats.get_xp_for_level(data.level + 1)
	
	var new_stats = player_stats.get_stats_at_level(data.level)
	level_up.emit(entity_id, data.level, new_stats)
	_apply_current_stats(entity_id)
	
	print("[LevelSystem] Player %d leveled up to %d!" % [entity_id, data.level])


## Internal: Apply current level stats to player
func _apply_current_stats(entity_id: int) -> void:
	if not player_data.has(entity_id):
		return
	
	var data = player_data[entity_id]
	var player = data.player_ref
	
	if not is_instance_valid(player) or player_stats == null:
		return
	
	var stats = player_stats.get_stats_at_level(data.level)
	
	# Apply speed
	if "speed" in player:
		player.speed = stats.speed
	
	# Apply dash stats
	if "dash_speed" in player:
		player.dash_speed = stats.dash_speed
	if "dash_cooldown" in player:
		player.dash_cooldown = stats.dash_cooldown
	
	# Apply health (update max health in health component)
	if player.has_node("Health"):
		var health_comp = player.get_node("Health")
		health_comp.max_health = stats.max_health
		# Heal to full on level up, or keep current health ratio
		var health_ratio = health_comp.current_health / float(health_comp.max_health) if health_comp.max_health > 0 else 1.0
		health_comp.current_health = int(stats.max_health * health_ratio)
		health_comp.health_changed.emit(health_comp.current_health, health_comp.max_health)
	
	# Store attack damage for use by attack system
	if "attack_damage" not in player:
		player.set_meta("attack_damage", stats.attack_damage)
	else:
		player.attack_damage = stats.attack_damage
	
	stats_updated.emit(entity_id, stats)
