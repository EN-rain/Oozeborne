class_name ClericClass extends PlayerClass

## Cleric - Healer and buffer support class
## Good defense, lower damage, powerful healing

func _init():
	display_name = "Cleric"
	description = "A divine healer blessed by the gods. Clerics excel at keeping allies alive through powerful healing magic."
	lore = "Servants of the Divine Temple, Clerics channel holy energy to mend wounds and protect the faithful."
	
	# Player scene - Green slime for healing classes
	
	# Stat modifiers
	modifiers_hp = 1.1        # +10% HP
	modifiers_speed = 0.9     # -10% Speed
	modifiers_damage = 0.8    # -20% Damage
	modifiers_defense = 1.2   # +20% Defense
	modifiers_attack_speed = 0.85   # -15% Attack Speed
	
	# Passive bonuses
	passive_name = "Healing Aura"
	passive_description = "Nearby allies regenerate 2 HP per second. Self-healing is 50% more effective."
	passive_lifesteal = 10.0
	
	# Mana & Regen
	mana_bonus = 30         # +30 MP (holy healer)
	mana_regen_bonus = 1.0  # +1.0 MP/s
	hp_regen_bonus = 0.5    # +0.5 HP/s out of combat
