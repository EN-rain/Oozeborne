class_name RangerClass extends PlayerClass

## Ranger - Ranged specialist with traps and mobility
## Balanced stats with ranged advantage

func _init():
	display_name = "Ranger"
	description = "One with nature. Rangers excel at ranged combat, laying traps and striking from a distance."
	lore = "Guardians of the wilderness, Rangers have sworn to protect the forests from those who would harm them."
	
	# Player scene - Green slime for nature classes
	
	# Stat modifiers
	modifiers_hp = 0.9        # -10% HP
	modifiers_speed = 1.2     # +20% Speed
	modifiers_damage = 1.2    # +20% Damage
	modifiers_defense = 0.9   # -10% Defense
	modifiers_attack_speed = 1.15   # +15% Attack Speed
	
	# Special ability
	ability_name = "Trap Network"
	ability_description = "Place 3 traps that trigger when enemies walk over them, dealing 50 damage and slowing for 3 seconds."
	ability_cooldown = 12.0
	ability_duration = 30.0   # Traps last 30 seconds
	
	# Passive bonuses
	passive_name = "Hunter's Mark"
	passive_description = "Marked enemies take 15% more damage from all sources and reveal their position."
	passive_xp_bonus = 15.0   # +15% XP from kills
