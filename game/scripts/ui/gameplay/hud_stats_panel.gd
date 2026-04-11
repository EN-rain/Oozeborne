extends Control
class_name HudStatsPanel

const SkillTreeData := preload("res://scripts/globals/skill_tree_runtime_data.gd")
@export var breakdown_base_color: Color = Color("8fd3ff")
@export var breakdown_level_color: Color = Color("8ef0a7")
@export var breakdown_class_color: Color = Color("ffd37a")
@export var breakdown_tree_color: Color = Color("ff94cf")

@onready var hp_stat_card: PanelContainer = %HPCard
@onready var attack_stat_card: PanelContainer = %AttackCard
@onready var defense_stat_card: PanelContainer = %DefenseCard
@onready var speed_stat_card: PanelContainer = %SpeedCard
@onready var crit_rate_stat_card: PanelContainer = %CritCard
@onready var crit_damage_stat_card: PanelContainer = %EvadeCard
@onready var hp_stat_value_label: Label = $ClassStats/StatsVBox/StatsCards/HPCard/Margin/VBox/Value
@onready var attack_stat_value_label: Label = $ClassStats/StatsVBox/StatsCards/AttackCard/Margin/VBox/Value
@onready var defense_stat_value_label: Label = $ClassStats/StatsVBox/StatsCards/DefenseCard/Margin/VBox/Value
@onready var speed_stat_value_label: Label = $ClassStats/StatsVBox/StatsCards/SpeedCard/Margin/VBox/Value
@onready var crit_rate_stat_value_label: Label = $ClassStats/StatsVBox/StatsCards/CritCard/Margin/VBox/Value
@onready var crit_damage_stat_value_label: Label = $ClassStats/StatsVBox/StatsCards/EvadeCard/Margin/VBox/Value
@onready var class_title_label: Label = $ClassStats/StatsVBox/ClassTitle
@onready var stat_breakdown_popup: PanelContainer = $"../StatBreakdownPopup"
@onready var stat_breakdown_title: Label = $"../StatBreakdownPopup/Content/Title"
@onready var stat_breakdown_token_0: Label = $"../StatBreakdownPopup/Content/Values/Token0"
@onready var stat_breakdown_operator_0: Label = $"../StatBreakdownPopup/Content/Values/Operator0"
@onready var stat_breakdown_token_1: Label = $"../StatBreakdownPopup/Content/Values/Token1"
@onready var stat_breakdown_operator_1: Label = $"../StatBreakdownPopup/Content/Values/Operator1"
@onready var stat_breakdown_token_2: Label = $"../StatBreakdownPopup/Content/Values/Token2"
@onready var stat_breakdown_operator_2: Label = $"../StatBreakdownPopup/Content/Values/Operator2"
@onready var stat_breakdown_token_3: Label = $"../StatBreakdownPopup/Content/Values/Token3"

var _player_ref: CharacterBody2D = null
var _stat_breakdown_hovered: bool = false
var _active_stat_key: String = ""
var _active_stat_card: Control = null
var _stat_breakdown_component_labels: Array[Label] = []
var _stat_breakdown_operator_labels: Array[Label] = []


func _ready() -> void:
	_configure_stat_breakdown_popup()
	_connect_stat_card_hovers()


func set_player(player: CharacterBody2D) -> void:
	_player_ref = player
	refresh_player_stat_cards()


func refresh_player_stat_cards() -> void:
	if _player_ref == null or not is_instance_valid(_player_ref):
		return

	var level_stats: Dictionary = LevelSystem.get_current_stats(_player_ref)
	var health_component := _player_ref.get_node_or_null("Health")
	var max_health: int = int(round(float(level_stats.get("max_health", 0))))
	if health_component != null:
		max_health = int(health_component.max_health)

	var attack_damage: int = int(_player_ref.attack_damage)
	var movement_speed: float = float(_player_ref.speed)
	var defense_modifier: float = float(_player_ref.get_meta("defense_modifier", 1.0))
	var crit_chance: float = float(_player_ref.get_meta("crit_chance", float(level_stats.get("crit_chance", 0.0))))
	var crit_damage: float = float(_player_ref.get_meta("crit_damage", float(level_stats.get("crit_damage", 1.0))))

	if hp_stat_value_label != null:
		hp_stat_value_label.text = _format_whole_number(max_health)
	if attack_stat_value_label != null:
		attack_stat_value_label.text = _format_whole_number(attack_damage)
	if defense_stat_value_label != null:
		defense_stat_value_label.text = _format_percent(defense_modifier)
	if speed_stat_value_label != null:
		speed_stat_value_label.text = _format_whole_number(int(round(movement_speed)))
	if crit_rate_stat_value_label != null:
		crit_rate_stat_value_label.text = _format_percent(crit_chance)
	if crit_damage_stat_value_label != null:
		crit_damage_stat_value_label.text = _format_percent(maxf(0.0, crit_damage - 1.0))
	if class_title_label != null:
		class_title_label.text = _get_active_class_label()
	if _active_stat_card != null and not _active_stat_key.is_empty():
		_show_stat_breakdown(_active_stat_key, _active_stat_card)


func _format_whole_number(value: int) -> String:
	return "%d" % value


func _format_percent(value: float) -> String:
	return "%d%%" % int(round(value * 100.0))


func _format_stat_number(value: float) -> String:
	if abs(value - round(value)) <= 0.05:
		return "%d" % int(round(value))
	return "%.1f" % value


func _configure_stat_breakdown_popup() -> void:
	_stat_breakdown_component_labels = [
		stat_breakdown_token_0,
		stat_breakdown_token_1,
		stat_breakdown_token_2,
		stat_breakdown_token_3,
	]
	_stat_breakdown_operator_labels = [
		stat_breakdown_operator_0,
		stat_breakdown_operator_1,
		stat_breakdown_operator_2,
	]
	if stat_breakdown_popup != null:
		stat_breakdown_popup.hide()
		if not stat_breakdown_popup.mouse_entered.is_connected(_on_stat_breakdown_popup_entered):
			stat_breakdown_popup.mouse_entered.connect(_on_stat_breakdown_popup_entered)
		if not stat_breakdown_popup.mouse_exited.is_connected(_on_stat_breakdown_popup_exited):
			stat_breakdown_popup.mouse_exited.connect(_on_stat_breakdown_popup_exited)
	_clear_stat_breakdown_tokens()


func _connect_stat_card_hovers() -> void:
	_connect_stat_card_hover(hp_stat_card, "hp")
	_connect_stat_card_hover(attack_stat_card, "attack")
	_connect_stat_card_hover(defense_stat_card, "defense")
	_connect_stat_card_hover(speed_stat_card, "speed")
	_connect_stat_card_hover(crit_rate_stat_card, "crit_rate")
	_connect_stat_card_hover(crit_damage_stat_card, "crit_damage")


func _connect_stat_card_hover(card: Control, stat_key: String) -> void:
	if card == null:
		return
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_child_mouse_filter_ignore(card)
	card.mouse_entered.connect(_on_stat_card_mouse_entered.bind(stat_key, card))
	card.mouse_exited.connect(_on_stat_card_mouse_exited.bind(card))


func _set_child_mouse_filter_ignore(control: Control) -> void:
	for child in control.get_children():
		if child is Control:
			var child_control := child as Control
			child_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_set_child_mouse_filter_ignore(child_control)


func _on_stat_card_mouse_entered(stat_key: String, card: Control) -> void:
	_active_stat_key = stat_key
	_active_stat_card = card
	_show_stat_breakdown(stat_key, card)


func _on_stat_card_mouse_exited(card: Control) -> void:
	if card == _active_stat_card:
		call_deferred("_maybe_hide_stat_breakdown")


func _on_stat_breakdown_popup_entered() -> void:
	_stat_breakdown_hovered = true


func _on_stat_breakdown_popup_exited() -> void:
	_stat_breakdown_hovered = false
	call_deferred("_maybe_hide_stat_breakdown")


func _maybe_hide_stat_breakdown() -> void:
	if _stat_breakdown_hovered:
		return
	var hovered_control := get_viewport().gui_get_hovered_control()
	if _active_stat_card != null and hovered_control != null and (_active_stat_card == hovered_control or _active_stat_card.is_ancestor_of(hovered_control)):
		return
	_hide_stat_breakdown()


func _hide_stat_breakdown() -> void:
	_active_stat_key = ""
	_active_stat_card = null
	if stat_breakdown_popup != null:
		stat_breakdown_popup.hide()


func _show_stat_breakdown(stat_key: String, card: Control) -> void:
	if card == null or stat_breakdown_popup == null or _player_ref == null or not is_instance_valid(_player_ref):
		return

	var breakdown := _build_stat_breakdown(stat_key, _player_ref)
	if breakdown.is_empty():
		return

	var components: Array = breakdown.get("components", [])
	stat_breakdown_title.text = str(breakdown.get("title", ""))
	_render_breakdown_tokens(components)
	stat_breakdown_popup.show()
	call_deferred("_position_stat_breakdown_popup", card)


func _position_stat_breakdown_popup(card: Control) -> void:
	if card == null or stat_breakdown_popup == null or not stat_breakdown_popup.visible:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var card_rect := Rect2(card.global_position, card.size)
	var popup_size: Vector2 = stat_breakdown_popup.get_combined_minimum_size()
	var next_x := card_rect.position.x + (card_rect.size.x - popup_size.x) * 0.5
	var next_y := card_rect.position.y - popup_size.y - 12.0
	if next_y < 12.0:
		next_y = card_rect.end.y + 12.0
	next_x = clampf(next_x, 12.0, maxf(12.0, viewport_size.x - popup_size.x - 12.0))
	next_y = clampf(next_y, 12.0, maxf(12.0, viewport_size.y - popup_size.y - 12.0))
	stat_breakdown_popup.position = Vector2(next_x, next_y)


func _render_breakdown_tokens(components: Array) -> void:
	_clear_stat_breakdown_tokens()
	var component_count := mini(components.size(), _stat_breakdown_component_labels.size())
	for index in range(component_count):
		var component: Dictionary = components[index]
		_set_breakdown_label(
			_stat_breakdown_component_labels[index],
			str(component.get("value", "0")),
			component.get("color", breakdown_base_color),
			str(component.get("tooltip", ""))
		)
		if index < component_count - 1 and index < _stat_breakdown_operator_labels.size():
			_set_breakdown_label(_stat_breakdown_operator_labels[index], "+", Color(1, 1, 1, 0.52), "")


func _clear_stat_breakdown_tokens() -> void:
	for label in _stat_breakdown_component_labels:
		_set_breakdown_label(label, "", breakdown_base_color, "", false)
	for label in _stat_breakdown_operator_labels:
		_set_breakdown_label(label, "", Color(1, 1, 1, 0.52), "", false)


func _set_breakdown_label(label: Label, text: String, color: Color, tooltip: String, show_label: bool = true) -> void:
	if label == null:
		return
	label.text = text
	label.tooltip_text = tooltip
	label.visible = show_label and not text.is_empty()
	label.add_theme_color_override("font_color", color)


func _build_stat_breakdown(stat_key: String, player: CharacterBody2D) -> Dictionary:
	var base_stat_resource: PlayerStats = LevelSystem.player_stats
	if base_stat_resource == null:
		return {}

	var level_stats: Dictionary = LevelSystem.get_current_stats(player)
	var class_data := _get_class_stat_data()
	var skill_tree_data := _get_skill_tree_stat_data()

	match stat_key:
		"hp":
			return _build_hp_breakdown(player, base_stat_resource, level_stats, class_data)
		"attack":
			return _build_attack_breakdown(player, base_stat_resource, level_stats, class_data)
		"defense":
			return _build_defense_breakdown(player)
		"speed":
			return _build_speed_breakdown(player, base_stat_resource, level_stats, class_data)
		"crit_rate":
			return _build_crit_rate_breakdown(player, base_stat_resource, class_data, skill_tree_data)
		"crit_damage":
			return _build_crit_damage_breakdown(player, base_stat_resource, class_data, skill_tree_data)
	return {}


func _build_hp_breakdown(player: CharacterBody2D, base_stat_resource: PlayerStats, level_stats: Dictionary, class_data: Dictionary) -> Dictionary:
	var raw_total: int = int(level_stats.get("max_health", base_stat_resource.base_max_health))
	var base_value: int = base_stat_resource.base_max_health
	var level_bonus: int = raw_total - base_value
	var class_applied: int = int(raw_total * float(class_data.get("hp_mult", 1.0)))
	var class_bonus: int = class_applied - raw_total
	var health_component := player.get_node_or_null("Health")
	var final_total: int = int(health_component.max_health) if health_component != null else class_applied
	var skill_tree_bonus: int = final_total - class_applied
	return {
		"title": "HP",
		"components": [
			_make_breakdown_component(base_value, breakdown_base_color, "Base HP"),
			_make_breakdown_component(level_bonus, breakdown_level_color, "Level HP Bonus"),
			_make_breakdown_component(class_bonus, breakdown_class_color, "Class HP Bonus"),
			_make_breakdown_component(skill_tree_bonus, breakdown_tree_color, "Skill Tree HP Bonus"),
		]
	}


func _build_attack_breakdown(player: CharacterBody2D, base_stat_resource: PlayerStats, level_stats: Dictionary, class_data: Dictionary) -> Dictionary:
	var raw_total: int = int(level_stats.get("attack_damage", base_stat_resource.base_attack_damage))
	var base_value: int = base_stat_resource.base_attack_damage
	var level_bonus: int = raw_total - base_value
	var class_applied: int = int(raw_total * float(class_data.get("damage_mult", 1.0)))
	var class_bonus: int = class_applied - raw_total
	var final_total: int = int(player.attack_damage)
	var skill_tree_bonus: int = final_total - class_applied
	return {
		"title": "Attack",
		"components": [
			_make_breakdown_component(base_value, breakdown_base_color, "Base Attack"),
			_make_breakdown_component(level_bonus, breakdown_level_color, "Level Attack Bonus"),
			_make_breakdown_component(class_bonus, breakdown_class_color, "Class Attack Bonus"),
			_make_breakdown_component(skill_tree_bonus, breakdown_tree_color, "Skill Tree Attack Bonus"),
		]
	}


func _build_defense_breakdown(player: CharacterBody2D) -> Dictionary:
	var base_value := 1.0
	var class_bonus: float = float(player.get_meta("defense_modifier", 1.0)) - base_value
	return {
		"title": "Defense",
		"components": [
			_make_percent_breakdown_component(base_value, breakdown_base_color, "Base Defense"),
			_make_percent_breakdown_component(class_bonus, breakdown_class_color, "Class Defense Bonus"),
		]
	}


func _build_speed_breakdown(player: CharacterBody2D, base_stat_resource: PlayerStats, level_stats: Dictionary, class_data: Dictionary) -> Dictionary:
	var raw_total: float = float(level_stats.get("speed", base_stat_resource.base_speed))
	var base_value: float = base_stat_resource.base_speed
	var level_bonus: float = raw_total - base_value
	var class_applied: float = raw_total * float(class_data.get("speed_mult", 1.0))
	var class_bonus: float = class_applied - raw_total
	var final_total: float = float(player.speed)
	var skill_tree_bonus: float = final_total - class_applied
	return {
		"title": "Speed",
		"components": [
			_make_breakdown_component(base_value, breakdown_base_color, "Base Speed"),
			_make_breakdown_component(level_bonus, breakdown_level_color, "Level Speed Bonus"),
			_make_breakdown_component(class_bonus, breakdown_class_color, "Class Speed Bonus"),
			_make_breakdown_component(skill_tree_bonus, breakdown_tree_color, "Skill Tree Speed Bonus"),
		]
	}


func _build_crit_rate_breakdown(player: CharacterBody2D, base_stat_resource: PlayerStats, class_data: Dictionary, skill_tree_data: Dictionary) -> Dictionary:
	var current_level: int = LevelSystem.get_level(player)
	var base_value: float = base_stat_resource.base_crit_chance
	var raw_total: float = base_stat_resource.get_crit_chance(current_level)
	var level_bonus: float = raw_total - base_value
	var class_bonus: float = float(class_data.get("crit_chance_bonus", 0.0))
	var skill_tree_meta: Dictionary = skill_tree_data.get("meta", {})
	var skill_tree_bonus: float = float(skill_tree_meta.get("crit_chance_bonus", 0.0))
	return {
		"title": "Crit Rate",
		"components": [
			_make_percent_breakdown_component(base_value, breakdown_base_color, "Base Crit Rate"),
			_make_percent_breakdown_component(level_bonus, breakdown_level_color, "Level Crit Rate Bonus"),
			_make_percent_breakdown_component(class_bonus, breakdown_class_color, "Class Crit Rate Bonus"),
			_make_percent_breakdown_component(skill_tree_bonus, breakdown_tree_color, "Skill Tree Crit Rate Bonus"),
		]
	}


func _build_crit_damage_breakdown(player: CharacterBody2D, base_stat_resource: PlayerStats, class_data: Dictionary, skill_tree_data: Dictionary) -> Dictionary:
	var current_level: int = LevelSystem.get_level(player)
	var base_value: float = maxf(0.0, base_stat_resource.base_crit_damage - 1.0)
	var raw_total: float = base_stat_resource.get_crit_damage(current_level)
	var level_bonus: float = raw_total - base_stat_resource.base_crit_damage
	var class_bonus: float = float(class_data.get("crit_damage_bonus", 0.0))
	var skill_tree_meta: Dictionary = skill_tree_data.get("meta", {})
	var skill_tree_bonus: float = float(skill_tree_meta.get("crit_damage_bonus", 0.0))
	return {
		"title": "Crit Damage",
		"components": [
			_make_percent_breakdown_component(base_value, breakdown_base_color, "Base Crit Damage Bonus"),
			_make_percent_breakdown_component(level_bonus, breakdown_level_color, "Level Crit Damage Bonus"),
			_make_percent_breakdown_component(class_bonus, breakdown_class_color, "Class Crit Damage Bonus"),
			_make_percent_breakdown_component(skill_tree_bonus, breakdown_tree_color, "Skill Tree Crit Damage Bonus"),
		]
	}


func _make_breakdown_component(value: float, color: Color, tooltip: String) -> Dictionary:
	return {"value": _format_stat_number(value), "color": color, "tooltip": tooltip}


func _make_percent_breakdown_component(value: float, color: Color, tooltip: String) -> Dictionary:
	return {"value": _format_percent(value), "color": color, "tooltip": tooltip}


func _get_class_stat_data() -> Dictionary:
	var hp_mult := 1.0
	var speed_mult := 1.0
	var damage_mult := 1.0
	var defense_mult := 1.0
	var crit_chance_bonus := 0.0
	var crit_damage_bonus := 0.0

	var main_class: PlayerClass = MultiplayerManager.player_class
	var player_subclass: PlayerClass = MultiplayerManager.player_subclass
	if main_class != null:
		hp_mult = main_class.modifiers_hp
		speed_mult = main_class.modifiers_speed
		damage_mult = main_class.modifiers_damage
		defense_mult = main_class.modifiers_defense
		crit_chance_bonus = maxf(main_class.modifiers_crit_chance - 1.0, 0.0)
		crit_damage_bonus = maxf(main_class.modifiers_crit_damage - 1.0, 0.0)
	if player_subclass != null:
		hp_mult *= 1.0 + (player_subclass.modifiers_hp - 1.0) * 0.5
		speed_mult *= 1.0 + (player_subclass.modifiers_speed - 1.0) * 0.5
		damage_mult *= 1.0 + (player_subclass.modifiers_damage - 1.0) * 0.5
		defense_mult *= 1.0 + (player_subclass.modifiers_defense - 1.0) * 0.5
		crit_chance_bonus += maxf(player_subclass.modifiers_crit_chance - 1.0, 0.0) * 0.5
		crit_damage_bonus += maxf(player_subclass.modifiers_crit_damage - 1.0, 0.0) * 0.5

	return {
		"hp_mult": hp_mult,
		"speed_mult": speed_mult,
		"damage_mult": damage_mult,
		"defense_mult": defense_mult,
		"crit_chance_bonus": crit_chance_bonus,
		"crit_damage_bonus": crit_damage_bonus,
	}


func _get_skill_tree_stat_data() -> Dictionary:
	var property_percent_bonuses := {"max_health": 0.0, "speed": 0.0, "attack_damage": 0.0}
	var property_flat_bonuses := {"max_health": 0.0, "speed": 0.0, "attack_damage": 0.0}
	var meta_totals: Dictionary = {}
	if SkillTreeManager == null or not SkillTreeManager.has_method("get_skill_level"):
		return {"property_percent": property_percent_bonuses, "property_flat": property_flat_bonuses, "meta": meta_totals}
	for skill_id_variant in SkillTreeData.STAT_RULES.keys():
		var skill_id: String = str(skill_id_variant)
		var skill_level: int = int(SkillTreeManager.get_skill_level(skill_id))
		if skill_level <= 0:
			continue
		var rule: Dictionary = SkillTreeData.STAT_RULES.get(skill_id, {})
		_accumulate_breakdown_rule(rule, skill_level, property_percent_bonuses, property_flat_bonuses, meta_totals)
	return {"property_percent": property_percent_bonuses, "property_flat": property_flat_bonuses, "meta": meta_totals}


func _get_active_class_label() -> String:
	var player_subclass: PlayerClass = MultiplayerManager.player_subclass
	if player_subclass != null and not player_subclass.display_name.is_empty():
		return player_subclass.display_name
	var main_class: PlayerClass = MultiplayerManager.player_class
	if main_class != null and not main_class.display_name.is_empty():
		return main_class.display_name
	return "Main Stats"


func _accumulate_breakdown_rule(rule: Dictionary, level: int, property_percent_bonuses: Dictionary, property_flat_bonuses: Dictionary, meta_totals: Dictionary) -> void:
	if rule.is_empty():
		return
	var kind := str(rule.get("kind", ""))
	if kind == "meta_multi":
		for entry in rule.get("entries", []):
			_accumulate_breakdown_rule(entry, level, property_percent_bonuses, property_flat_bonuses, meta_totals)
		return
	var target := str(rule.get("target", ""))
	var amount := float(rule.get("value", 0.0)) * level
	match kind:
		"property_percent":
			property_percent_bonuses[target] = float(property_percent_bonuses.get(target, 0.0)) + amount
		"property_flat":
			property_flat_bonuses[target] = float(property_flat_bonuses.get(target, 0.0)) + amount
		"meta_percent", "meta_flat":
			meta_totals[target] = float(meta_totals.get(target, 0.0)) + amount
