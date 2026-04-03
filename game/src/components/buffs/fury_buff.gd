extends StatusEffect
class_name FuryBuff

## FuryBuff - +40% attack speed

@export var attack_speed_increase: float = 0.4  # 40% faster attacks

var _original_attack_speed: float = 1.0


func _init():
	effect_name = "fury"
	duration = 10.0
	is_debuff = false


func _on_apply() -> void:
	if target == null:
		return
	
	if target.has_meta("attack_speed"):
		_original_attack_speed = target.get_meta("attack_speed")
	else:
		_original_attack_speed = 1.0
	
	# Higher attack speed = faster attacks
	target.set_meta("attack_speed", _original_attack_speed * (1.0 + attack_speed_increase))
	print("[FuryBuff] Attack speed +%.0f%%" % [attack_speed_increase * 100])


func _on_remove() -> void:
	if target == null:
		return
	
	target.set_meta("attack_speed", _original_attack_speed)
	print("[FuryBuff] Attack speed restored")
