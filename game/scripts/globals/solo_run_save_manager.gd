extends Node

const SAVE_PATH := "user://solo_run_save.json"
const SAVE_VERSION := 1

var _pending_continue_snapshot: Dictionary = {}


func has_saved_run() -> bool:
	return not _read_saved_run().is_empty()


func clear_saved_run() -> void:
	_pending_continue_snapshot.clear()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func save_current_run_from_scene(scene_root: Node) -> bool:
	if scene_root == null or not is_instance_valid(scene_root):
		return false
	if not scene_root.has_method("build_solo_run_snapshot"):
		return false
	var snapshot: Dictionary = scene_root.call("build_solo_run_snapshot")
	if snapshot.is_empty():
		return false
	snapshot["version"] = SAVE_VERSION
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(snapshot))
	return true


func prepare_continue_run() -> bool:
	var snapshot := _read_saved_run()
	if snapshot.is_empty():
		return false
	_apply_snapshot_to_globals(snapshot)
	_pending_continue_snapshot = snapshot.duplicate(true)
	return true


func consume_pending_continue_snapshot() -> Dictionary:
	var snapshot := _pending_continue_snapshot.duplicate(true)
	_pending_continue_snapshot.clear()
	return snapshot


func get_saved_run_summary() -> Dictionary:
	var snapshot := _read_saved_run()
	if snapshot.is_empty():
		return {}
	return {
		"round": int(snapshot.get("round", 1)),
		"level": int(snapshot.get("player_level", 1)),
		"class_name": str(snapshot.get("player_class_name", "Solo Run")),
	}


func _read_saved_run() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _apply_snapshot_to_globals(snapshot: Dictionary) -> void:
	MultiplayerManager.player_class = _resolve_class_instance(str(snapshot.get("player_class_id", "")))
	MultiplayerManager.player_subclass = _resolve_class_instance(str(snapshot.get("player_subclass_id", "")))
	MultiplayerManager.subclass_choice_made = bool(snapshot.get("subclass_choice_made", false))
	MultiplayerManager.player_level = int(snapshot.get("player_level", 1))


func _resolve_class_instance(class_id: String) -> PlayerClass:
	if class_id.is_empty():
		return null
	return ClassManager.create_class_instance(class_id)
