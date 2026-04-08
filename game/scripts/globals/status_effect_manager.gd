extends Node

## StatusEffectManager - Singleton that manages active status effects on all entities
## Add to AutoLoad as "StatusEffectManager"

signal effect_added(entity_id: int, effect_name: String, is_debuff: bool)
signal effect_removed(entity_id: int, effect_name: String, is_debuff: bool)

# Dictionary: entity_id -> { effect_name -> StatusEffect }
var active_effects: Dictionary = {}


func _process(delta: float) -> void:
	# Tick all active effects
	for entity_id in active_effects.keys():
		var entity_effects = active_effects[entity_id]
		for effect_name in entity_effects.keys():
			var effect = entity_effects[effect_name]
			if effect and is_instance_valid(effect):
				effect.tick(delta)
				if not effect.is_active:
					_remove_effect(entity_id, effect_name)


## Apply a new status effect to an entity
func apply_effect(target: Node, effect: StatusEffect) -> void:
	if target == null:
		effect.queue_free()
		return
	
	var entity_id = target.get_instance_id()
	var effect_key = effect.effect_name
	
	# Initialize entity's effect dict if needed
	if not active_effects.has(entity_id):
		active_effects[entity_id] = {}
	
	# If effect already exists, refresh it
	if active_effects[entity_id].has(effect_key):
		active_effects[entity_id][effect_key].refresh()
		effect.queue_free()
		return
	
	# Apply the effect
	effect.apply(target)
	active_effects[entity_id][effect_key] = effect
	_show_effect_popup(target, effect)
	
	effect_added.emit(entity_id, effect_key, effect.is_debuff)
	print("[StatusEffectManager] Applied %s to entity %d" % [effect_key, entity_id])


## Check if an entity has a specific effect
func has_effect(target: Node, effect_name: String) -> bool:
	if target == null:
		return false
	var entity_id = target.get_instance_id()
	return active_effects.has(entity_id) and active_effects[entity_id].has(effect_name)


## Get remaining time for an effect on an entity
func get_remaining_time(target: Node, effect_name: String) -> float:
	if target == null:
		return 0.0
	var entity_id = target.get_instance_id()
	if not active_effects.has(entity_id) or not active_effects[entity_id].has(effect_name):
		return 0.0
	return active_effects[entity_id][effect_name].time_remaining


## Remove a specific effect from an entity
func remove_effect(target: Node, effect_name: String) -> void:
	if target == null:
		return
	var entity_id = target.get_instance_id()
	_remove_effect(entity_id, effect_name)


## Remove all effects from an entity
func remove_all_effects(target: Node) -> void:
	if target == null:
		return
	var entity_id = target.get_instance_id()
	if active_effects.has(entity_id):
		for effect_key in active_effects[entity_id].keys():
			_remove_effect(entity_id, effect_key)


## Clean up effects when entity is freed
func on_entity_freed(entity_id: int) -> void:
	if active_effects.has(entity_id):
		for effect_key in active_effects[entity_id].keys():
			var effect = active_effects[entity_id][effect_key]
			if is_instance_valid(effect):
				effect.queue_free()
		active_effects.erase(entity_id)


func _remove_effect(entity_id: int, effect_name: String) -> void:
	if not active_effects.has(entity_id):
		return
	if not active_effects[entity_id].has(effect_name):
		return
	
	var effect = active_effects[entity_id][effect_name]
	if is_instance_valid(effect):
		effect.remove()
		effect.queue_free()
	
	active_effects[entity_id].erase(effect_name)
	effect_removed.emit(entity_id, effect_name, true)


func _show_effect_popup(target: Node, effect: StatusEffect) -> void:
	if effect == null or not effect.show_apply_popup:
		return
	if not is_instance_valid(target):
		return
	if not (target is Node2D):
		return

	var world_target := target as Node2D
	var popup_text := effect.popup_text.strip_edges()
	if popup_text.is_empty():
		popup_text = _derive_popup_text(effect.effect_name, effect.is_debuff)

	if popup_text.is_empty():
		return

	var popup_position := world_target.global_position + Vector2(0, -38)
	DamageNumbers.spawn_custom(popup_position, popup_text, effect.popup_color, 14)


func _derive_popup_text(effect_name: String, is_debuff: bool) -> String:
	var normalized := effect_name.strip_edges().to_lower()
	match normalized:
		"slow":
			return "Slowed"
		"poison":
			return "Poisoned"
		"bleed":
			return "Bleeding"
		"stun":
			return "Stunned"
		"weakness":
			return "Weakened"
		"vulnerability":
			return "Vulnerable"
		"curse":
			return "Cursed"
		"blind":
			return "Blinded"

	if normalized.is_empty():
		return ""

	var words: PackedStringArray = normalized.replace("_", " ").split(" ", false)
	var titled_words: Array[String] = []
	for word in words:
		if word.is_empty():
			continue
		titled_words.append(word.substr(0, 1).to_upper() + word.substr(1))

	var base_text := " ".join(titled_words)
	if is_debuff:
		return base_text
	return "+" + base_text
