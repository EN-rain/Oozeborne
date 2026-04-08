extends StatusEffect
class_name BleedDebuff

## BleedDebuff - Damage over time + blocks healing

@export var damage_per_second: int = 2
@export var tick_interval: float = 1.0

var _tick_timer: float = 0.0


func _init():
	effect_name = "bleed"
	duration = 8.0
	is_debuff = true
	popup_text = "Bleeding"
	popup_color = Color(0.95, 0.28, 0.28, 1.0)


func _on_apply() -> void:
	if target == null:
		return
	
	# Block healing while bleeding
	target.set_meta("healing_blocked", true)
	print("[BleedDebuff] Dealing %d damage/sec, healing blocked for %.1fs" % [damage_per_second, duration])


func _on_tick(delta: float) -> void:
	if target == null:
		return
	
	_tick_timer += delta
	if _tick_timer >= tick_interval:
		_tick_timer = 0.0
		_damage_target()


func _on_remove() -> void:
	if target == null:
		return
	
	if target.has_meta("healing_blocked"):
		target.remove_meta("healing_blocked")
	print("[BleedDebuff] Healing unblocked")


func _damage_target() -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage_per_second)
	elif target.has_node("Health") and target.get_node("Health").has_method("take_damage"):
		target.get_node("Health").take_damage(damage_per_second)
	elif "health" in target and target.health.has_method("take_damage"):
		target.health.take_damage(damage_per_second)
