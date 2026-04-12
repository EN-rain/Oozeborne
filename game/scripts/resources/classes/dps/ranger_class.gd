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
	modifiers_crit_chance = 1.10    # +10% Crit Chance
	modifiers_crit_damage = 1.15    # +15% Crit Damage
	
	# Mana & Regen
	mana_bonus = 0          # Non-mana class
	mana_regen_bonus = 0.0
	hp_regen_bonus = 0.0
