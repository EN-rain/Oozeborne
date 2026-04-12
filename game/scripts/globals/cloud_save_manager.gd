extends Node

## CloudSaveManager - 5 cloud save slots per player (solo + multiplayer)
## All saves stored on Nakama. Each slot has a "mode" field: "solo" or "multiplayer"

signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool)
signal slots_loaded(slots: Array)

const COLLECTION := "game_saves"
const MAX_SLOTS := 5
const SAVE_VERSION := 1

var _cached_slots: Array = []


func _ready() -> void:
	_cached_slots.resize(MAX_SLOTS)
	for i in range(MAX_SLOTS):
		_cached_slots[i] = {}


## Build a save snapshot from the current game scene
func build_save_snapshot(mode: String = "solo") -> Dictionary:
	var tree := get_tree()
	if tree == null:
		return {}
	var current_scene := tree.current_scene
	if current_scene == null or not current_scene.has_method("build_solo_run_snapshot"):
		return {}
	var snapshot: Dictionary = current_scene.call("build_solo_run_snapshot")
	if snapshot.is_empty():
		return {}
	snapshot["version"] = SAVE_VERSION
	snapshot["saved_at"] = Time.get_datetime_string_from_system()
	snapshot["mode"] = mode
	return snapshot


## Rename a save slot (stored in the save data itself)
func rename_slot(slot: int, new_name: String) -> Dictionary:
	if slot < 1 or slot > MAX_SLOTS:
		return {"success": false, "error": "Invalid slot"}
	if not MultiplayerManager.is_authenticated():
		return {"success": false, "error": "Not authenticated"}
	var data: Dictionary = _cached_slots[slot - 1]
	if data.is_empty():
		return {"success": false, "error": "Slot is empty"}
	data["slot_name"] = new_name
	var key := "slot_%d" % slot
	var json_data := JSON.stringify(data)
	var write_obj := NakamaWriteStorageObject.new(COLLECTION, key, 1, 1, json_data, "")
	var client := _get_client()
	if client == null:
		return {"success": false, "error": "No server connection"}
	var result = await client.write_storage_objects_async(MultiplayerManager.session, [write_obj])
	if result == null or result.is_exception():
		return {"success": false, "error": "Failed to rename"}
	return {"success": true, "error": ""}


## Save current game state to a specific slot (1-5)
func save_to_slot(slot: int, mode: String = "solo") -> Dictionary:
	if slot < 1 or slot > MAX_SLOTS:
		return {"success": false, "error": "Invalid slot (1-%d)" % MAX_SLOTS}
	if not MultiplayerManager.is_authenticated():
		return {"success": false, "error": "Not authenticated"}

	var snapshot := build_save_snapshot(mode)
	if snapshot.is_empty():
		return {"success": false, "error": "No game data to save"}

	var key := "slot_%d" % slot
	var json_data := JSON.stringify(snapshot)

	var write_obj := NakamaWriteStorageObject.new(
		COLLECTION,
		key,
		1,  # permission_read: owner only
		1,  # permission_write: owner only
		json_data,
		""   # version (empty = create/overwrite)
	)

	var client := _get_client()
	if client == null:
		return {"success": false, "error": "No server connection"}

	var result = await client.write_storage_objects_async(MultiplayerManager.session, [write_obj])
	if result == null or result.is_exception():
		var err_msg := "Server write failed"
		if result != null:
			err_msg = result.get_exception().message
		save_completed.emit(slot, false)
		return {"success": false, "error": err_msg}

	# Update cache
	_cached_slots[slot - 1] = snapshot
	save_completed.emit(slot, true)
	return {"success": true, "error": ""}


## Load all save slot metadata from Nakama storage
func load_slots() -> Dictionary:
	if not MultiplayerManager.is_authenticated():
		return {"success": false, "error": "Not authenticated"}

	var client := _get_client()
	if client == null:
		return {"success": false, "error": "No server connection"}

	var user_id := MultiplayerManager.session.user_id if MultiplayerManager.session != null else ""
	var result = await client.list_storage_objects_async(MultiplayerManager.session, COLLECTION, user_id, MAX_SLOTS)

	if result == null or result.is_exception():
		slots_loaded.emit([])
		return {"success": false, "error": "Failed to load slots"}

	# Clear cache
	for i in range(MAX_SLOTS):
		_cached_slots[i] = {}

	# Parse results
	if result.objects != null:
		for obj in result.objects:
			var key: String = obj.key
			if key.begins_with("slot_"):
				var slot_num := key.substr(5).to_int()
				if slot_num >= 1 and slot_num <= MAX_SLOTS:
					var parsed = JSON.parse_string(obj.value)
					if parsed is Dictionary:
						_cached_slots[slot_num - 1] = parsed

	slots_loaded.emit(_cached_slots.duplicate())
	return {"success": true, "error": "", "slots": _cached_slots.duplicate()}


## Load save data from a specific slot
func load_from_slot(slot: int) -> Dictionary:
	if slot < 1 or slot > MAX_SLOTS:
		return {"success": false, "error": "Invalid slot"}
	if not MultiplayerManager.is_authenticated():
		return {"success": false, "error": "Not authenticated"}

	# Try cache first
	var cached: Dictionary = _cached_slots[slot - 1]
	if not cached.is_empty():
		_apply_snapshot(cached)
		load_completed.emit(slot, true)
		return {"success": true, "error": "", "data": cached}

	# Fetch from server
	var client := _get_client()
	if client == null:
		return {"success": false, "error": "No server connection"}

	var key := "slot_%d" % slot
	var read_id := NakamaStorageObjectId.new(COLLECTION, key, MultiplayerManager.session.user_id)
	var result = await client.read_storage_objects_async(MultiplayerManager.session, [read_id])

	if result == null or result.is_exception():
		load_completed.emit(slot, false)
		return {"success": false, "error": "Failed to read slot"}

	if result.objects == null or result.objects.is_empty():
		load_completed.emit(slot, false)
		return {"success": false, "error": "Slot is empty"}

	var obj = result.objects[0]
	var parsed = JSON.parse_string(obj.value)
	if not parsed is Dictionary:
		load_completed.emit(slot, false)
		return {"success": false, "error": "Invalid save data"}

	_cached_slots[slot - 1] = parsed
	_apply_snapshot(parsed)
	load_completed.emit(slot, true)
	return {"success": true, "error": "", "data": parsed}


## Delete a save slot
func delete_slot(slot: int) -> Dictionary:
	if slot < 1 or slot > MAX_SLOTS:
		return {"success": false, "error": "Invalid slot"}
	if not MultiplayerManager.is_authenticated():
		return {"success": false, "error": "Not authenticated"}

	var client := _get_client()
	if client == null:
		return {"success": false, "error": "No server connection"}

	var key := "slot_%d" % slot
	var delete_id := NakamaStorageObjectId.new(COLLECTION, key)
	var result = await client.delete_storage_objects_async(MultiplayerManager.session, [delete_id])

	if result != null and result.is_exception():
		return {"success": false, "error": "Failed to delete slot"}

	_cached_slots[slot - 1] = {}
	return {"success": true, "error": ""}


## Find the first empty slot (1-5), returns 0 if all full
func find_empty_slot() -> int:
	for i in range(MAX_SLOTS):
		if _cached_slots[i].is_empty():
			return i + 1
	return 0


## Auto-save to the first available slot
func auto_save(mode: String = "solo") -> Dictionary:
	var slot := find_empty_slot()
	if slot == 0:
		return {"success": false, "error": "All 5 save slots are full. Delete one first.", "slot": 0}
	var result := await save_to_slot(slot, mode)
	result["slot"] = slot
	return result


## Check if any slot has a save
func has_any_save() -> bool:
	for i in range(MAX_SLOTS):
		if not _cached_slots[i].is_empty():
			return true
	return false


## Get cached slot summary for UI display
func get_slot_summary(slot: int) -> Dictionary:
	if slot < 1 or slot > MAX_SLOTS:
		return {}
	var data: Dictionary = _cached_slots[slot - 1]
	if data.is_empty():
		return {}
	return {
		"slot": slot,
		"slot_name": str(data.get("slot_name", "Slot %d" % slot)),
		"mode": str(data.get("mode", "solo")),
		"class_name": str(data.get("player_class_name", "—")),
		"level": int(data.get("player_level", 1)),
		"round": int(data.get("round", 1)),
		"coins": int(data.get("coins", 0)),
		"saved_at": str(data.get("saved_at", "")),
	}


## Get all slot summaries
func get_all_slot_summaries() -> Array:
	var summaries := []
	for i in range(MAX_SLOTS):
		summaries.append(get_slot_summary(i + 1))
	return summaries


## Apply loaded snapshot to game globals
func _apply_snapshot(snapshot: Dictionary) -> void:
	var class_id := str(snapshot.get("player_class_id", ""))
	if not class_id.is_empty():
		MultiplayerManager.player_class = ClassManager.create_class_instance(class_id)
	var subclass_id := str(snapshot.get("player_subclass_id", ""))
	MultiplayerManager.player_subclass = ClassManager.create_class_instance(subclass_id) if not subclass_id.is_empty() else null
	MultiplayerManager.subclass_choice_made = bool(snapshot.get("subclass_choice_made", false))
	MultiplayerManager.player_level = int(snapshot.get("player_level", 1))
	if snapshot.has("skill_tree_state"):
		SkillTreeManager.load_state(snapshot.get("skill_tree_state", {}))
	if CoinManager != null and CoinManager.has_method("set_coins"):
		CoinManager.set_coins(int(snapshot.get("coins", 0)))


func _get_client() -> NakamaClient:
	if MultiplayerManager.client != null:
		return MultiplayerManager.client
	return null
