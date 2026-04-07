extends StatusEffect
class_name PoisonDebuff

## PoisonDebuff - Damage over time

@export var damage_per_second: int = 3
@export var tick_interval: float = 1.0

var _tick_timer: float = 0.0


func _init():
	effect_name = "poison"
	duration = 6.0
	is_debuff = true


func _on_apply() -> void:
	print("[PoisonDebuff] Dealing %d damage/sec for %.1fs" % [damage_per_second, duration])


func _on_tick(delta: float) -> void:
	if target == null:
		return
	
	_tick_timer += delta
	if _tick_timer >= tick_interval:
		_tick_timer = 0.0
		_damage_target()


func _damage_target() -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage_per_second)
	elif target.has_node("Health") and target.get_node("Health").has_method("take_damage"):
		target.get_node("Health").take_damage(damage_per_second)
	elif "health" in target and target.health.has_method("take_damage"):
		target.health.take_damage(damage_per_second)
