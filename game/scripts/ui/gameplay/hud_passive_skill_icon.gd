extends PanelContainer
class_name HudPassiveSkillIcon

@export var passive_style: StyleBoxFlat
@export var stat_style: StyleBoxFlat

@onready var icon: TextureRect = %Icon


func _ensure_ui_refs() -> void:
	if icon == null:
		icon = get_node_or_null("%Icon")


func configure(skill_definition: Resource, texture: Texture2D, skill_id: String) -> void:
	_ensure_ui_refs()
	if skill_definition != null:
		tooltip_text = str(skill_definition.display_name)
	else:
		tooltip_text = skill_id

	if icon != null:
		icon.texture = texture

	if skill_definition != null and int(skill_definition.skill_type) == int(SkillDefinition.SkillType.STAT):
		add_theme_stylebox_override("panel", stat_style)
	else:
		add_theme_stylebox_override("panel", passive_style)
