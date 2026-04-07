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
	
	# Special ability
	ability_name = "Fortify"
	ability_description = "Gain damage reduction and taunt nearby enemies for a short duration."
	ability_cooldown = 14.0
	ability_duration = 4.0
	
	# Passive bonuses
	passive_name = "Unbreakable"
	passive_description = "Reduce incoming damage while above 50% HP."
