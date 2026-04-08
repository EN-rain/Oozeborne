extends StatusEffect
class_name RegenerationBuff

## RegenerationBuff - Heal over time

@export var heal_per_second: int = 5
@export var tick_interval: float = 1.0

var _tick_timer: float = 0.0


func _init():
	effect_name = "regeneration"
	duration = 8.0
	is_debuff = false
	popup_text = "Regenerating"
	popup_color = Color(0.35, 1.0, 0.55, 1.0)


func _on_apply() -> void:
	print("[RegenerationBuff] Healing %d HP/sec for %.1fs" % [heal_per_second, duration])


func _on_tick(delta: float) -> void:
	if target == null:
		return
	
	_tick_timer += delta
	if _tick_timer >= tick_interval:
		_tick_timer = 0.0
		_heal_target()


func _heal_target() -> void:
	if target.has_method("heal"):
		target.heal(heal_per_second)
	elif target.has_node("Health") and target.get_node("Health").has_method("heal"):
		target.get_node("Health").heal(heal_per_second)
	elif "health" in target and target.health.has_method("heal"):
		target.health.heal(heal_per_second)
