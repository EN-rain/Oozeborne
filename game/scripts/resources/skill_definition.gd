class_name SkillDefinition
extends Resource

enum SkillType {
	STAT,
	ABILITY,
	PASSIVE,
	SPECIAL,
}

@export var skill_id: String = ""
@export var display_name: String = ""
@export var skill_type: SkillType = SkillType.STAT
@export_range(1, 10, 1) var max_level: int = 5
@export_range(1, 10, 1) var sp_cost_per_level: int = 1
@export_multiline var description_template: String = ""
@export var value_per_level: Variant = 0
@export var icon: Texture2D


func get_description(level: int) -> String:
	var resolved_level := clampi(level, 0, max_level)
	var description := description_template
	description = description.replace("{level}", str(resolved_level))
	description = description.replace("{max_level}", str(max_level))
	description = description.replace("{value}", _stringify_value(get_value(resolved_level)))
	return description


func get_value(level: int) -> Variant:
	var resolved_level := clampi(level, 0, max_level)
	if value_per_level is Array:
		var entries: Array = value_per_level
		if entries.is_empty():
			return null
		return entries[min(resolved_level, entries.size() - 1)]
	if value_per_level is Dictionary:
		var source: Dictionary = value_per_level
		if source.has("base") and source.has("per_level"):
			return _combine_numeric(source.get("base"), source.get("per_level"), resolved_level)
		if source.has(str(resolved_level)):
			return source.get(str(resolved_level))
		return source
	if value_per_level is int or value_per_level is float:
		return _combine_numeric(0, value_per_level, resolved_level)
	return value_per_level


func _combine_numeric(base_value: Variant, per_level_value: Variant, level: int) -> Variant:
	if (base_value is int or base_value is float) and (per_level_value is int or per_level_value is float):
		return base_value + (per_level_value * level)
	return per_level_value


func _stringify_value(value: Variant) -> String:
	if value == null:
		return ""
	if value is String:
		return value
	if value is float:
		return str(snapped(value, 0.001))
	return str(value)
