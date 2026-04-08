extends Node
class_name RoundManager

## RoundManager - Centralized round progression and enemy stat scaling.
## Tracks active mobs, advances rounds over time, and reapplies scaling to all tracked enemies.

signal round_changed(new_round: int, profile: Dictionary)
signal mob_scaled(mob: Node, profile: Dictionary)

@export var starting_round: int = 1
@export var health_growth_per_round: float = 0.12
@export var damage_growth_per_round: float = 0.08
@export var speed_growth_per_round: float = 0.02
@export var xp_growth_per_round: float = 0.08

var current_round: int = 1

var _tracked_mobs: Array[Node] = []


func _ready() -> void:
	current_round = max(1, starting_round)


func set_round(new_round: int) -> void:
	var clamped_round: int = int(max(1, new_round))
	if clamped_round == current_round:
		return

	current_round = clamped_round
	var profile := get_round_profile()
	_apply_to_tracked_mobs()
	round_changed.emit(current_round, profile)


func get_round_profile(round_number: int = current_round) -> Dictionary:
	var round_offset: int = int(max(round_number - 1, 0))
	return {
		"round": round_number,
		"mob_level": round_number,
		"health_growth_pct": int(round(health_growth_per_round * 100.0)),
		"damage_growth_pct": int(round(damage_growth_per_round * 100.0)),
		"speed_growth_pct": int(round(speed_growth_per_round * 100.0)),
		"xp_growth_pct": int(round(xp_growth_per_round * 100.0)),
		"health_multiplier": pow(1.0 + health_growth_per_round, round_offset),
		"damage_multiplier": pow(1.0 + damage_growth_per_round, round_offset),
		"speed_multiplier": pow(1.0 + speed_growth_per_round, round_offset),
		"xp_multiplier": pow(1.0 + xp_growth_per_round, round_offset),
	}


func register_mob(mob: Node) -> void:
	if not is_instance_valid(mob) or _tracked_mobs.has(mob):
		return

	_capture_base_stats(mob)
	_tracked_mobs.append(mob)
	mob.tree_exiting.connect(_on_tracked_mob_exiting.bind(mob))
	apply_to_mob(mob)


func unregister_mob(mob: Node) -> void:
	var index := _tracked_mobs.find(mob)
	if index != -1:
		_tracked_mobs.remove_at(index)


func apply_to_mob(mob: Node) -> void:
	if not is_instance_valid(mob):
		return

	var base_stats: Dictionary = mob.get_meta("round_manager_base_stats", {})
	if base_stats.is_empty():
		_capture_base_stats(mob)
		base_stats = mob.get_meta("round_manager_base_stats", {})
		if base_stats.is_empty():
			return

	var profile := get_round_profile()
	var health_multiplier: float = profile["health_multiplier"]
	var damage_multiplier: float = profile["damage_multiplier"]
	var speed_multiplier: float = profile["speed_multiplier"]
	var xp_multiplier: float = profile["xp_multiplier"]

	if base_stats.has("max_health") and "max_health" in mob:
		mob.max_health = max(1, int(round(base_stats["max_health"] * health_multiplier)))
	if base_stats.has("contact_damage") and "contact_damage" in mob:
		mob.contact_damage = max(1, int(round(base_stats["contact_damage"] * damage_multiplier)))
	if base_stats.has("speed") and "speed" in mob:
		mob.speed = float(base_stats["speed"]) * speed_multiplier
	if base_stats.has("xp_value") and "xp_value" in mob:
		mob.xp_value = max(1, int(round(base_stats["xp_value"] * xp_multiplier)))

	_apply_health_scaling(mob)
	_sync_enemy_runtime_state(mob)
	mob.set_meta("mob_level", profile["mob_level"])
	mob.set_meta("round_profile", profile)
	mob_scaled.emit(mob, profile)


func register_existing_mobs(root: Node) -> void:
	if not is_instance_valid(root):
		return

	for child: Node in root.get_children():
		if _looks_like_enemy(child):
			register_mob(child)
		register_existing_mobs(child)


func _apply_to_tracked_mobs() -> void:
	for mob in _tracked_mobs.duplicate():
		if not is_instance_valid(mob):
			unregister_mob(mob)
			continue
		apply_to_mob(mob)


func _capture_base_stats(mob: Node) -> void:
	var base_stats := {}
	if "max_health" in mob:
		base_stats["max_health"] = mob.max_health
	if "contact_damage" in mob:
		base_stats["contact_damage"] = mob.contact_damage
	if "speed" in mob:
		base_stats["speed"] = mob.speed
	if "xp_value" in mob:
		base_stats["xp_value"] = mob.xp_value

	if not base_stats.is_empty():
		mob.set_meta("round_manager_base_stats", base_stats)


func _apply_health_scaling(mob: Node) -> void:
	var health_component = _get_health_component(mob)
	if health_component == null:
		return
	if health_component.is_dead:
		return

	var previous_max: int = int(max(1, int(health_component.max_health)))
	var current_health := int(health_component.current_health)
	var health_ratio := float(current_health) / float(previous_max)

	health_component.max_health = max(1, int(mob.max_health if "max_health" in mob else previous_max))
	health_component.current_health = max(1, int(round(health_component.max_health * health_ratio)))
	if current_health >= previous_max:
		health_component.current_health = health_component.max_health

	if health_component.health_bar:
		health_component.health_bar.max_value = health_component.max_health
		health_component.health_bar.value = health_component.current_health
	health_component.health_changed.emit(health_component.current_health, health_component.max_health)


func _sync_enemy_runtime_state(mob: Node) -> void:
	if "damage_timer" in mob and mob.damage_timer != null and "damage_cooldown" in mob:
		mob.damage_timer.wait_time = mob.damage_cooldown

	if "blink_cooldown_timer" in mob and mob.blink_cooldown_timer != null and "blink_cooldown" in mob:
		mob.blink_cooldown_timer.wait_time = mob.blink_cooldown

	if "bt_player" in mob and mob.bt_player != null:
		mob.bt_player.blackboard.set_var("speed", mob.speed if "speed" in mob else 0.0)
		mob.bt_player.blackboard.set_var("contact_damage", mob.contact_damage if "contact_damage" in mob else 0)
		mob.bt_player.blackboard.set_var("stop_distance", mob.stop_distance if "stop_distance" in mob else 0.0)
		mob.bt_player.blackboard.set_var("knockback_force", mob.knockback_force if "knockback_force" in mob else 0.0)
		mob.bt_player.blackboard.set_var("attack_distance", mob.attack_distance if "attack_distance" in mob else 0.0)
		mob.bt_player.blackboard.set_var("arrow_speed", mob.arrow_speed if "arrow_speed" in mob else 0.0)
		mob.bt_player.blackboard.set_var("teleport_distance", mob.teleport_distance if "teleport_distance" in mob else 0.0)
		mob.bt_player.blackboard.set_var("blink_cooldown", mob.blink_cooldown if "blink_cooldown" in mob else 0.0)


func _get_health_component(mob: Node) -> HealthComponent:
	if "health" in mob and mob.health != null:
		return mob.health as HealthComponent

	for child: Node in mob.get_children():
		if child is HealthComponent:
			return child as HealthComponent

	return null


func _looks_like_enemy(node: Node) -> bool:
	return "max_health" in node and ("contact_damage" in node or "xp_value" in node)


func _on_tracked_mob_exiting(mob: Node) -> void:
	unregister_mob(mob)
