extends StatusEffect
class_name SlowDebuff

## SlowDebuff - Reduces movement speed by percentage

@export var slow_percentage: float = 0.4  # 40% slow

var original_speed: float = 0.0


func _init():
	effect_name = "slow"
	duration = 5.0
	is_debuff = true


func _on_apply() -> void:
	if target == null:
		return
	
	# Store original speed
	if "speed" in target:
		original_speed = target.speed
		target.speed = original_speed * (1.0 - slow_percentage)
		print("[SlowDebuff] Speed reduced from %.1f to %.1f" % [original_speed, target.speed])


func _on_remove() -> void:
	if target == null:
		return
	
	# Restore original speed
	if "speed" in target and original_speed > 0:
		target.speed = original_speed
		print("[SlowDebuff] Speed restored to %.1f" % original_speed)
