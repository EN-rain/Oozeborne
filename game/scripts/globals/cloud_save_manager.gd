extends Node

## CloudSaveManager (Custom API Version)
## Custom REST endpoints for cloud saves on /saves

signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool)
signal slots_loaded(slots: Array)

const MAX_SLOTS := 5
const SAVE_VERSION := 1

var _cached_slots: Array = []

func _ready() -> void:
	_cached_slots.resize(MAX_SLOTS)
	for i in range(MAX_SLOTS):
		_cached_slots[i] = {}

func build_save_snapshot(mode: String = "solo") -> Dictionary:
	var tree := get_tree()
	if tree == null: return {}
	var current_scene := tree.current_scene
	if current_scene == null or not current_scene.has_method("build_solo_run_snapshot"):
		return {}
	var snapshot: Dictionary = current_scene.call("build_solo_run_snapshot")
	if snapshot.is_empty(): return {}
	snapshot["version"] = SAVE_VERSION
	snapshot["saved_at"] = Time.get_datetime_string_from_system()
	snapshot["mode"] = mode
	return snapshot

func save_to_slot(slot: int, mode: String = "solo") -> Dictionary:
	if not MultiplayerManager.is_authenticated():
		return {"success": false, "error": "Not authenticated"}

	var snapshot := build_save_snapshot(mode)
	if snapshot.is_empty(): return {"success": false, "error": "No data"}

	var result = await _http_request("/saves/%d" % slot, HTTPClient.METHOD_POST, JSON.stringify({"data": snapshot}))
	if result.get("success", false):
		_cached_slots[slot - 1] = snapshot
		save_completed.emit(slot, true)
		return {"success": true}
	
	save_completed.emit(slot, false)
	return {"success": false, "error": result.get("error", "Save failed")}

func load_slots() -> Dictionary:
	if not MultiplayerManager.is_authenticated():
		return {"success": false}

	var result = await _http_request("/saves", HTTPClient.METHOD_GET)
	if result.get("success", false):
		# Clear cache
		for i in range(MAX_SLOTS): _cached_slots[i] = {}
		
		# Fill cache
		for s_data in result.slots:
			var slot_idx = int(s_data.slot) - 1
			if slot_idx >= 0 and slot_idx < MAX_SLOTS:
				# Minimal metadata for slot summary
				_cached_slots[slot_idx] = {"slot_name": s_data.slot_name, "saved_at": s_data.saved_at}
		
		slots_loaded.emit(_cached_slots.duplicate())
		return {"success": true, "slots": _cached_slots}
	
	slots_loaded.emit([])
	return {"success": false}

func load_from_slot(slot: int) -> Dictionary:
	if not MultiplayerManager.is_authenticated(): return {"success": false}

	var result = await _http_request("/saves/%d" % slot, HTTPClient.METHOD_GET)
	if result.get("success", false):
		var data = result.data
		_cached_slots[slot - 1] = data
		_apply_snapshot(data)
		load_completed.emit(slot, true)
		return {"success": true, "data": data}

	load_completed.emit(slot, false)
	return {"success": false}

func delete_slot(slot: int) -> Dictionary:
	var result = await _http_request("/saves/%d" % slot, HTTPClient.METHOD_DELETE)
	if result.get("success", false):
		_cached_slots[slot - 1] = {}
		return {"success": true}
	return {"success": false}

# --- Internal Helpers ---

func _http_request(path: String, method: int, body: String = ""):
	# Delegate to MultiplayerManager for auth-aware HTTP requests
	return await MultiplayerManager._http_request(path, method, body)

func _apply_snapshot(snapshot: Dictionary) -> void:
	if snapshot.is_empty(): return
	var class_id := str(snapshot.get("player_class_id", ""))
	if not class_id.is_empty() and ClassManager != null:
		MultiplayerManager.player_class = ClassManager.create_class_instance(class_id)
	
	MultiplayerManager.player_level = int(snapshot.get("player_level", 1))
	if snapshot.has("skill_tree_state") and SkillTreeManager != null:
		SkillTreeManager.load_state(snapshot.get("skill_tree_state", {}))
	if CoinManager != null and CoinManager.has_method("set_coins"):
		CoinManager.set_coins(int(snapshot.get("coins", 0)))

func get_slot_summary(slot: int) -> Dictionary:
	if slot < 1 or slot > MAX_SLOTS: return {}
	var data = _cached_slots[slot - 1]
	if data.is_empty(): return {}
	return {
		"slot": slot,
		"slot_name": str(data.get("slot_name", "Slot %d" % slot)),
		"saved_at": str(data.get("saved_at", ""))
	}
