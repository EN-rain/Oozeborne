class_name TankRoleClass extends PlayerClass

## Tank - Main frontline class focused on durability and control
## High survivability with lower damage tempo

func _init():
	display_name = "Tank"
	description = "Frontline main class focused on survivability and control."
	lore = "Tanks anchor the front line, absorbing pressure and creating space for allies to operate safely."
	
	# Class identity - tank is a main class
	is_main_class = true
	is_subclass = false
	
	# Player scene - Blue slime for defensive archetype
	
	# Stat modifiers
	modifiers_hp = 1.25       # +25% HP
	modifiers_speed = 0.95    # -5% Speed
	modifiers_damage = 0.95   # -5% Damage
	modifiers_defense = 1.25  # +25% Defense
	modifiers_attack_speed = 0.95   # -5% Attack Speed
	modifiers_crit_chance = 1.02    # +2% Crit Chance
	modifiers_crit_damage = 1.05    # +5% Crit Damage
	
	# Mana & Regen
	mana_bonus = 0          # Non-mana class
	mana_regen_bonus = 0.0
	hp_regen_bonus = 1.0    # +1 HP/s out of combat
