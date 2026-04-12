class_name ShadowKnightClass extends PlayerClass

## Shadow Knight - Dark tank with lifesteal and sacrifice mechanics
## High HP, good damage, dark abilities

func _init():
	display_name = "Shadow Knight"
	description = "A fallen warrior who has embraced the darkness. Shadow Knights sacrifice their own HP to fuel devastating attacks."
	lore = "Once noble paladins, Shadow Knights made a pact with darkness to gain power at a terrible price."
	
	# Player scene - Purple slime for dark knight classes
	
	# Class identity - hybrid is a subclass
	is_main_class = false
	is_subclass = true
	
	# Stat modifiers
	modifiers_hp = 1.15       # +15% HP
	modifiers_speed = 1.05    # +5% Speed
	modifiers_damage = 1.1    # +10% Damage
	modifiers_defense = 0.98  # -2% Defense
	modifiers_attack_speed = 1.0     # Normal Attack Speed
	
	# Mana & Regen
	mana_bonus = 0          # Non-mana class
	mana_regen_bonus = 0.0
	hp_regen_bonus = 1.0    # +1.0 HP/s out of combat
