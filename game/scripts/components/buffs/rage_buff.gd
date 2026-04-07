extends StatusEffect
class_name RageBuff

## RageBuff - +25% critical hit chance

@export var crit_chance_increase: float = 0.25  # 25% more crit chance

var _original_crit_chance: float = 0.0


func _init():
	effect_name = "rage"
	duration = 15.0
	is_debuff = false


func _on_apply() -> void:
	if target == null:
		return
	
	if target.has_meta("crit_chance"):
		_original_crit_chance = target.get_meta("crit_chance")
	else:
		_original_crit_chance = 0.0
	
	target.set_meta("crit_chance", _original_crit_chance + crit_chance_increase)
	print("[RageBuff] Crit chance +%.0f%% (now %.0f%%)" % [crit_chance_increase * 100, target.get_meta("crit_chance") * 100])


func _on_remove() -> void:
	if target == null:
		return
	
	target.set_meta("crit_chance", _original_crit_chance)
	print("[RageBuff] Crit chance restored to %.0f%%" % [_original_crit_chance * 100])
