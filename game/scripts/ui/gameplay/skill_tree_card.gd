extends Button
class_name SkillTreeCard

@export var locked_style: StyleBoxFlat
@export var maxed_style: StyleBoxFlat
@export var selected_style: StyleBoxFlat
@export var learned_style: StyleBoxFlat
@export var default_style: StyleBoxFlat

@onready var indicator: ColorRect = %Indicator
@onready var title_label: Label = %TitleLabel
@onready var level_label: Label = %LevelLabel
@onready var type_label: Label = %TypeLabel
@onready var role_label: Label = %RoleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var state_label: Label = %StateLabel

var skill_id: String = ""
var tree_key: String = ""


func _ensure_ui_refs() -> void:
	if indicator == null:
		indicator = get_node_or_null("%Indicator")
	if title_label == null:
		title_label = get_node_or_null("%TitleLabel")
	if level_label == null:
		level_label = get_node_or_null("%LevelLabel")
	if type_label == null:
		type_label = get_node_or_null("%TypeLabel")
	if role_label == null:
		role_label = get_node_or_null("%RoleLabel")
	if description_label == null:
		description_label = get_node_or_null("%DescriptionLabel")
	if state_label == null:
		state_label = get_node_or_null("%StateLabel")


func configure(skill_definition: Resource, next_tree_key: String, role_text: String = "") -> void:
	if skill_definition == null:
		return
	_ensure_ui_refs()
	skill_id = str(skill_definition.skill_id)
	tree_key = next_tree_key
	if title_label != null:
		title_label.text = str(skill_definition.display_name)
	if indicator != null:
		indicator.color = SkillTreeUI.TYPE_COLORS.get(int(skill_definition.skill_type), Color.WHITE)
	if type_label != null:
		type_label.text = SkillTreeUI.skill_type_to_text(int(skill_definition.skill_type))
	if role_label != null:
		role_label.text = role_text


func refresh_display(description: String, state_text: String, level: int, max_level: int, unlocked: bool, is_maxed: bool, is_selected: bool) -> void:
	_ensure_ui_refs()
	if level_label != null:
		level_label.text = "%d / %d" % [level, max_level]
	if description_label != null:
		description_label.text = description
	if state_label != null:
		state_label.text = state_text
	disabled = not unlocked
	text = ""

	var style: StyleBoxFlat = default_style
	if not unlocked:
		style = locked_style
	elif is_maxed:
		style = maxed_style
	elif is_selected:
		style = selected_style
	elif level > 0:
		style = learned_style

	if style != null:
		add_theme_stylebox_override("normal", style)
		add_theme_stylebox_override("hover", style)
		add_theme_stylebox_override("pressed", style)
		add_theme_stylebox_override("disabled", style)
