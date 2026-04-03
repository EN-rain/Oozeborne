extends StatusEffect
class_name BerserkBuff

## BerserkBuff - +50% damage, -25% defense

@export var damage_increase: float = 0.5  # 50% more damage
@export var defense_reduction: float = 0.25  # 25% less defense

var _original_damage_modifier: float = 1.0
var _original_defense_modifier: float = 1.0


func _init():
	effect_name = "berserk"
	duration = 10.0
	is_debuff = false


func _on_apply() -> void:
	if target == null:
		return
	
	# Store and modify damage
	if target.has_meta("damage_modifier"):
		_original_damage_modifier = target.get_meta("damage_modifier")
	else:
		_original_damage_modifier = 1.0
	target.set_meta("damage_modifier", _original_damage_modifier * (1.0 + damage_increase))
	
	# Store and modify defense
	if target.has_meta("defense_modifier"):
		_original_defense_modifier = target.get_meta("defense_modifier")
	else:
		_original_defense_modifier = 1.0
	target.set_meta("defense_modifier", _original_defense_modifier * (1.0 - defense_reduction))
	
	print("[BerserkBuff] Damage +%.0f%%, Defense -%.0f%%" % [damage_increase * 100, defense_reduction * 100])


func _on_remove() -> void:
	if target == null:
		return
	
	target.set_meta("damage_modifier", _original_damage_modifier)
	target.set_meta("defense_modifier", _original_defense_modifier)
	print("[BerserkBuff] Modifiers restored")
