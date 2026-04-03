class_name BerserkerClass extends PlayerClass

## Berserker - Aggressive tank that deals more damage when low on HP
## Balanced HP, high damage, low defense

func _init():
	display_name = "Berserker"
	description = "A fury-driven warrior who grows stronger as their blood flows. The lower your HP, the higher your damage."
	lore = "Born from the frozen north, Berserkers embrace the rage within to devastate their foes."
	
	# Stat modifiers
	modifiers_hp = 1.25       # +25% HP
	modifiers_speed = 0.9     # -10% Speed
	modifiers_damage = 1.4    # +40% Damage
	modifiers_defense = 0.7   # -30% Defense
	modifiers_attack_speed = 1.2   # +20% Attack Speed
	
	# Special ability
	ability_name = "Blood Rage"
	ability_description = "Enter a frenzy for 6 seconds. Gain +50% attack speed and +30% damage, but take 20% more damage."
	ability_cooldown = 20.0
	ability_duration = 6.0
	
	# Passive bonuses
	passive_name = "Adrenaline"
	passive_description = "Deal up to 50% more damage based on missing HP. At 1 HP, deal maximum bonus damage."
	passive_lifesteal = 5.0   # 5% lifesteal
