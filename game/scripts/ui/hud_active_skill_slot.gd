extends PanelContainer
class_name HudActiveSkillSlot

@onready var icon: TextureRect = %Icon
@onready var hotkey_label: Label = %Hotkey
@onready var cooldown_label: Label = %Cooldown


func set_slot_index(slot_index: int) -> void:
	var label := _get_hotkey_label()
	if label != null:
		label.text = str(slot_index + 1)


func set_empty() -> void:
	var icon_node := _get_icon()
	if icon_node != null:
		icon_node.texture = null
		icon_node.modulate = Color(1, 1, 1, 0.18)

	var cooldown_node := _get_cooldown_label()
	if cooldown_node != null:
		cooldown_node.visible = false
		cooldown_node.text = ""


func set_skill_icon(texture: Texture2D) -> void:
	var icon_node := _get_icon()
	if icon_node != null:
		icon_node.texture = texture
		icon_node.modulate = Color.WHITE


func set_cooldown(cooldown_remaining: float) -> bool:
	var is_active := cooldown_remaining > 0.0
	var cooldown_node := _get_cooldown_label()
	if cooldown_node != null:
		cooldown_node.visible = is_active
		cooldown_node.text = "%.1f" % cooldown_remaining if is_active else ""
	return is_active


func _get_icon() -> TextureRect:
	if icon == null:
		icon = get_node_or_null("%Icon") as TextureRect
	return icon


func _get_hotkey_label() -> Label:
	if hotkey_label == null:
		hotkey_label = get_node_or_null("%Hotkey") as Label
	return hotkey_label


func _get_cooldown_label() -> Label:
	if cooldown_label == null:
		cooldown_label = get_node_or_null("%Cooldown") as Label
	return cooldown_label
