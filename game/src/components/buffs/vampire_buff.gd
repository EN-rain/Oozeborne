extends StatusEffect
class_name VampireBuff

## VampireBuff - Lifesteal on damage dealt

@export var lifesteal_percentage: float = 0.2  # 20% of damage healed

var _original_lifesteal: float = 0.0


func _init():
	effect_name = "vampire"
	duration = 12.0
	is_debuff = false


func _on_apply() -> void:
	if target == null:
		return
	
	if target.has_meta("lifesteal"):
		_original_lifesteal = target.get_meta("lifesteal")
	else:
		_original_lifesteal = 0.0
	
	target.set_meta("lifesteal", _original_lifesteal + lifesteal_percentage)
	print("[VampireBuff] Lifesteal +%.0f%%" % [lifesteal_percentage * 100])


func _on_remove() -> void:
	if target == null:
		return
	
	target.set_meta("lifesteal", _original_lifesteal)
	print("[VampireBuff] Lifesteal restored to %.0f%%" % [_original_lifesteal * 100])
