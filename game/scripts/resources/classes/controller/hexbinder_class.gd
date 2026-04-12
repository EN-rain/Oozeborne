class_name HexbinderClass extends PlayerClass

## Hexbinder - Curse controller focused on debuff pressure
## Fragile utility subclass with high spell amplification

func _init():
	display_name = "Hexbinder"
	description = "Curse specialist that weakens enemies and amplifies team burst."
	lore = "Hexbinders use layered curses to choke enemy output and punish overcommitment."
	
	# Player scene - Purple slime for curse casters
	
	# Class identity - controller is a subclass
	is_main_class = false
	is_subclass = true

	# Stat modifiers
	modifiers_hp = 0.92        # -8% HP
	modifiers_speed = 1.02     # +2% Speed
	modifiers_damage = 1.15    # +15% Damage
	modifiers_defense = 0.9    # -10% Defense
	modifiers_attack_speed = 1.06   # +6% Attack Speed

	# Passive bonuses
	passive_name = "Malice Chain"
	passive_description = "Defeated cursed enemies spread a weaker curse to nearby targets."
	passive_thorns_damage = 6.0
	
	# Mana & Regen
	mana_bonus = 15         # +15 MP (curse magic)
	mana_regen_bonus = 0.5  # +0.5 MP/s
	hp_regen_bonus = 0.0
