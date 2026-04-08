extends StatusEffect
class_name BlindDebuff

## BlindDebuff - Reduced visibility (for UI/effects to handle)

@export var visibility_reduction: float = 0.5  # 50% visibility reduction


func _init():
	effect_name = "blind"
	duration = 6.0
	is_debuff = true
	popup_text = "Blinded"
	popup_color = Color(0.72, 0.72, 0.85, 1.0)


func _on_apply() -> void:
	if target == null:
		return
	
	target.set_meta("blind", true)
	target.set_meta("visibility_reduction", visibility_reduction)
	print("[BlindDebuff] Visibility reduced by %.0f%% for %.1fs" % [visibility_reduction * 100, duration])


func _on_remove() -> void:
	if target == null:
		return
	
	if target.has_meta("blind"):
		target.remove_meta("blind")
	if target.has_meta("visibility_reduction"):
		target.remove_meta("visibility_reduction")
	print("[BlindDebuff] Visibility restored")
