extends Control
class_name ClassSelectionUI

## ClassSelectionUI - UI for selecting player class before game start
## Subclass option unlocks at level 10

signal class_selected(player_class: PlayerClass, is_subclass: bool)

@onready var class_grid: GridContainer = $VBox/ClassGrid
@onready var class_info_panel: PanelContainer = $VBox/HBox/ClassInfo
@onready var class_name_label: Label = $VBox/HBox/ClassInfo/ScrollContainer/VBox/ClassNameLabel
@onready var class_desc_label: Label = $VBox/HBox/ClassInfo/ScrollContainer/VBox/ClassDescLabel
@onready var stats_label: Label = $VBox/HBox/ClassInfo/ScrollContainer/VBox/StatsLabel
@onready var ability_label: Label = $VBox/HBox/ClassInfo/ScrollContainer/VBox/AbilityLabel
@onready var passive_label: Label = $VBox/HBox/ClassInfo/ScrollContainer/VBox/PassiveLabel
@onready var select_button: Button = $VBox/HBox/ActionColumn/SelectButton
@onready var subclass_check: CheckBox = $VBox/HBox/ActionColumn/SubclassCheck
@onready var subclass_hint: Label = $VBox/SubclassHintBar/SubclassHint

var available_classes: Array[PlayerClass] = []
var selected_class: PlayerClass = null
var is_subclass_selected: bool = false
var player_level: int = 1

# Category tabs
var current_category: String = "all"
var category_buttons: Dictionary = {}
var _active_class_button: Button = null

# Category accent colors (pixel-art jewel tones)
const CATEGORY_COLORS = {
	"all": Color(0.9, 0.75, 0.3, 0.9),
	"tank": Color(0.3, 0.55, 0.8, 1.0),
	"dps": Color(0.8, 0.3, 0.25, 1.0),
	"support": Color(0.25, 0.7, 0.4, 1.0),
	"hybrid": Color(0.55, 0.35, 0.75, 1.0),
}

# Category icons (RPG themed)
const CATEGORY_ICONS = {
	"all": "⬡",
	"tank": "🛡",
	"dps": "⚔",
	"support": "✚",
	"hybrid": "◈",
}

# Role color mapping for class card accents (pixel RPG palette)
const ROLE_COLORS = {
	"tank": Color(0.25, 0.5, 0.75, 1.0),
	"dps": Color(0.75, 0.25, 0.2, 1.0),
	"support": Color(0.2, 0.65, 0.35, 1.0),
	"hybrid": Color(0.5, 0.3, 0.7, 1.0),
}


func _ready():
	_load_available_classes()
	_setup_ui()
	_update_subclass_availability()


func _load_available_classes():
	# Load all class scripts
	var class_types = [
		preload("res://src/resources/classes/tank/guardian_class.gd"),
		preload("res://src/resources/classes/tank/berserker_class.gd"),
		preload("res://src/resources/classes/tank/paladin_class.gd"),
		preload("res://src/resources/classes/dps/assassin_class.gd"),
		preload("res://src/resources/classes/dps/ranger_class.gd"),
		preload("res://src/resources/classes/dps/mage_class.gd"),
		preload("res://src/resources/classes/dps/samurai_class.gd"),
		preload("res://src/resources/classes/support/cleric_class.gd"),
		preload("res://src/resources/classes/support/bard_class.gd"),
		preload("res://src/resources/classes/support/alchemist_class.gd"),
		preload("res://src/resources/classes/support/necromancer_class.gd"),
		preload("res://src/resources/classes/hybrid/spellblade_class.gd"),
		preload("res://src/resources/classes/hybrid/shadow_knight_class.gd"),
		preload("res://src/resources/classes/hybrid/monk_class.gd"),
	]
	
	for class_type in class_types:
		var instance = class_type.new()
		available_classes.append(instance)


func _setup_ui():
	# Create category tab bar
	var categories = ["all", "tank", "dps", "support", "hybrid"]
	var category_box = HBoxContainer.new()
	category_box.name = "CategoryBox"
	category_box.add_theme_constant_override("separation", 4)
	
	for cat in categories:
		var btn = Button.new()
		btn.text = CATEGORY_ICONS.get(cat, "") + "  " + cat.to_upper()
		btn.toggle_mode = true
		btn.button_group = _get_or_create_button_group()
		
		# Apply pixel-art category tab styles
		var cat_color = CATEGORY_COLORS.get(cat, Color(0.9, 0.75, 0.3))
		btn.add_theme_font_size_override("font_size", 11)
		btn.add_theme_color_override("font_color", cat_color * Color(1, 1, 1, 0.65))
		btn.add_theme_color_override("font_hover_color", cat_color)
		btn.add_theme_color_override("font_pressed_color", cat_color)
		
		# Pixel-art tab button style
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.08, 0.06, 0.14, 0.4)
		normal_style.border_width_bottom = 3
		normal_style.border_color = Color(0, 0, 0, 0)
		normal_style.corner_radius_top_left = 4
		normal_style.corner_radius_top_right = 4
		normal_style.content_margin_left = 12
		normal_style.content_margin_right = 12
		normal_style.content_margin_top = 6
		normal_style.content_margin_bottom = 6
		btn.add_theme_stylebox_override("normal", normal_style)
		
		var hover_style = normal_style.duplicate()
		hover_style.bg_color = Color(0.1, 0.08, 0.2, 0.6)
		hover_style.border_color = cat_color * Color(1, 1, 1, 0.4)
		btn.add_theme_stylebox_override("hover", hover_style)
		
		var pressed_style = normal_style.duplicate()
		pressed_style.bg_color = Color(0.1, 0.06, 0.2, 0.8)
		pressed_style.border_color = cat_color * Color(1, 1, 1, 0.9)
		btn.add_theme_stylebox_override("pressed", pressed_style)
		
		if cat == "all":
			btn.button_pressed = true
		btn.pressed.connect(_on_category_pressed.bind(cat))
		category_box.add_child(btn)
		category_buttons[cat] = btn
	
	$VBox.add_child(category_box)
	$VBox.move_child(category_box, 1)  # After title, before grid
	
	# Populate class grid
	_populate_class_grid("all")
	
	# Connect select button
	select_button.pressed.connect(_on_select_pressed)
	select_button.disabled = true
	
	# Connect subclass checkbox
	subclass_check.toggled.connect(_on_subclass_toggled)
	
	# Hide info panel initially (show placeholder text)
	class_info_panel.visible = true


func _get_or_create_button_group() -> ButtonGroup:
	var group = ButtonGroup.new()
	return group


func _get_class_role(player_class: PlayerClass) -> String:
	var class_type = player_class.get_script().get_global_name()
	if class_type in ["GuardianClass", "BerserkerClass", "PaladinClass"]:
		return "tank"
	elif class_type in ["AssassinClass", "RangerClass", "MageClass", "SamuraiClass"]:
		return "dps"
	elif class_type in ["ClericClass", "BardClass", "AlchemistClass", "NecromancerClass"]:
		return "support"
	elif class_type in ["SpellbladeClass", "ShadowKnightClass", "MonkClass"]:
		return "hybrid"
	return "all"


func _populate_class_grid(category: String):
	# Clear existing buttons
	for child in class_grid.get_children():
		child.queue_free()
	
	_active_class_button = null
	
	for player_class in available_classes:
		if category != "all" and not _class_matches_category(player_class, category):
			continue
		
		var role = _get_class_role(player_class)
		var role_color = ROLE_COLORS.get(role, Color(0.5, 0.5, 0.6))
		
		# --- Pixel-art class card button ---
		var card = Button.new()
		card.custom_minimum_size = Vector2(0, 42)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.toggle_mode = true
		card.text = player_class.display_name
		card.add_theme_font_size_override("font_size", 12)
		card.add_theme_color_override("font_color", Color(0.7, 0.65, 0.85, 0.9))
		card.add_theme_color_override("font_hover_color", Color(0.95, 0.82, 0.35, 1))
		card.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))
		
		# Normal state (pixel-art flat)
		var card_normal = StyleBoxFlat.new()
		card_normal.bg_color = Color(0.08, 0.06, 0.14, 0.7)
		card_normal.border_width_left = 3
		card_normal.border_width_top = 2
		card_normal.border_width_right = 2
		card_normal.border_width_bottom = 2
		card_normal.border_color = Color(0.25, 0.2, 0.38, 0.5)
		card_normal.corner_radius_top_left = 4
		card_normal.corner_radius_top_right = 4
		card_normal.corner_radius_bottom_right = 4
		card_normal.corner_radius_bottom_left = 4
		card_normal.content_margin_left = 14
		card_normal.content_margin_right = 10
		card_normal.content_margin_top = 8
		card_normal.content_margin_bottom = 8
		card.add_theme_stylebox_override("normal", card_normal)
		
		# Hover state — role color accent border
		var card_hover = card_normal.duplicate()
		card_hover.bg_color = Color(0.1, 0.08, 0.2, 0.85)
		card_hover.border_color = role_color * Color(1, 1, 1, 0.6)
		card_hover.border_width_left = 3
		card.add_theme_stylebox_override("hover", card_hover)
		
		# Pressed (selected) state — strong role accent
		var card_pressed = card_normal.duplicate()
		card_pressed.bg_color = Color(0.1, 0.06, 0.2, 0.95)
		card_pressed.border_color = role_color * Color(1, 1, 1, 0.9)
		card_pressed.border_width_left = 3
		card_pressed.shadow_color = role_color * Color(1, 1, 1, 0.15)
		card_pressed.shadow_size = 4
		card.add_theme_stylebox_override("pressed", card_pressed)
		
		card.pressed.connect(_on_class_button_pressed.bind(player_class, card))
		class_grid.add_child(card)


func _class_matches_category(player_class: PlayerClass, category: String) -> bool:
	var class_type = player_class.get_script().get_global_name()
	match category:
		"tank":
			return class_type in ["GuardianClass", "BerserkerClass", "PaladinClass"]
		"dps":
			return class_type in ["AssassinClass", "RangerClass", "MageClass", "SamuraiClass"]
		"support":
			return class_type in ["ClericClass", "BardClass", "AlchemistClass", "NecromancerClass"]
		"hybrid":
			return class_type in ["SpellbladeClass", "ShadowKnightClass", "MonkClass"]
		_:
			return true


func _on_category_pressed(category: String):
	current_category = category
	_populate_class_grid(category)
	selected_class = null
	class_name_label.text = "Select a class"
	class_desc_label.text = "Choose a class from the grid above to see details."
	stats_label.text = ""
	ability_label.text = ""
	passive_label.text = ""
	select_button.disabled = true
	select_button.text = "✦  Confirm Class"


func _on_class_button_pressed(player_class: PlayerClass, btn: Button):
	# Deselect previous button
	if _active_class_button and is_instance_valid(_active_class_button) and _active_class_button != btn:
		_active_class_button.button_pressed = false
	
	_active_class_button = btn
	selected_class = player_class
	_update_class_info()
	select_button.disabled = false
	select_button.text = "✦  Select " + player_class.display_name


func _update_class_info():
	if selected_class == null:
		return
	
	class_name_label.text = selected_class.display_name
	class_desc_label.text = selected_class.description
	
	# Stats with modifiers shown as colored values
	var stats_parts: Array = []
	if selected_class.modifiers_hp != 1.0:
		stats_parts.append("HP %+.0f%%" % [(selected_class.modifiers_hp - 1.0) * 100])
	if selected_class.modifiers_speed != 1.0:
		stats_parts.append("SPD %+.0f%%" % [(selected_class.modifiers_speed - 1.0) * 100])
	if selected_class.modifiers_damage != 1.0:
		stats_parts.append("DMG %+.0f%%" % [(selected_class.modifiers_damage - 1.0) * 100])
	if selected_class.modifiers_defense != 1.0:
		stats_parts.append("DEF %+.0f%%" % [(selected_class.modifiers_defense - 1.0) * 100])
	if selected_class.modifiers_attack_speed != 1.0:
		stats_parts.append("ATKSPD %+.0f%%" % [(selected_class.modifiers_attack_speed - 1.0) * 100])
	if selected_class.modifiers_crit_chance != 1.0:
		stats_parts.append("CRIT %+.0f%%" % [(selected_class.modifiers_crit_chance - 1.0) * 100])
	
	if stats_parts.size() > 0:
		stats_label.text = "⚙ " + " · ".join(stats_parts)
	else:
		stats_label.text = "⚙ Base stats (no modifiers)"
	
	# Ability
	if selected_class.ability_name:
		ability_label.text = "⚡ " + selected_class.ability_name + "\n" + selected_class.ability_description
	else:
		ability_label.text = ""
	
	# Passive
	if selected_class.passive_name:
		passive_label.text = "✧ " + selected_class.passive_name + "\n" + selected_class.passive_description
	else:
		passive_label.text = ""


func _on_subclass_toggled(toggled: bool):
	is_subclass_selected = toggled


func _on_select_pressed():
	if selected_class == null:
		return
	class_selected.emit(selected_class, is_subclass_selected)
	
	# Visual feedback — briefly flash the button text
	select_button.text = "✓  " + selected_class.display_name + " Selected!"
	select_button.disabled = true
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(select_button):
		select_button.disabled = false
		select_button.text = "✦  Select " + selected_class.display_name


func set_player_level(level: int):
	player_level = level
	_update_subclass_availability()


func _update_subclass_availability():
	var can_use_subclass = player_level >= 10
	subclass_check.disabled = not can_use_subclass
	subclass_check.visible = can_use_subclass
	
	# Also show/hide the subclass hint bar
	var hint_bar = $VBox/SubclassHintBar
	
	if can_use_subclass:
		subclass_hint.text = "✦ Subclass unlocked! Select a second class to combine."
		subclass_hint.add_theme_color_override("font_color", Color(0.45, 0.85, 0.5, 0.8))
		hint_bar.visible = true
	else:
		subclass_hint.text = "🔒 Reach level 10 to unlock Subclass"
		subclass_hint.add_theme_color_override("font_color", Color(0.45, 0.48, 0.58, 0.55))
		hint_bar.visible = true


func get_selected_class() -> PlayerClass:
	return selected_class


func is_subclass_mode() -> bool:
	return is_subclass_selected and player_level >= 10
