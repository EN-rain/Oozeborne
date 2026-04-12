extends Resource
class_name PlayerStats

## PlayerStats - Defines base stats and scaling per level
## Used by LevelSystem to calculate stats at any level

# --- Base Stats (Level 1) ---
@export var base_max_health: int = 100
@export var base_speed: float = 100.0
@export var base_dash_speed: float = 400.0
@export var base_dash_cooldown: float = 3.0
@export var base_attack_damage: int = 25
@export var base_crit_chance: float = 0.05
@export var base_crit_damage: float = 1.10
@export var base_max_mana: int = 0  # 0 = non-mana class; 100 = mana class base
@export var base_mana_regen: float = 3.0  # MP/s in combat
@export var base_hp_regen: float = 0.0  # HP/s out of combat

# --- Per-Level Scaling ---
@export var health_per_level: int = 10
@export var speed_per_level: float = 2.0
@export var dash_speed_per_level: float = 5.0
@export var dash_cooldown_reduction: float = 0.02  # Reduces cooldown per level
@export var damage_per_level: int = 3
@export var crit_chance_per_level: float = 0.0005
@export var crit_damage_per_level: float = 0.001
@export var mana_per_level: int = 5  # +MP per level (mana classes only)
@export var mana_regen_per_level: float = 0.1  # +MP/s per level
@export var hp_regen_per_level: float = 0.5  # +HP/s per level

# --- Min/Max Caps ---
@export var min_dash_cooldown: float = 1.0
@export var max_speed: float = 200.0
@export var max_dash_speed: float = 600.0
@export var max_crit_chance: float = 0.10
@export var max_crit_damage: float = 1.20
@export var max_mana_regen: float = 10.0
@export var max_hp_regen: float = 5.0

# --- XP Curve ---
@export var base_xp_requirement: int = 100
@export var xp_scaling: float = 1.5  # Multiplier per level


## Calculate XP required to reach a specific level
func get_xp_for_level(level: int) -> int:
	if level <= 1:
		return 0
	# Formula: base * (scaling ^ (level - 1))
	return int(base_xp_requirement * pow(xp_scaling, level - 1))


## Calculate total XP required from level 1 to target level
func get_total_xp_for_level(level: int) -> int:
	var total := 0
	for l in range(2, level + 1):
		total += get_xp_for_level(l)
	return total


## Get max health at a specific level
func get_max_health(level: int) -> int:
	return base_max_health + (health_per_level * (level - 1))


## Get movement speed at a specific level
func get_speed(level: int) -> float:
	return minf(base_speed + (speed_per_level * (level - 1)), max_speed)


## Get dash speed at a specific level
func get_dash_speed(level: int) -> float:
	return minf(base_dash_speed + (dash_speed_per_level * (level - 1)), max_dash_speed)


## Get dash cooldown at a specific level (decreases with level)
func get_dash_cooldown(level: int) -> float:
	var cooldown := base_dash_cooldown - (dash_cooldown_reduction * (level - 1))
	return maxf(cooldown, min_dash_cooldown)


## Get attack damage at a specific level
func get_attack_damage(level: int) -> int:
	return base_attack_damage + (damage_per_level * (level - 1))


## Get critical hit chance at a specific level
func get_crit_chance(level: int) -> float:
	return minf(base_crit_chance + (crit_chance_per_level * (level - 1)), max_crit_chance)


## Get critical hit damage multiplier at a specific level
func get_crit_damage(level: int) -> float:
	return minf(base_crit_damage + (crit_damage_per_level * (level - 1)), max_crit_damage)


## Get max mana at a specific level (0 for non-mana classes)
func get_max_mana(level: int) -> int:
	return base_max_mana + (mana_per_level * (level - 1))


## Get mana regen rate at a specific level (MP/s in combat)
func get_mana_regen(level: int) -> float:
	return minf(base_mana_regen + (mana_regen_per_level * (level - 1)), max_mana_regen)


## Get HP regen rate at a specific level (HP/s out of combat)
func get_hp_regen(level: int) -> float:
	return minf(base_hp_regen + (hp_regen_per_level * (level - 1)), max_hp_regen)


## Get all stats for a level as a dictionary
func get_stats_at_level(level: int) -> Dictionary:
	return {
		"max_health": get_max_health(level),
		"speed": get_speed(level),
		"dash_speed": get_dash_speed(level),
		"dash_cooldown": get_dash_cooldown(level),
		"attack_damage": get_attack_damage(level),
		"crit_chance": get_crit_chance(level),
		"crit_damage": get_crit_damage(level),
		"max_mana": get_max_mana(level),
		"mana_regen": get_mana_regen(level),
		"hp_regen": get_hp_regen(level),
		"xp_to_next": get_xp_for_level(level + 1)
	}
