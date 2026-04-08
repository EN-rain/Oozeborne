extends StatusEffect
class_name WeaknessDebuff

## WeaknessDebuff - -30% damage dealt

@export var damage_reduction: float = 0.3  # 30% less damage dealt

var _original_damage_modifier: float = 1.0


func _init():
	effect_name = "weakness"
	duration = 10.0
	is_debuff = true
	popup_text = "Weakened"
	popup_color = Color(0.92, 0.55, 0.3, 1.0)


func _on_apply() -> void:
	if target == null:
		return
	
	if target.has_meta("damage_modifier"):
		_original_damage_modifier = target.get_meta("damage_modifier")
	else:
		_original_damage_modifier = 1.0
	
	target.set_meta("damage_modifier", _original_damage_modifier * (1.0 - damage_reduction))
	print("[WeaknessDebuff] Damage dealt -%.0f%%" % [damage_reduction * 100])


func _on_remove() -> void:
	if target == null:
		return
	
	target.set_meta("damage_modifier", _original_damage_modifier)
	print("[WeaknessDebuff] Damage restored")
