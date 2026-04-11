extends Control

class_name HudSkillBar

@onready var active_skill_strip_host: HBoxContainer = %ActiveSkillStrip
@onready var passive_strip_host: HBoxContainer = %PassiveStrip

@export var active_skill_slot_scene: PackedScene
@export var passive_skill_icon_scene: PackedScene

@export var cooldown_refresh_interval_sec: float = 0.05

var _hud_active_icon_nodes: Array[HudActiveSkillSlot] = []
var _hud_passive_icon_nodes: Array[HudPassiveSkillIcon] = []
var _hud_passive_strip: HBoxContainer
var _hud_passive_signature: String = ""
var _hud_needs_refresh: bool = true
@onready var _cooldown_refresh_timer: Timer = $CooldownRefreshTimer


func _ready() -> void:
	_setup_skill_hud()
	_connect_skill_tree_signals()
	_setup_refresh_timer()
	refresh_skill_hud()


func refresh_skill_hud() -> void:
	_hud_needs_refresh = true


func _setup_skill_hud() -> void:
	if active_skill_strip_host == null:
		return
	if active_skill_slot_scene == null:
		push_warning("[HUD] active_skill_slot_scene is not assigned.")
		return

	for child in active_skill_strip_host.get_children():
		child.queue_free()

	_hud_active_icon_nodes.clear()
	_hud_passive_icon_nodes.clear()
	_hud_passive_signature = ""

	for slot_index in range(4):
		var slot: HudActiveSkillSlot = active_skill_slot_scene.instantiate() as HudActiveSkillSlot
		slot.set_slot_index(slot_index)
		active_skill_strip_host.add_child(slot)
		_hud_active_icon_nodes.append(slot)

	if passive_strip_host != null:
		_hud_passive_strip = passive_strip_host


func _setup_refresh_timer() -> void:
	if _cooldown_refresh_timer == null:
		return
	_cooldown_refresh_timer.wait_time = cooldown_refresh_interval_sec
	_cooldown_refresh_timer.timeout.connect(_refresh_skill_hud_if_needed)


func _connect_skill_tree_signals() -> void:
	var manager: Node = SkillTreeManager
	if manager == null:
		return
	if not manager.sp_changed.is_connected(_on_skill_tree_state_changed):
		manager.sp_changed.connect(_on_skill_tree_state_changed)
	if not manager.skill_invested.is_connected(_on_skill_tree_skill_invested):
		manager.skill_invested.connect(_on_skill_tree_skill_invested)
	if not manager.state_loaded.is_connected(_on_skill_tree_loaded):
		manager.state_loaded.connect(_on_skill_tree_loaded)


func _refresh_skill_hud_if_needed() -> void:
	var manager: Node = SkillTreeManager
	var registry: Node = SkillRegistry
	if manager == null or registry == null or _hud_active_icon_nodes.is_empty():
		return

	var cooldowns_changed := false
	for slot_index in range(_hud_active_icon_nodes.size()):
		var slot_ref: HudActiveSkillSlot = _hud_active_icon_nodes[slot_index]
		var cooldown_remaining := PlayerSkillManager.get_ability_cooldown_remaining(slot_index)
		if slot_ref.set_cooldown(cooldown_remaining):
			cooldowns_changed = true

	if not _hud_needs_refresh and not cooldowns_changed:
		return
	_hud_needs_refresh = false

	for slot_index in range(_hud_active_icon_nodes.size()):
		var slot_ref: HudActiveSkillSlot = _hud_active_icon_nodes[slot_index]
		var skill_id: String = str(manager.call("get_slotted_skill", slot_index))
		if skill_id.is_empty():
			slot_ref.set_empty()
			continue
		slot_ref.set_skill_icon(registry.call("get_skill_icon", skill_id) as Texture2D)

	_refresh_passive_skill_icons(manager, registry)


func _refresh_passive_skill_icons(manager: Node, registry: Node) -> void:
	if _hud_passive_strip == null:
		return
	if passive_skill_icon_scene == null:
		push_warning("[HUD] passive_skill_icon_scene is not assigned.")
		return

	var passive_skill_ids: Array[String] = []
	for skill_id_variant in manager.call("get_learned_skill_ids"):
		var skill_id := str(skill_id_variant)
		var skill = registry.get_skill(skill_id)
		if skill == null:
			continue
		if skill.skill_type == SkillDefinition.SkillType.STAT or skill.skill_type == SkillDefinition.SkillType.PASSIVE:
			passive_skill_ids.append(skill_id)

	passive_skill_ids.sort()
	var signature := "|".join(passive_skill_ids)
	if signature == _hud_passive_signature:
		return
	_hud_passive_signature = signature

	var icon_index := 0
	for skill_id in passive_skill_ids:
		var skill: Resource = registry.get_skill(skill_id)
		var icon_panel := _get_or_create_passive_icon(icon_index)
		if icon_panel == null:
			continue
		icon_panel.visible = true
		icon_panel.configure(skill, registry.call("get_skill_icon", skill_id) as Texture2D, skill_id)
		icon_index += 1

	for hidden_index in range(icon_index, _hud_passive_icon_nodes.size()):
		_hud_passive_icon_nodes[hidden_index].visible = false


func _get_or_create_passive_icon(icon_index: int) -> HudPassiveSkillIcon:
	if icon_index < _hud_passive_icon_nodes.size():
		return _hud_passive_icon_nodes[icon_index]
	if passive_skill_icon_scene == null or _hud_passive_strip == null:
		return null
	var icon_panel: HudPassiveSkillIcon = passive_skill_icon_scene.instantiate() as HudPassiveSkillIcon
	if icon_panel == null:
		return null
	_hud_passive_strip.add_child(icon_panel)
	_hud_passive_icon_nodes.append(icon_panel)
	return icon_panel


func _on_skill_tree_state_changed(_available: int, _total: int) -> void:
	_hud_passive_signature = ""
	_hud_needs_refresh = true


func _on_skill_tree_skill_invested(_skill_id: String, _new_level: int) -> void:
	_hud_passive_signature = ""
	_hud_needs_refresh = true


func _on_skill_tree_loaded(_state: Dictionary) -> void:
	_hud_passive_signature = ""
	_hud_needs_refresh = true
