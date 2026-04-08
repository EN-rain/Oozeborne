extends StatusEffect
class_name SwiftnessBuff

## SwiftnessBuff - +30% movement speed

@export var speed_increase: float = 0.3  # 30% speed increase

var _original_speed: float = 0.0


func _init():
	effect_name = "swiftness"
	duration = 15.0
	is_debuff = false
	popup_text = "Swift"
	popup_color = Color(0.45, 1.0, 0.85, 1.0)


func _on_apply() -> void:
	if target == null:
		return
	
	if "speed" in target:
		_original_speed = target.speed
		target.speed = _original_speed * (1.0 + speed_increase)
		print("[SwiftnessBuff] Speed increased from %.1f to %.1f" % [_original_speed, target.speed])


func _on_remove() -> void:
	if target == null:
		return
	
	if "speed" in target and _original_speed > 0:
		target.speed = _original_speed
		print("[SwiftnessBuff] Speed restored to %.1f" % _original_speed)
