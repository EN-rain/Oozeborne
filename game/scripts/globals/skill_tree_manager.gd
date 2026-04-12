extends Node
class_name SkillTreeManagerService

const SkillTreePassiveEffectScript := preload("res://scripts/effects/buffs/skill_tree_passive_effect.gd")

const MAX_SP := 250
const SUBCLASS_UNLOCK_SP := 20
const SUBCLASS_SP_CAP := 30
const ACTION_BAR_SIZE := 4
const STATE_VERSION := 1
const PROPERTY_TARGETS := {
	"max_health": true,
	"speed": true,
	"attack_damage": true,
}

signal sp_changed(sp_available: int, total_sp_earned: int)
signal skill_invested(skill_id: String, new_level: int)
signal subclasses_unlocked(main_class: String)
signal subclass_locked(subclass_key: String, reason: String)
signal insufficient_sp(required: int, available: int)
signal skill_not_learned(skill_id: String)
signal state_loaded(state: Dictionary)

var _state: Dictionary = {}
var _local_player: Node = null
var _local_player_entity_id: int = 0
var _passive_effects: Dictionary = {}
var _stat_broadcast_timer: Timer
var _pending_stat_broadcast: bool = false


func _ready() -> void:
	_state = _default_state()
	_stat_broadcast_timer = Timer.new()
	_stat_broadcast_timer.one_shot = true
	_stat_broadcast_timer.wait_time = 0.5
	_stat_broadcast_timer.timeout.connect(_on_stat_broadcast_timeout)
	add_child(_stat_broadcast_timer)

	if not LevelSystem.level_up.is_connected(_on_level_up):
		LevelSystem.level_up.connect(_on_level_up)
	if not LevelSystem.stats_updated.is_connected(_on_stats_updated):
		LevelSystem.stats_updated.connect(_on_stats_updated)

	call_deferred("_sync_local_player_ref")


func _exit_tree() -> void:
	if LevelSystem.level_up.is_connected(_on_level_up):
		LevelSystem.level_up.disconnect(_on_level_up)
	if LevelSystem.stats_updated.is_connected(_on_stats_updated):
		LevelSystem.stats_updated.disconnect(_on_stats_updated)
	if _local_player != null and is_instance_valid(_local_player):
		_remove_all_passives(_local_player)


func get_skill_level(skill_id: String) -> int:
	return int(_state.invested.get(skill_id, 0))


func get_sp_available() -> int:
	return int(_state.sp_available)


func get_total_sp_earned() -> int:
	return int(_state.total_sp_earned)


func get_main_tree_sp_spent() -> int:
	return _get_main_tree_sp_spent()


func get_subclass_sp_spent(subclass_key: String) -> int:
	return _get_subclass_sp_spent(subclass_key)


func are_subclasses_unlocked() -> bool:
	return _get_main_tree_sp_spent() >= SUBCLASS_UNLOCK_SP


func is_skill_available_for_slotting(skill_id: String) -> bool:
	return _can_slot_skill(skill_id)


func invest_sp(skill_id: String) -> bool:
	var registry = _registry()
	if registry == null:
		return false

	_sync_local_player_ref()
	var skill = registry.get_skill(skill_id)
	if skill == null:
		return false
	if _state.sp_available < skill.sp_cost_per_level:
		insufficient_sp.emit(skill.sp_cost_per_level, _state.sp_available)
		return false

	var info = registry.get_skill_path_info(skill_id)
	if not _is_skill_compatible(info):
		return false

	var current_level = get_skill_level(skill_id)
	if current_level >= skill.max_level:
		return false

	if _is_subclass_skill(info):
		if _get_main_tree_sp_spent() < SUBCLASS_UNLOCK_SP:
			subclass_locked.emit(str(info.get("tree_key", "")), "main_class_not_maxed")
			return false
		if _get_subclass_sp_spent(str(info.get("tree_key", ""))) >= SUBCLASS_SP_CAP:
			subclass_locked.emit(str(info.get("tree_key", "")), "subclass_cap_reached")
			return false

	_state.invested[skill_id] = current_level + 1
	_state.sp_available -= skill.sp_cost_per_level

	_sync_local_player_ref()
	if _local_player != null and is_instance_valid(_local_player):
		if skill.skill_type == SkillDefinition.SkillType.STAT:
			_apply_stat_skills(_local_player)
		elif skill.skill_type == SkillDefinition.SkillType.PASSIVE:
			_sync_passive_skill(skill_id, current_level + 1, _local_player)

	if _get_main_tree_sp_spent() >= SUBCLASS_UNLOCK_SP and not _state.subclasses_unlock_emitted:
		_state.subclasses_unlock_emitted = true
		subclasses_unlocked.emit(_get_current_main_class_key())

	_refresh_action_bar_registrations()
	sp_changed.emit(_state.sp_available, _state.total_sp_earned)
	skill_invested.emit(skill_id, current_level + 1)
	return true


func slot_ability(slot_index: int, skill_id: String) -> bool:
	var registry = _registry()
	if registry == null:
		return false
	if slot_index < 0 or slot_index >= ACTION_BAR_SIZE:
		skill_not_learned.emit(skill_id)
		return false

	var skill = registry.get_skill(skill_id)
	if skill == null:
		skill_not_learned.emit(skill_id)
		return false
	if skill.skill_type != SkillDefinition.SkillType.ABILITY and skill.skill_type != SkillDefinition.SkillType.SPECIAL:
		skill_not_learned.emit(skill_id)
		return false
	if not _can_slot_skill(skill_id):
		skill_not_learned.emit(skill_id)
		return false

	_state.action_bar[slot_index] = skill_id
	_refresh_action_bar_registrations()
	return true


func get_slotted_skill(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= ACTION_BAR_SIZE:
		return ""
	return str(_state.action_bar[slot_index])


func get_learned_skill_ids() -> PackedStringArray:
	var learned: PackedStringArray = []
	for skill_id in (_state.invested as Dictionary).keys():
		if int(_state.invested[skill_id]) > 0:
			learned.append(str(skill_id))
	learned.sort()
	return learned


func clear_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= ACTION_BAR_SIZE:
		return
	_state.action_bar[slot_index] = ""
	PlayerSkillManager.clear_ability_slot(slot_index)


func save_state() -> Dictionary:
	return {
		"version": STATE_VERSION,
		"invested": (_state.invested as Dictionary).duplicate(true),
		"action_bar": (_state.action_bar as Array).duplicate(),
		"sp_available": _state.sp_available,
		"total_sp_earned": _state.total_sp_earned,
		"subclasses_unlock_emitted": _state.subclasses_unlock_emitted,
	}


func load_state(data: Dictionary) -> void:
	var next_state = _default_state()
	if _is_valid_save_data(data):
		next_state.invested = (data.get("invested", {}) as Dictionary).duplicate(true)
		var saved_bar = data.get("action_bar", []) as Array
		for index in range(min(saved_bar.size(), ACTION_BAR_SIZE)):
			next_state.action_bar[index] = str(saved_bar[index])
		next_state.sp_available = max(0, int(data.get("sp_available", 0)))
		next_state.total_sp_earned = clampi(int(data.get("total_sp_earned", 0)), 0, MAX_SP)
		next_state.subclasses_unlock_emitted = bool(data.get("subclasses_unlock_emitted", false))
	else:
		push_warning("SkillTreeManager.load_state received missing or corrupt data; initializing defaults.")

	_state = next_state
	_sync_local_player_ref()
	state_loaded.emit(save_state())
	sp_changed.emit(_state.sp_available, _state.total_sp_earned)

func reset_run_state() -> void:
	if _local_player != null and is_instance_valid(_local_player):
		_remove_all_passives(_local_player)
	_local_player = null
	_local_player_entity_id = 0
	_passive_effects.clear()
	load_state(_default_state())


func handle_remote_skill_stat_update(user_id: String, stats: Dictionary) -> void:
	if user_id.is_empty() or MultiplayerUtils.is_local_player(user_id):
		return
	if not MultiplayerUtils.has_remote_player(user_id):
		return
	apply_remote_skill_stats(MultiplayerUtils.get_remote_player_node(user_id), stats)


func apply_remote_skill_stats(target_player: Node, stats: Dictionary) -> void:
	if target_player == null or not is_instance_valid(target_player):
		return
	if stats.has("speed") and "speed" in target_player:
		target_player.speed = float(stats["speed"])
	if stats.has("dash_speed") and "dash_speed" in target_player:
		target_player.dash_speed = float(stats["dash_speed"])
	if stats.has("dash_cooldown") and "dash_cooldown" in target_player:
		target_player.dash_cooldown = float(stats["dash_cooldown"])
	if stats.has("attack_damage") and "attack_damage" in target_player:
		target_player.attack_damage = int(stats["attack_damage"])
	if target_player.has_node("Health"):
		var health = target_player.get_node("Health")
		if stats.has("max_health"):
			health.max_health = int(stats["max_health"])
		if stats.has("current_health"):
			health.current_health = min(int(stats["current_health"]), int(health.max_health))
			if health.has_signal("health_changed"):
				health.health_changed.emit(health.current_health, health.max_health)
	if stats.has("meta"):
		for key in (stats["meta"] as Dictionary).keys():
			target_player.set_meta(str(key), stats["meta"][key])
	var mana_node = target_player.get_node_or_null("Mana")
	if mana_node != null:
		if stats.has("max_mana"):
			mana_node.set_max_mana(int(stats["max_mana"]))
		if stats.has("current_mana"):
			mana_node.current_mana = mini(int(stats["current_mana"]), mana_node.max_mana)
			mana_node.mana_changed.emit(mana_node.current_mana, mana_node.max_mana)
		if stats.has("mana_regen_bonus"):
			mana_node.mana_regen_bonus = float(stats["mana_regen_bonus"])


func _on_level_up(entity_id: int, new_level: int, _stats: Dictionary) -> void:
	_sync_local_player_ref()
	if entity_id != _local_player_entity_id:
		return
	_sync_sp_from_level(new_level)


func _on_stats_updated(entity_id: int, _stats: Dictionary) -> void:
	_sync_local_player_ref()
	if entity_id != _local_player_entity_id:
		return
	if _local_player != null and is_instance_valid(_local_player):
		_sync_sp_from_level(LevelSystem.get_level(_local_player))
	if _local_player != null and is_instance_valid(_local_player):
		_apply_stat_skills(_local_player)


func _apply_stat_skills(player: Node) -> void:
	var registry = _registry()
	if player == null or not is_instance_valid(player) or registry == null:
		return

	var base_stats = LevelSystem.get_current_stats(player)
	if player.has_method("reapply_class_modifiers_after_level_sync"):
		player.reapply_class_modifiers_after_level_sync(base_stats)

	var property_percent_bonuses = {"max_health": 0.0, "speed": 0.0, "attack_damage": 0.0, "max_mana": 0.0, "hp_regen": 0.0}
	var property_flat_bonuses = {"max_health": 0.0, "speed": 0.0, "attack_damage": 0.0, "max_mana": 0.0, "hp_regen": 0.0}
	var meta_totals: Dictionary = {}

	for skill_id in (_state.invested as Dictionary).keys():
		var level = int(_state.invested[skill_id])
		if level <= 0:
			continue
		var skill = registry.get_skill(str(skill_id))
		if skill == null or skill.skill_type != SkillDefinition.SkillType.STAT:
			continue
		var rule: Dictionary = SkillTreeRuntimeData.STAT_RULES.get(skill_id, {})
		_accumulate_rule(rule, level, property_percent_bonuses, property_flat_bonuses, meta_totals)

	_apply_property_bonus(player, "speed", property_percent_bonuses, property_flat_bonuses)
	_apply_property_bonus(player, "attack_damage", property_percent_bonuses, property_flat_bonuses)
	_apply_health_bonus(player, property_percent_bonuses, property_flat_bonuses, meta_totals)
	_apply_mana_bonus(player, property_percent_bonuses, property_flat_bonuses, meta_totals)
	_apply_meta_totals(player, meta_totals)
	_queue_stat_broadcast()


func _sync_passive_skill(skill_id: String, level: int, player: Node) -> void:
	var rule: Dictionary = SkillTreeRuntimeData.PASSIVE_RULES.get(skill_id, {})
	if rule.is_empty():
		return
	var effect = _passive_effects.get(skill_id, null)
	var target_key = str(rule.get("target", ""))
	var magnitude = float(rule.get("value", 0.0)) * level
	if effect == null or not is_instance_valid(effect):
		effect = SkillTreePassiveEffectScript.new()
		effect.effect_name = "skill_tree_%s" % skill_id
		effect.meta_target = target_key
		effect.set_magnitude(magnitude)
		StatusEffectManager.apply_effect(player, effect)
		_passive_effects[skill_id] = effect
	else:
		effect.set_magnitude(magnitude)
		player.set_meta(target_key, magnitude)
	_queue_stat_broadcast()


func _remove_all_passives(player: Node) -> void:
	if player == null or not is_instance_valid(player):
		return
	for skill_id in _passive_effects.keys():
		var effect = _passive_effects[skill_id]
		if effect != null and is_instance_valid(effect):
			StatusEffectManager.remove_effect(player, effect.effect_name)
	_passive_effects.clear()


func _sync_local_player_ref() -> void:
	var registry = _registry()
	var next_player = _resolve_local_player()
	if next_player == _local_player and is_instance_valid(_local_player):
		return
	if _local_player != null and is_instance_valid(_local_player):
		_remove_all_passives(_local_player)
	_local_player = next_player
	_local_player_entity_id = _local_player.get_instance_id() if _local_player != null and is_instance_valid(_local_player) else 0
	if _local_player == null or not is_instance_valid(_local_player):
		return
	_sync_sp_from_level(LevelSystem.get_level(_local_player))
	_apply_stat_skills(_local_player)
	if registry != null:
		for skill_id in (_state.invested as Dictionary).keys():
			var level = int(_state.invested[skill_id])
			var skill = registry.get_skill(str(skill_id))
			if skill != null and skill.skill_type == SkillDefinition.SkillType.PASSIVE and level > 0:
				_sync_passive_skill(str(skill_id), level, _local_player)
	_refresh_action_bar_registrations()


func _refresh_action_bar_registrations() -> void:
	for index in range(ACTION_BAR_SIZE):
		PlayerSkillManager.clear_ability_slot(index)
	for index in range(ACTION_BAR_SIZE):
		var skill_id = get_slotted_skill(index)
		if skill_id.is_empty():
			continue
		PlayerSkillManager.register_ability_slot(index, skill_id, float(SkillTreeRuntimeData.ABILITY_COOLDOWNS.get(skill_id, 0.0)))


func _can_slot_skill(skill_id: String) -> bool:
	var registry = _registry()
	if registry == null:
		return false
	var skill = registry.get_skill(skill_id)
	if skill == null:
		return false
	if skill.skill_type == SkillDefinition.SkillType.SPECIAL:
		var info = registry.get_skill_path_info(skill_id)
		if str(info.get("tree_key", "")) == "main" and str(info.get("main_class", "")) == _get_current_main_class_key():
			return true
	return get_skill_level(skill_id) > 0


func _is_skill_compatible(info: Dictionary) -> bool:
	var current_main = _get_current_main_class_key()
	return not current_main.is_empty() and str(info.get("main_class", "")) == current_main


func _is_subclass_skill(info: Dictionary) -> bool:
	return str(info.get("tree_key", "")) != "main"


func _get_main_tree_sp_spent() -> int:
	var registry = _registry()
	if registry == null:
		return 0
	var current_main = _get_current_main_class_key()
	var total = 0
	for skill_id in (_state.invested as Dictionary).keys():
		var info = registry.get_skill_path_info(str(skill_id))
		if str(info.get("main_class", "")) == current_main and str(info.get("tree_key", "")) == "main":
			total += int(_state.invested[skill_id])
	return total


func _get_subclass_sp_spent(subclass_key: String) -> int:
	var registry = _registry()
	if registry == null:
		return 0
	var total = 0
	for skill_id in (_state.invested as Dictionary).keys():
		var info = registry.get_skill_path_info(str(skill_id))
		if str(info.get("tree_key", "")) == subclass_key:
			total += int(_state.invested[skill_id])
	return total


func _resolve_local_player() -> Node:
	for entry in LevelSystem.player_data.values():
		var player = entry.get("player_ref", null)
		if player != null and is_instance_valid(player) and ("is_local_player" in player and player.is_local_player):
			return player
	var current_scene = get_tree().current_scene
	return current_scene.find_child("Player", true, false) if current_scene != null else null


func _get_current_main_class_key() -> String:
	return ClassManager.get_class_id(MultiplayerManager.player_class) if MultiplayerManager.player_class != null else ""


func _calculate_total_sp_for_level(level: int) -> int:
	var resolved_level = max(level, 0)
	var bonus_steps = int(floor(float(resolved_level) / 10.0))
	return mini((resolved_level * 2) + (bonus_steps * 5), MAX_SP)


func _sync_sp_from_level(level: int) -> bool:
	var expected_total: int = _calculate_total_sp_for_level(level)
	var spent_total: int = _calculate_total_sp_spent()
	var next_available: int = clampi(expected_total - spent_total, 0, MAX_SP)
	if expected_total == int(_state.total_sp_earned) and next_available == int(_state.sp_available):
		return false
	_state.total_sp_earned = expected_total
	_state.sp_available = next_available
	sp_changed.emit(_state.sp_available, _state.total_sp_earned)
	return true


func _calculate_total_sp_spent() -> int:
	var registry = _registry()
	var total: int = 0
	for skill_id_variant in (_state.invested as Dictionary).keys():
		var skill_id: String = str(skill_id_variant)
		var level: int = int(_state.invested[skill_id_variant])
		if level <= 0:
			continue
		var per_level_cost: int = 1
		if registry != null:
			var skill = registry.get_skill(skill_id)
			if skill != null:
				per_level_cost = max(int(skill.sp_cost_per_level), 1)
		total += level * per_level_cost
	return total


func _accumulate_rule(rule: Dictionary, level: int, property_percent_bonuses: Dictionary, property_flat_bonuses: Dictionary, meta_totals: Dictionary) -> void:
	if rule.is_empty():
		return
	var kind = str(rule.get("kind", ""))
	if kind == "meta_multi":
		for entry in rule.get("entries", []):
			_accumulate_rule(entry, level, property_percent_bonuses, property_flat_bonuses, meta_totals)
		return

	var target = str(rule.get("target", ""))
	var amount = float(rule.get("value", 0.0)) * level
	match kind:
		"property_percent":
			property_percent_bonuses[target] = float(property_percent_bonuses.get(target, 0.0)) + amount
		"property_flat":
			property_flat_bonuses[target] = float(property_flat_bonuses.get(target, 0.0)) + amount
		"meta_percent", "meta_flat":
			meta_totals[target] = float(meta_totals.get(target, 0.0)) + amount


func _apply_property_bonus(player: Node, property_name: String, property_percent_bonuses: Dictionary, property_flat_bonuses: Dictionary) -> void:
	if not PROPERTY_TARGETS.has(property_name) or not (property_name in player):
		return
	var base_value = float(player.get(property_name))
	var next_value = base_value * (1.0 + float(property_percent_bonuses.get(property_name, 0.0))) + float(property_flat_bonuses.get(property_name, 0.0))
	if property_name == "attack_damage":
		player.set(property_name, int(round(next_value)))
	else:
		player.set(property_name, next_value)


func _apply_health_bonus(player: Node, property_percent_bonuses: Dictionary, property_flat_bonuses: Dictionary, meta_totals: Dictionary = {}) -> void:
	if not player.has_node("Health"):
		return
	var health = player.get_node("Health")
	var base_max = float(health.max_health)
	var ratio = float(health.current_health) / float(max(int(base_max), 1))
	var next_max = int(round(base_max * (1.0 + float(property_percent_bonuses.get("max_health", 0.0))) + float(property_flat_bonuses.get("max_health", 0.0))))
	health.max_health = max(next_max, 1)
	health.current_health = int(round(health.max_health * clampf(ratio, 0.0, 1.0)))
	# Apply hp_regen from flat bonuses
	var hp_regen_flat = float(property_flat_bonuses.get("hp_regen", 0.0))
	if hp_regen_flat > 0.0:
		health.hp_regen_bonus += hp_regen_flat
	# Apply hp_regen_bonus from meta_totals
	var hp_regen_meta = float(meta_totals.get("hp_regen_bonus", 0.0))
	if hp_regen_meta > 0.0:
		health.hp_regen_bonus += hp_regen_meta
	if health.has_signal("health_changed"):
		health.health_changed.emit(health.current_health, health.max_health)


func _apply_mana_bonus(player: Node, property_percent_bonuses: Dictionary, property_flat_bonuses: Dictionary, meta_totals: Dictionary) -> void:
	var mana_node = player.get_node_or_null("Mana")
	if mana_node == null:
		return
	# Apply percent/flat bonuses to max_mana
	var base_max = float(mana_node.max_mana)
	var percent_bonus = float(property_percent_bonuses.get("max_mana", 0.0))
	var flat_bonus = float(property_flat_bonuses.get("max_mana", 0.0))
	if percent_bonus != 0.0 or flat_bonus != 0.0:
		var next_max = int(round(base_max * (1.0 + percent_bonus) + flat_bonus))
		mana_node.set_max_mana(maxi(next_max, 0))
	# Apply mana_bonus from meta_totals (e.g. mage focus skill)
	var mana_flat = float(meta_totals.get("mana_bonus", 0.0))
	if mana_flat > 0.0:
		mana_node.set_max_mana(maxi(mana_node.max_mana + int(round(mana_flat)), 0))
	# Apply mana_regen from meta_totals
	var regen_bonus = float(meta_totals.get("mana_regen", 0.0))
	mana_node.mana_regen_bonus += regen_bonus


func _apply_meta_totals(player: Node, meta_totals: Dictionary) -> void:
	var all_targets: Dictionary = {}
	for rule in SkillTreeRuntimeData.STAT_RULES.values():
		_collect_rule_targets(rule, all_targets)
	for target in all_targets.keys():
		player.set_meta(str(target), float(meta_totals.get(target, 0.0)))


func _collect_rule_targets(rule: Dictionary, targets: Dictionary) -> void:
	var kind = str(rule.get("kind", ""))
	if kind == "meta_multi":
		for entry in rule.get("entries", []):
			_collect_rule_targets(entry, targets)
	elif kind.begins_with("meta_"):
		targets[str(rule.get("target", ""))] = true


func _queue_stat_broadcast() -> void:
	_pending_stat_broadcast = true
	if _stat_broadcast_timer.is_stopped():
		_stat_broadcast_timer.start()


func _on_stat_broadcast_timeout() -> void:
	if not _pending_stat_broadcast:
		return
	_pending_stat_broadcast = false
	_sync_local_player_ref()
	if _local_player == null or not is_instance_valid(_local_player):
		return
	if not MultiplayerManager.is_socket_open() or MultiplayerManager.match_id.is_empty():
		return
	NetworkMessaging.send_skill_stat_update(_build_derived_stat_payload(_local_player))


func _build_derived_stat_payload(player: Node) -> Dictionary:
	var payload = {
		"speed": float(player.get("speed")) if "speed" in player else 0.0,
		"dash_speed": float(player.get("dash_speed")) if "dash_speed" in player else 0.0,
		"dash_cooldown": float(player.get("dash_cooldown")) if "dash_cooldown" in player else 0.0,
		"attack_damage": int(player.get("attack_damage")) if "attack_damage" in player else 0,
		"meta": {},
	}
	if player.has_node("Health"):
		var health = player.get_node("Health")
		payload["max_health"] = int(health.max_health)
		payload["current_health"] = int(health.current_health)
		payload["hp_regen"] = float(health.hp_regen + health.hp_regen_bonus)
	var mana_node = player.get_node_or_null("Mana")
	if mana_node != null:
		payload["max_mana"] = int(mana_node.max_mana)
		payload["current_mana"] = int(mana_node.current_mana)
		payload["mana_regen_bonus"] = float(mana_node.mana_regen_bonus)
	for rule in SkillTreeRuntimeData.STAT_RULES.values():
		_append_meta_from_rule(payload["meta"], rule, player)
	for rule in SkillTreeRuntimeData.PASSIVE_RULES.values():
		var target = str(rule.get("target", ""))
		if not target.is_empty():
			payload["meta"][target] = player.get_meta(target, 0.0)
	return payload


func _append_meta_from_rule(meta_payload: Dictionary, rule: Dictionary, player: Node) -> void:
	var kind = str(rule.get("kind", ""))
	if kind == "meta_multi":
		for entry in rule.get("entries", []):
			_append_meta_from_rule(meta_payload, entry, player)
	elif kind.begins_with("meta_"):
		var target = str(rule.get("target", ""))
		if not target.is_empty():
			meta_payload[target] = player.get_meta(target, 0.0)


func _default_state() -> Dictionary:
	return {
		"invested": {},
		"action_bar": ["", "", "", ""],
		"sp_available": 0,
		"total_sp_earned": 0,
		"subclasses_unlock_emitted": false,
	}


func _is_valid_save_data(data: Dictionary) -> bool:
	return data.has("invested") and data.has("action_bar") and data.has("sp_available") and data.has("total_sp_earned")


func _registry():
	return get_tree().root.get_node_or_null("SkillRegistry")
