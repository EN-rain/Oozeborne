extends StatusEffect
class_name IronSkinBuff

## IronSkinBuff - +50% damage reduction

@export var damage_reduction: float = 0.5  # 50% less damage taken

var _original_defense_modifier: float = 1.0


func _init():
	effect_name = "iron_skin"
	duration = 12.0
	is_debuff = false
	popup_text = "Iron Skin"
	popup_color = Color(0.62, 0.8, 0.95, 1.0)


func _on_apply() -> void:
	if target == null:
		return
	
	# Reduce damage taken by increasing defense
	if target.has_meta("defense_modifier"):
		_original_defense_modifier = target.get_meta("defense_modifier")
	else:
		_original_defense_modifier = 1.0
	
	# Defense modifier reduces incoming damage (higher = less damage)
	target.set_meta("defense_modifier", _original_defense_modifier + damage_reduction)
	print("[IronSkinBuff] Damage reduction +%.0f%%" % [damage_reduction * 100])


func _on_remove() -> void:
	if target == null:
		return
	
	target.set_meta("defense_modifier", _original_defense_modifier)
	print("[IronSkinBuff] Defense restored")
