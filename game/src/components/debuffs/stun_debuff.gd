extends StatusEffect
class_name StunDebuff

## StunDebuff - Cannot move or attack

var _original_can_move: bool = true


func _init():
	effect_name = "stun"
	duration = 1.5
	is_debuff = true


func _on_apply() -> void:
	if target == null:
		return
	
	# Disable movement
	if "can_move" in target:
		_original_can_move = target.can_move
		target.can_move = false
	
	# Disable velocity
	if "velocity" in target:
		target.velocity = Vector2.ZERO
	
	print("[StunDebuff] Stunned for %.1fs" % duration)


func _on_remove() -> void:
	if target == null:
		return
	
	if "can_move" in target:
		target.can_move = _original_can_move
	
	print("[StunDebuff] Stun ended")
