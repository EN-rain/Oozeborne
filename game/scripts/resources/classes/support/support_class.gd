class_name SupportRoleClass extends PlayerClass

## Support - Main utility class with sustain and team enablement
## Strong defense and tempo control, lower raw damage

func _init():
	display_name = "Support"
	description = "Utility main class that amplifies sustain and team control."
	lore = "Support classes stabilize fights through sustain, utility, and careful tempo management."
	
	# Class identity - support is a main class
	is_main_class = true
	is_subclass = false
	
	# Player scene - Green slime for support classes
	
	# Stat modifiers
	modifiers_hp = 1.05       # +5% HP
	modifiers_speed = 1.0     # Base Speed
	modifiers_damage = 0.9    # -10% Damage
	modifiers_defense = 1.05  # +5% Defense
	modifiers_attack_speed = 1.0     # Base Attack Speed
	modifiers_crit_chance = 1.03     # +3% Crit Chance
	modifiers_crit_damage = 1.05     # +5% Crit Damage
	
	# Passive bonuses
	passive_name = "Steady Hands"
	passive_description = "Improves sustain effects and cooldown rhythm."
	
	# Mana & Regen
	mana_bonus = 0          # Non-mana class
	mana_regen_bonus = 0.0
	hp_regen_bonus = 0.5    # +0.5 HP/s out of combat
