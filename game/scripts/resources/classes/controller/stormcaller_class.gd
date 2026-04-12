class_name StormcallerClass extends PlayerClass

## Stormcaller - Aggressive controller with knockback and chain shocks
## Mobile subclass with sustained control pressure

func _init():
	display_name = "Stormcaller"
	description = "Aggressive controller that displaces enemies with chained lightning bursts."
	lore = "Stormcallers command volatile fronts that scatter formations and punish clustering."
	
	# Player scene - Teal slime for lightning archetype
	
	# Class identity - controller is a subclass
	is_main_class = false
	is_subclass = true

	# Stat modifiers
	modifiers_hp = 0.96        # -4% HP
	modifiers_speed = 1.12     # +12% Speed
	modifiers_damage = 1.12    # +12% Damage
	modifiers_defense = 0.92   # -8% Defense
	modifiers_attack_speed = 1.1    # +10% Attack Speed

	# Passive bonuses
	passive_name = "Static Build"
	passive_thorns_damage = 7.0
	
	# Mana & Regen
	mana_bonus = 20         # +20 MP (lightning magic)
	mana_regen_bonus = 0.5  # +0.5 MP/s
	hp_regen_bonus = 0.0
	passive_description = "Repeated hits on controlled targets increase your lightning damage."
