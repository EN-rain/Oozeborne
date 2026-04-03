extends StatusEffect
class_name CurseDebuff

## CurseDebuff - Cannot use abilities (dash, special attacks, etc.)

var _original_can_dash: bool = true


func _init():
	effect_name = "curse"
	duration = 5.0
	is_debuff = true


func _on_apply() -> void:
	if target == null:
		return
	
	# Disable abilities
	target.set_meta("abilities_blocked", true)
	
	# Specifically disable dash if available
	if "can_dash" in target:
		_original_can_dash = target.can_dash
		target.can_dash = false
	
	print("[CurseDebuff] Abilities blocked for %.1fs" % duration)


func _on_remove() -> void:
	if target == null:
		return
	
	if target.has_meta("abilities_blocked"):
		target.remove_meta("abilities_blocked")
	
	if "can_dash" in target:
		target.can_dash = _original_can_dash
	
	print("[CurseDebuff] Abilities unblocked")
