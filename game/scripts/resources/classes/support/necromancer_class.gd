class_name NecromancerClass extends PlayerClass

## Necromancer - Dark support caster with life drain and battlefield pressure
## Sustained magic damage, fragile defenses, strong soul-harvest utility

func _init():
	display_name = "Necromancer"
	description = "A forbidden spellcaster who weaponizes decay, soul siphoning, and restless dead to control the battlefield."
	lore = "Banished from sacred academies, Necromancers learned to bargain with death itself and turn lost souls into power."

	# Player scene - Purple slime for dark magic classes
	
	# Stat modifiers
	modifiers_hp = 0.85       # -15% HP
	modifiers_speed = 0.95    # -5% Speed
	modifiers_damage = 1.22   # +22% Damage
	modifiers_defense = 0.8   # -20% Defense
	modifiers_attack_speed = 1.0
	modifiers_crit_chance = 1.08  # +8% Crit Chance
	modifiers_crit_damage = 1.15  # +15% Crit Damage

	# Passive bonuses
	passive_name = "Soul Harvest"
	passive_description = "Defeated enemies restore a small amount of health and briefly amplify your spell damage."
	passive_lifesteal = 14.0
	
	# Mana & Regen
	mana_bonus = 20         # +20 MP (dark caster)
	mana_regen_bonus = 0.5  # +0.5 MP/s
	hp_regen_bonus = 0.0
