extends StatusEffect
class_name SkillTreePassiveEffect

@export var meta_target: String = ""
@export var magnitude: float = 0.0

var _applied_to: Node = null


func _init() -> void:
	effect_name = "skill_tree_passive"
	duration = INF
	is_debuff = false
	show_apply_popup = false


func set_magnitude(new_magnitude: float) -> void:
	magnitude = new_magnitude
	if _applied_to != null and is_instance_valid(_applied_to) and not meta_target.is_empty():
		_applied_to.set_meta(meta_target, magnitude)


func _on_apply() -> void:
	_applied_to = target
	if _applied_to != null and is_instance_valid(_applied_to) and not meta_target.is_empty():
		_applied_to.set_meta(meta_target, magnitude)


func _on_remove() -> void:
	if _applied_to != null and is_instance_valid(_applied_to) and not meta_target.is_empty():
		_applied_to.set_meta(meta_target, 0.0)
	_applied_to = null
