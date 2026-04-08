extends StatusEffect
class_name ShieldBuff

## ShieldBuff - Absorbs fixed amount of damage

@export var shield_amount: int = 50  # Absorbs 50 damage

var _remaining_shield: int = 0


func _init():
	effect_name = "shield"
	duration = 30.0  # Lasts until broken or timeout
	is_debuff = false
	popup_text = "Shielded"
	popup_color = Color(0.4, 0.9, 1.0, 1.0)


func _on_apply() -> void:
	if target == null:
		return
	
	_remaining_shield = shield_amount
	
	# Add shield to target
	if target.has_meta("shield"):
		_remaining_shield = target.get_meta("shield") + shield_amount
	
	target.set_meta("shield", _remaining_shield)
	print("[ShieldBuff] Shield applied: %d HP" % _remaining_shield)


func _on_remove() -> void:
	if target == null:
		return
	
	if target.has_meta("shield"):
		target.remove_meta("shield")
	print("[ShieldBuff] Shield removed")


## Call this when target takes damage to absorb
func absorb_damage(amount: int) -> int:
	if _remaining_shield <= 0:
		return amount
	
	var absorbed = min(amount, _remaining_shield)
	_remaining_shield -= absorbed
	
	if target and target.has_meta("shield"):
		target.set_meta("shield", _remaining_shield)
	
	print("[ShieldBuff] Absorbed %d damage, %d remaining" % [absorbed, _remaining_shield])
	
	if _remaining_shield <= 0:
		remove()
	
	return amount - absorbed
