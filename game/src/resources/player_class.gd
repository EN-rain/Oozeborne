class_name PlayerClass extends Resource

## PlayerClass - Base resource defining a player class
## Each class modifies base stats and provides unique abilities

@export_group("Class Info")
@export var display_name: String = "Adventurer"
@export var description: String = "A balanced fighter with no specializations."
@export_multiline var lore: String = ""
@export var icon: Texture2D
@export var is_main_class: bool = true
@export var is_subclass: bool = false

@export_group("Stat Modifiers", "modifiers")
@export_range(0.5, 2.0) var modifiers_hp: float = 1.0
@export_range(0.5, 2.0) var modifiers_speed: float = 1.0
@export_range(0.5, 2.0) var modifiers_damage: float = 1.0
@export_range(0.5, 2.0) var modifiers_defense: float = 1.0
@export_range(0.5, 2.0) var modifiers_attack_speed: float = 1.0
@export_range(0.5, 2.0) var modifiers_crit_chance: float = 1.0
@export_range(0.5, 2.0) var modifiers_crit_damage: float = 1.0

@export_group("Special Ability", "ability")
@export var ability_name: String = ""
@export_multiline var ability_description: String = ""
@export var ability_cooldown: float = 10.0
@export var ability_duration: float = 5.0

@export_group("Passive Bonuses", "passive")
@export var passive_name: String = ""
@export_multiline var passive_description: String = ""
@export var passive_lifesteal: float = 0.0
@export var passive_dodge_chance: float = 0.0
@export var passive_thorns_damage: float = 0.0
@export var passive_xp_bonus: float = 0.0
@export var passive_gold_bonus: float = 0.0

@export_group("Player Scene", "player")
@export var player_scene: PackedScene  ## The player scene to instantiate for this class (slime variant)

@export_group("Starting Bonuses", "starting")
@export var starting_level: int = 1
@export var starting_xp_bonus: int = 0
@export var starting_items: Array[String] = []


## Get modified stat value
func get_modified_hp(base_hp: int) -> int:
	return int(base_hp * modifiers_hp)


func get_modified_speed(base_speed: float) -> float:
	return base_speed * modifiers_speed


func get_modified_damage(base_damage: int) -> int:
	return int(base_damage * modifiers_damage)


func get_modified_defense(base_defense: int) -> int:
	return int(base_defense * modifiers_defense)


## Get class display name with modifiers summary
func get_stats_summary() -> String:
	var summary = display_name + ":\n"
	
	if modifiers_hp != 1.0:
		summary += "  HP: %+.0f%s\n" % [(modifiers_hp - 1.0) * 100, "%"]
	if modifiers_speed != 1.0:
		summary += "  Speed: %+.0f%s\n" % [(modifiers_speed - 1.0) * 100, "%"]
	if modifiers_damage != 1.0:
		summary += "  Damage: %+.0f%s\n" % [(modifiers_damage - 1.0) * 100, "%"]
	if modifiers_defense != 1.0:
		summary += "  Defense: %+.0f%s\n" % [(modifiers_defense - 1.0) * 100, "%"]
	if modifiers_attack_speed != 1.0:
		summary += "  Attack Speed: %+.0f%s\n" % [(modifiers_attack_speed - 1.0) * 100, "%"]
	if modifiers_crit_chance != 1.0:
		summary += "  Crit Chance: %+.0f%s\n" % [(modifiers_crit_chance - 1.0) * 100, "%"]
	
	return summary
