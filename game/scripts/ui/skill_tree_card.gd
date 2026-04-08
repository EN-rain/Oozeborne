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
@onready var description_label: Label = %DescriptionLabel
@onready var state_label: Label = %StateLabel
@onready var invest_button: Button = %InvestButton

var skill_id: String = ""
var tree_key: String = ""


func configure(skill_definition: Resource, next_tree_key: String) -> void:
	if skill_definition == null:
		return
	skill_id = str(skill_definition.skill_id)
	tree_key = next_tree_key
	title_label.text = str(skill_definition.display_name)
	indicator.color = SkillTreeUI.TYPE_COLORS.get(int(skill_definition.skill_type), Color.WHITE)


func refresh_display(description: String, state_text: String, level: int, max_level: int, unlocked: bool, is_maxed: bool, is_selected: bool, can_invest: bool) -> void:
	level_label.text = "%d / %d" % [level, max_level]
	description_label.text = description
	state_label.text = state_text
	invest_button.disabled = not can_invest
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
