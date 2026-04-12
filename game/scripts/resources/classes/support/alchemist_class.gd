class_name AlchemistClass extends PlayerClass

## Alchemist - Debuff specialist with potions and DoT
## Balanced stats with utility items

func _init():
	display_name = "Alchemist"
	description = "A master of potions and poisons. Alchemists debilitate enemies with various concoctions."
	lore = "Members of the Alchemist Guild, they seek to unlock the secrets of transmutation."
	
	# Player scene - Green slime for utility classes
	
	# Stat modifiers
	modifiers_hp = 0.95       # -5% HP
	modifiers_speed = 1.05    # +5% Speed
	modifiers_damage = 1.05   # +5% Damage
	modifiers_defense = 1.05  # +5% Defense
	modifiers_attack_speed = 1.0     # Normal Attack Speed
	
	# Passive bonuses
	passive_name = "Transmutation"
	passive_description = "Potions and consumables are 50% more effective. Gain 10% chance to apply Poison on hit."
	passive_gold_bonus = 10.0
	passive_xp_bonus = 10.0
	
	# Mana & Regen
	mana_bonus = 0          # Non-mana class
	mana_regen_bonus = 0.0
	hp_regen_bonus = 0.5    # +0.5 HP/s out of combat
