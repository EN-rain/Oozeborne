extends Control
class_name SkillTreeUI

signal closed

const TYPE_COLORS := {
	SkillDefinition.SkillType.STAT: Color(0.34, 0.82, 0.48, 1.0),
	SkillDefinition.SkillType.ABILITY: Color(0.36, 0.66, 0.98, 1.0),
	SkillDefinition.SkillType.PASSIVE: Color(0.76, 0.46, 0.92, 1.0),
	SkillDefinition.SkillType.SPECIAL: Color(0.98, 0.72, 0.28, 1.0),
}

@onready var title_label: Label = %TitleLabel
@onready var sp_label: Label = %SpLabel
@onready var status_label: Label = %StatusLabel
@onready var tab_container: TabContainer = %Tabs
@onready var action_bar_slots: HBoxContainer = %ActionBarSlots
@onready var tooltip_panel: PanelContainer = %TooltipPanel
@onready var tooltip_title: Label = %TooltipTitle
@onready var tooltip_body: Label = %TooltipBody
@onready var close_button: Button = %CloseButton

var _status_timer: Timer
var _selected_skill_id: String = ""
var _slot_buttons: Array[Button] = []
var _skill_card_refs: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_status_timer = Timer.new()
	_status_timer.one_shot = true
	_status_timer.wait_time = 2.0
	_status_timer.timeout.connect(_on_status_timeout)
	add_child(_status_timer)
	tooltip_panel.visible = false
	_setup_action_bar()
	_connect_signals()
	_refresh_all()


func _process(_delta: float) -> void:
	if visible:
		_refresh_action_bar()


func open() -> void:
	_refresh_all()
	show()


func close() -> void:
	if not visible:
		return
	hide()
	tooltip_panel.visible = false
	closed.emit()


func _on_close_pressed() -> void:
	close()


func _connect_signals() -> void:
	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)
	var manager = _skill_tree_manager()
	if manager == null:
		return
	if not manager.sp_changed.is_connected(_on_sp_changed):
		manager.sp_changed.connect(_on_sp_changed)
	if not manager.skill_invested.is_connected(_on_skill_invested):
		manager.skill_invested.connect(_on_skill_invested)
	if not manager.subclasses_unlocked.is_connected(_on_subclasses_unlocked):
		manager.subclasses_unlocked.connect(_on_subclasses_unlocked)
	if not manager.subclass_locked.is_connected(_on_subclass_locked):
		manager.subclass_locked.connect(_on_subclass_locked)
	if not manager.insufficient_sp.is_connected(_on_insufficient_sp):
		manager.insufficient_sp.connect(_on_insufficient_sp)
	if not manager.skill_not_learned.is_connected(_on_skill_not_learned):
		manager.skill_not_learned.connect(_on_skill_not_learned)


func _setup_action_bar() -> void:
	for child in action_bar_slots.get_children():
		child.queue_free()
	_slot_buttons.clear()
	for slot_index in range(4):
		var button = Button.new()
		button.custom_minimum_size = Vector2(0, 60)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_action_slot_pressed.bind(slot_index))
		action_bar_slots.add_child(button)
		_slot_buttons.append(button)


func _refresh_all() -> void:
	title_label.text = "SKILL TREE"
	_selected_skill_id = ""
	_refresh_sp_label()
	_refresh_tabs()
	_refresh_action_bar()


func _refresh_sp_label() -> void:
	var manager = _skill_tree_manager()
	sp_label.text = "SP %d / %d" % [manager.get_sp_available(), manager.get_total_sp_earned()] if manager != null else "SP 0 / 0"


func _refresh_tabs() -> void:
	for child in tab_container.get_children():
		child.queue_free()
	_skill_card_refs.clear()

	var main_class: PlayerClass = MultiplayerManager.player_class
	if main_class == null:
		var empty_tab = VBoxContainer.new()
		var label = Label.new()
		label.text = "Select a main class to unlock the skill tree."
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_tab.add_child(label)
		tab_container.add_child(empty_tab)
		tab_container.set_tab_title(0, "Unavailable")
		return

	var main_class_id = ClassManager.get_class_id(main_class)
	_add_tree_tab("Main", main_class_id, "main")
	for subclass_id in ClassManager.get_subclass_ids_for_main_id(main_class_id):
		_add_tree_tab(ClassManager.class_id_to_display_name(subclass_id), main_class_id, subclass_id)


func _add_tree_tab(tab_name: String, main_class_id: String, tree_key: String) -> void:
	var root = MarginContainer.new()
	root.add_theme_constant_override("margin_left", 8)
	root.add_theme_constant_override("margin_top", 8)
	root.add_theme_constant_override("margin_right", 8)
	root.add_theme_constant_override("margin_bottom", 8)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	var tab_info = Label.new()
	tab_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tab_info.text = _build_tab_header_text(tree_key)
	vbox.add_child(tab_info)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	vbox.add_child(grid)

	var registry = _skill_registry()
	var skills = registry.get_skills_for_tree(main_class_id, tree_key) if registry != null else []
	for skill in skills:
		grid.add_child(_create_skill_card(skill, tree_key))

	tab_container.add_child(root)
	tab_container.set_tab_title(tab_container.get_tab_count() - 1, tab_name)


func _build_tab_header_text(tree_key: String) -> String:
	var manager = _skill_tree_manager()
	if tree_key == "main":
		return "Spend 20 SP in the main tree to unlock subclass tabs."
	var spent = int(manager.call("get_subclass_sp_spent", tree_key)) if manager != null else 0
	var unlocked = bool(manager.call("are_subclasses_unlocked")) if manager != null else false
	if unlocked:
		return "%s tree unlocked. %d / 30 SP invested." % [ClassManager.class_id_to_display_name(tree_key), spent]
	return "%s tree locked until 20 SP are invested in the main tree." % ClassManager.class_id_to_display_name(tree_key)


func _create_skill_card(skill, tree_key: String) -> Control:
	var card = Button.new()
	card.alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 170)
	card.focus_mode = Control.FOCUS_NONE
	card.mouse_entered.connect(_show_tooltip.bind(skill.skill_id))
	card.mouse_exited.connect(_hide_tooltip)
	card.pressed.connect(_on_skill_card_pressed.bind(skill.skill_id))

	var container = VBoxContainer.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_theme_constant_override("separation", 6)
	card.add_child(container)

	var top_row = HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(top_row)

	var indicator = ColorRect.new()
	indicator.custom_minimum_size = Vector2(12, 12)
	indicator.color = TYPE_COLORS.get(skill.skill_type, Color.WHITE)
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(indicator)

	var title = Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(title)

	var level_label = Label.new()
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(level_label)

	var desc = Label.new()
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(desc)

	var footer = HBoxContainer.new()
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(footer)

	var state_label = Label.new()
	state_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_child(state_label)

	var invest_button = Button.new()
	invest_button.text = "Invest"
	invest_button.pressed.connect(_on_invest_pressed.bind(skill.skill_id))
	footer.add_child(invest_button)

	_skill_card_refs[skill.skill_id] = {
		"card": card,
		"title": title,
		"level": level_label,
		"description": desc,
		"state": state_label,
		"invest": invest_button,
		"tree_key": tree_key,
	}
	_refresh_skill_card(skill.skill_id)
	return card


func _refresh_skill_card(skill_id: String) -> void:
	if not _skill_card_refs.has(skill_id):
		return
	var manager = _skill_tree_manager()
	var registry = _skill_registry()
	if manager == null or registry == null:
		return
	var refs: Dictionary = _skill_card_refs[skill_id]
	var skill = registry.get_skill(skill_id)
	if skill == null:
		return

	var level = int(manager.call("get_skill_level", skill_id))
	var is_maxed = level >= skill.max_level
	var is_subclass_tree = str(refs.get("tree_key", "")) != "main"
	var unlocked = not is_subclass_tree or bool(manager.call("are_subclasses_unlocked"))
	var slottable = bool(manager.call("is_skill_available_for_slotting", skill_id))

	var title: Label = refs["title"]
	var level_label: Label = refs["level"]
	var desc: Label = refs["description"]
	var state_label: Label = refs["state"]
	var invest_button: Button = refs["invest"]
	var card: Button = refs["card"]

	title.text = skill.display_name
	level_label.text = "%d / %d" % [level, skill.max_level]
	desc.text = _summarize_skill(skill, level)
	state_label.text = _build_skill_state_text(skill, level, slottable, unlocked)
	invest_button.disabled = is_maxed or not unlocked or int(manager.call("get_sp_available")) <= 0
	card.disabled = not unlocked
	card.text = ""
	var style = _build_card_style(level, unlocked, is_maxed, _selected_skill_id == skill_id)
	card.add_theme_stylebox_override("normal", style)
	card.add_theme_stylebox_override("hover", style)
	card.add_theme_stylebox_override("pressed", style)
	card.add_theme_stylebox_override("disabled", style)


func _build_skill_state_text(skill, level: int, slottable: bool, unlocked: bool) -> String:
	if not unlocked:
		return "Locked"
	if level >= skill.max_level:
		return "Maxed"
	if slottable and (skill.skill_type == SkillDefinition.SkillType.ABILITY or skill.skill_type == SkillDefinition.SkillType.SPECIAL):
		return "Ready to slot"
	if level > 0:
		return "Learned"
	return "Unlearned"


func _build_card_style(level: int, unlocked: bool, is_maxed: bool, is_selected: bool) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.content_margin_left = 12
	style.content_margin_top = 12
	style.content_margin_right = 12
	style.content_margin_bottom = 12
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	if not unlocked:
		style.bg_color = Color(0.12, 0.12, 0.14, 0.9)
		style.border_color = Color(0.28, 0.28, 0.32, 0.7)
	elif is_maxed:
		style.bg_color = Color(0.18, 0.2, 0.14, 0.95)
		style.border_color = Color(0.9, 0.8, 0.3, 0.95)
	elif is_selected:
		style.bg_color = Color(0.16, 0.24, 0.34, 0.95)
		style.border_color = Color(0.45, 0.75, 1.0, 0.95)
	elif level > 0:
		style.bg_color = Color(0.12, 0.18, 0.22, 0.95)
		style.border_color = Color(0.3, 0.55, 0.72, 0.85)
	else:
		style.bg_color = Color(0.08, 0.1, 0.14, 0.96)
		style.border_color = Color(0.2, 0.3, 0.4, 0.7)
	return style


func _summarize_skill(skill, level: int) -> String:
	var description = skill.get_description(max(level, 1))
	var lines = description.split("\n", false)
	return lines[0] if not lines.is_empty() else description


func _show_tooltip(skill_id: String) -> void:
	var registry = _skill_registry()
	var manager = _skill_tree_manager()
	if registry == null or manager == null:
		return
	var skill = registry.get_skill(skill_id)
	if skill == null:
		return
	var level = int(manager.call("get_skill_level", skill_id))
	var current_text = skill.get_description(max(level, 1))
	var next_text = "Max rank reached." if level >= skill.max_level else skill.get_description(level + 1)
	tooltip_title.text = "%s  [%d / %d]" % [skill.display_name, level, skill.max_level]
	tooltip_body.text = "Current\n%s\n\nNext\n%s" % [current_text, next_text]
	tooltip_panel.visible = true


func _hide_tooltip() -> void:
	tooltip_panel.visible = false


func _refresh_action_bar() -> void:
	var manager = _skill_tree_manager()
	var registry = _skill_registry()
	if manager == null:
		return
	for slot_index in range(_slot_buttons.size()):
		var button = _slot_buttons[slot_index]
		var skill_id = str(manager.call("get_slotted_skill", slot_index))
		if skill_id.is_empty():
			button.text = "Slot %d\nEmpty" % (slot_index + 1)
			continue
		var skill = registry.get_skill(skill_id) if registry != null else null
		var cooldown = PlayerSkillManager.get_ability_cooldown_remaining(slot_index)
		button.text = "Slot %d\n%s\n%s" % [
			slot_index + 1,
			skill.display_name if skill != null else skill_id,
			"%.1fs" % cooldown if cooldown > 0.0 else "Ready"
		]


func _on_invest_pressed(skill_id: String) -> void:
	var manager = _skill_tree_manager()
	var registry = _skill_registry()
	if manager != null and bool(manager.call("invest_sp", skill_id)):
		var skill = registry.get_skill(skill_id) if registry != null else null
		_show_status("Invested in %s." % (skill.display_name if skill != null else skill_id), Color(0.62, 0.92, 0.72, 1))


func _on_skill_card_pressed(skill_id: String) -> void:
	var manager = _skill_tree_manager()
	var registry = _skill_registry()
	if manager == null or registry == null:
		return
	var skill = registry.get_skill(skill_id)
	if skill == null:
		return
	if skill.skill_type != SkillDefinition.SkillType.ABILITY and skill.skill_type != SkillDefinition.SkillType.SPECIAL:
		return
	if not bool(manager.call("is_skill_available_for_slotting", skill_id)):
		_show_status("Learn the skill before slotting it.", Color(1, 0.6, 0.45, 1))
		return
	_selected_skill_id = "" if _selected_skill_id == skill_id else skill_id
	for key in _skill_card_refs.keys():
		_refresh_skill_card(str(key))
	_show_status("Selected %s for slotting." % skill.display_name, Color(0.65, 0.85, 1.0, 1.0))


func _on_action_slot_pressed(slot_index: int) -> void:
	var manager = _skill_tree_manager()
	var registry = _skill_registry()
	if manager == null:
		return
	if not _selected_skill_id.is_empty():
		if bool(manager.call("slot_ability", slot_index, _selected_skill_id)):
			var skill = registry.get_skill(_selected_skill_id) if registry != null else null
			_show_status("Slotted %s into slot %d." % [skill.display_name if skill != null else _selected_skill_id, slot_index + 1], Color(0.65, 0.85, 1.0, 1.0))
			_selected_skill_id = ""
			for key in _skill_card_refs.keys():
				_refresh_skill_card(str(key))
			_refresh_action_bar()
		return
	if not str(manager.call("get_slotted_skill", slot_index)).is_empty():
		manager.call("clear_slot", slot_index)
		_show_status("Cleared slot %d." % (slot_index + 1), Color(1, 0.8, 0.55, 1.0))
	_refresh_action_bar()


func _show_status(message: String, color: Color) -> void:
	status_label.text = message
	status_label.modulate = color
	_status_timer.start()


func _on_status_timeout() -> void:
	status_label.text = ""


func _on_sp_changed(_available: int, _total: int) -> void:
	_refresh_sp_label()
	for skill_id in _skill_card_refs.keys():
		_refresh_skill_card(str(skill_id))


func _on_skill_invested(skill_id: String, _new_level: int) -> void:
	_refresh_sp_label()
	if _skill_card_refs.has(skill_id):
		_refresh_skill_card(skill_id)
	_refresh_action_bar()


func _on_subclasses_unlocked(_main_class: String) -> void:
	_show_status("Subclass trees unlocked.", Color(0.85, 0.95, 0.55, 1.0))
	_refresh_tabs()


func _on_subclass_locked(subclass_key: String, reason: String) -> void:
	var name = ClassManager.class_id_to_display_name(subclass_key)
	_show_status("%s reached its 30 SP cap." % name if reason == "subclass_cap_reached" else "%s is still locked." % name, Color(1, 0.55, 0.45, 1.0))


func _on_insufficient_sp(required: int, available: int) -> void:
	_show_status("Need %d SP, only %d available." % [required, available], Color(1, 0.55, 0.45, 1.0))


func _on_skill_not_learned(skill_id: String) -> void:
	var registry = _skill_registry()
	var skill = registry.get_skill(skill_id) if registry != null else null
	_show_status("%s is not available for slotting." % (skill.display_name if skill != null else skill_id), Color(1, 0.55, 0.45, 1.0))


func _skill_tree_manager():
	return get_tree().root.get_node_or_null("SkillTreeManager")


func _skill_registry():
	return get_tree().root.get_node_or_null("SkillRegistry")
