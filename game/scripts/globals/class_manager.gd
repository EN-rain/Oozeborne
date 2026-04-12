extends Node

## ClassManager - Global autoload for managing player classes and subclasses
## Main classes: tank, dps, support, hybrid, controller

const REQUIRED_MAIN_CLASS_COUNT := 5

@export_group("Main Classes")
@export var tank_class_script: Script
@export var dps_class_script: Script
@export var support_class_script: Script
@export var hybrid_class_script: Script
@export var controller_class_script: Script

@export_group("Tank Subclasses")
@export var guardian_class_script: Script
@export var berserker_class_script: Script
@export var paladin_class_script: Script

@export_group("DPS Subclasses")
@export var assassin_class_script: Script
@export var ranger_class_script: Script
@export var mage_class_script: Script
@export var samurai_class_script: Script

@export_group("Support Subclasses")
@export var cleric_class_script: Script
@export var bard_class_script: Script
@export var alchemist_class_script: Script
@export var necromancer_class_script: Script

@export_group("Hybrid Subclasses")
@export var spellblade_class_script: Script
@export var shadow_knight_class_script: Script
@export var monk_class_script: Script

@export_group("Controller Subclasses")
@export var chronomancer_class_script: Script
@export var warden_class_script: Script
@export var hexbinder_class_script: Script
@export var stormcaller_class_script: Script

const MAIN_CLASS_IDS: Array[String] = [
	"tank",
	"dps",
	"support",
	"hybrid",
	"controller"
]

const SUBCLASS_IDS: Array[String] = [
	"guardian",
	"berserker",
	"paladin",
	"assassin",
	"ranger",
	"mage",
	"samurai",
	"cleric",
	"bard",
	"alchemist",
	"necromancer",
	"spellblade",
	"shadow_knight",
	"monk",
	"chronomancer",
	"warden",
	"hexbinder",
	"stormcaller"
]

const TANK_CLASS_IDS: Array[String] = ["tank", "guardian", "berserker", "paladin"]
const DPS_CLASS_IDS: Array[String] = ["dps", "assassin", "ranger", "mage", "samurai"]
const SUPPORT_CLASS_IDS: Array[String] = ["support", "cleric", "bard", "alchemist", "necromancer"]
const HYBRID_CLASS_IDS: Array[String] = ["hybrid", "spellblade", "shadow_knight", "monk"]
const CONTROLLER_CLASS_IDS: Array[String] = ["controller", "chronomancer", "warden", "hexbinder", "stormcaller"]
const CLASS_ICON_ROOT := "res://assets/class_icons"

const MAIN_TO_SUBCLASS_IDS := {
	"tank": ["guardian", "berserker", "paladin"],
	"dps": ["assassin", "ranger", "mage", "samurai"],
	"support": ["cleric", "bard", "alchemist", "necromancer"],
	"hybrid": ["spellblade", "shadow_knight", "monk"],
	"controller": ["chronomancer", "warden", "hexbinder", "stormcaller"]
}
const CLASS_ID_META_KEY := "_class_manager_id"

static var _instance: Node = null
static var _cached_main_classes: Array[PlayerClass] = []
static var _cached_subclasses: Array[PlayerClass] = []
static var _cached_all_classes: Array[PlayerClass] = []
static var _cached_class_map: Dictionary = {}
static var _cached_script_name_to_id: Dictionary = {}
static var _cached_display_name_to_id: Dictionary = {}
static var _is_initialized: bool = false

var _class_scripts: Dictionary = {}


func _ready() -> void:
	_instance = self
	_refresh_registry()


func _refresh_registry() -> void:
	_class_scripts = _build_class_scripts()
	_validate_class_configuration()
	_load_all_classes()
	_is_initialized = true


func _build_class_scripts() -> Dictionary:
	return {
		"tank": tank_class_script,
		"dps": dps_class_script,
		"support": support_class_script,
		"hybrid": hybrid_class_script,
		"controller": controller_class_script,
		"guardian": guardian_class_script,
		"berserker": berserker_class_script,
		"paladin": paladin_class_script,
		"assassin": assassin_class_script,
		"ranger": ranger_class_script,
		"mage": mage_class_script,
		"samurai": samurai_class_script,
		"cleric": cleric_class_script,
		"bard": bard_class_script,
		"alchemist": alchemist_class_script,
		"necromancer": necromancer_class_script,
		"spellblade": spellblade_class_script,
		"shadow_knight": shadow_knight_class_script,
		"monk": monk_class_script,
		"chronomancer": chronomancer_class_script,
		"warden": warden_class_script,
		"hexbinder": hexbinder_class_script,
		"stormcaller": stormcaller_class_script,
	}


func _load_all_classes() -> void:
	_cached_all_classes.clear()
	_cached_main_classes.clear()
	_cached_subclasses.clear()
	_cached_class_map.clear()
	_cached_script_name_to_id.clear()
	_cached_display_name_to_id.clear()

	for class_id in _class_scripts.keys():
		var script = _class_scripts[class_id]
		if script == null:
			continue
		var instance: PlayerClass = script.new()
		_apply_class_identity(instance, class_id)
		_assign_class_icon(instance, class_id)
		_cached_all_classes.append(instance)
		_cached_class_map[class_id] = instance
		var script_name := str(script.get_global_name())
		if not script_name.is_empty():
			_cached_script_name_to_id[script_name] = class_id
		var normalized_display_name := _normalize_display_name(instance.display_name)
		if not normalized_display_name.is_empty():
			_cached_display_name_to_id[normalized_display_name] = class_id

	for class_id in MAIN_CLASS_IDS:
		if _cached_class_map.has(class_id):
			_cached_main_classes.append(_cached_class_map[class_id])

	for class_id in SUBCLASS_IDS:
		if _cached_class_map.has(class_id):
			_cached_subclasses.append(_cached_class_map[class_id])


func _assign_class_icon(instance: PlayerClass, class_id: String) -> void:
	if instance == null or class_id.is_empty():
		return

	var icon_path := "%s/%s/%s_icon.png" % [CLASS_ICON_ROOT, class_id, class_id]
	if not ResourceLoader.exists(icon_path):
		return

	instance.icon = load(icon_path) as Texture2D


static func _initialize() -> void:
	var manager := _get_instance()
	if manager == null:
		push_error("ClassManager singleton is unavailable. Ensure the autoload scene is configured.")
		return
	if _is_initialized:
		return
	manager._refresh_registry()


static func _get_instance() -> Node:
	if _instance != null:
		return _instance
	var main_loop := Engine.get_main_loop()
	if main_loop == null:
		return null
	var tree := main_loop as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("ClassManager")


static func _get_class_scripts() -> Dictionary:
	var manager := _get_instance()
	return manager._class_scripts if manager != null else {}


func get_main_classes() -> Array[PlayerClass]:
	if not _is_initialized:
		_initialize()
	return _cached_main_classes.duplicate()


func get_subclasses() -> Array[PlayerClass]:
	if not _is_initialized:
		_initialize()
	return _cached_subclasses.duplicate()


func get_subclasses_for_main_class(main_class: PlayerClass) -> Array[PlayerClass]:
	if not _is_initialized:
		_initialize()
	if main_class == null:
		return _cached_subclasses.duplicate()

	var class_id := get_class_id(main_class)
	if class_id.is_empty() or not MAIN_TO_SUBCLASS_IDS.has(class_id):
		return _cached_subclasses.duplicate()

	var target_ids: Array = MAIN_TO_SUBCLASS_IDS[class_id]
	var filtered: Array[PlayerClass] = []
	for subclass_id in target_ids:
		if _cached_class_map.has(subclass_id):
			var subclass_instance = _cached_class_map[subclass_id] as PlayerClass
			if subclass_instance != null and subclass_instance.is_subclass:
				filtered.append(subclass_instance)
	return filtered if not filtered.is_empty() else _cached_subclasses.duplicate()


func get_all_classes() -> Array[PlayerClass]:
	if not _is_initialized:
		_initialize()
	return _cached_all_classes.duplicate()


func get_class_by_id(class_id: String) -> PlayerClass:
	if not _is_initialized:
		_initialize()
	if _cached_class_map.has(class_id):
		return _cached_class_map[class_id]
	return null


func is_main_class(class_id: String) -> bool:
	return class_id in MAIN_CLASS_IDS


func is_subclass(class_id: String) -> bool:
	return class_id in SUBCLASS_IDS


func is_main_class_instance(player_class: PlayerClass) -> bool:
	return player_class != null and player_class.is_main_class


func is_subclass_instance(player_class: PlayerClass) -> bool:
	return player_class != null and player_class.is_subclass


func get_class_id(player_class: PlayerClass) -> String:
	if player_class == null:
		return ""
	if not _is_initialized:
		_initialize()

	if player_class.has_meta(CLASS_ID_META_KEY):
		return str(player_class.get_meta(CLASS_ID_META_KEY))
 
	var class_type: String = player_class.get_script().get_global_name()
	if _cached_script_name_to_id.has(class_type):
		return _cached_script_name_to_id[class_type]

	var normalized_display_name := _normalize_display_name(player_class.display_name)
	if _cached_display_name_to_id.has(normalized_display_name):
		return _cached_display_name_to_id[normalized_display_name]
	return ""


func display_name_to_class_id(display_name: String) -> String:
	if not _is_initialized:
		_initialize()
	var normalized_display_name := _normalize_display_name(display_name)
	if _cached_display_name_to_id.has(normalized_display_name):
		return _cached_display_name_to_id[normalized_display_name]
	return ""


func class_id_to_display_name(class_id: String) -> String:
	if not _is_initialized:
		_initialize()
	if not _cached_class_map.has(class_id):
		return ""
	var p_class := _cached_class_map[class_id] as PlayerClass
	return p_class.display_name if p_class != null else ""


func get_main_class_display_order() -> Array[String]:
	if not _is_initialized:
		_initialize()
	var result: Array[String] = []
	for class_id in MAIN_CLASS_IDS:
		result.append(class_id_to_display_name(class_id))
	return result


func get_subclass_ids_for_main_id(main_class_id: String) -> Array[String]:
	if not MAIN_TO_SUBCLASS_IDS.has(main_class_id):
		return []
	var ids: Array = MAIN_TO_SUBCLASS_IDS[main_class_id]
	var result: Array[String] = []
	for item in ids:
		result.append(str(item))
	return result


func get_class_role(class_id: String) -> String:
	if class_id in TANK_CLASS_IDS:
		return "tank"
	if class_id in DPS_CLASS_IDS:
		return "dps"
	if class_id in SUPPORT_CLASS_IDS:
		return "support"
	if class_id in HYBRID_CLASS_IDS:
		return "hybrid"
	if class_id in CONTROLLER_CLASS_IDS:
		return "controller"
	return "unknown"


func get_class_role_from_instance(player_class: PlayerClass) -> String:
	return get_class_role(get_class_id(player_class))


func get_classes_by_role(role: String) -> Array[PlayerClass]:
	if not _is_initialized:
		_initialize()
	var result: Array[PlayerClass] = []
	var target_ids: Array[String] = []
	match role.to_lower():
		"tank": target_ids = TANK_CLASS_IDS
		"dps": target_ids = DPS_CLASS_IDS
		"support": target_ids = SUPPORT_CLASS_IDS
		"hybrid": target_ids = HYBRID_CLASS_IDS
		"controller": target_ids = CONTROLLER_CLASS_IDS
		_: return result
	for class_id in target_ids:
		if _cached_class_map.has(class_id):
			result.append(_cached_class_map[class_id])
	return result


func create_class_instance(class_id: String) -> PlayerClass:
	var class_scripts := _get_class_scripts()
	if class_scripts.has(class_id) and class_scripts[class_id] != null:
		var instance: PlayerClass = class_scripts[class_id].new()
		_apply_class_identity(instance, class_id)
		return instance
	return null


static func _apply_class_identity(instance: PlayerClass, class_id: String) -> void:
	if instance == null:
		return
	instance.set_meta(CLASS_ID_META_KEY, class_id)
	instance.is_main_class = class_id in MAIN_CLASS_IDS
	instance.is_subclass = class_id in SUBCLASS_IDS


static func _normalize_display_name(display_name: String) -> String:
	return display_name.strip_edges().to_lower()


func _validate_class_configuration() -> void:
	var class_scripts := _class_scripts
	if MAIN_CLASS_IDS.size() != REQUIRED_MAIN_CLASS_COUNT:
		push_error("ClassManager config invalid: expected %d main classes, got %d" % [REQUIRED_MAIN_CLASS_COUNT, MAIN_CLASS_IDS.size()])
	for class_id in MAIN_CLASS_IDS:
		if not class_scripts.has(class_id) or class_scripts[class_id] == null:
			push_error("ClassManager config invalid: main class '%s' is missing from the inspector registry" % class_id)
	for class_id in SUBCLASS_IDS:
		if not class_scripts.has(class_id) or class_scripts[class_id] == null:
			push_error("ClassManager config invalid: subclass '%s' is missing from the inspector registry" % class_id)
		if class_id in MAIN_CLASS_IDS:
			push_error("ClassManager config invalid: class '%s' cannot be both main and subclass" % class_id)


func get_class_info(class_id: String) -> Dictionary:
	var player_class = get_class_by_id(class_id)
	if player_class == null:
		return {}
	return {
		"id": class_id,
		"display_name": player_class.display_name,
		"description": player_class.description,
		"role": get_class_role(class_id),
		"is_main_class": is_main_class(class_id),
		"is_subclass": is_subclass(class_id),
		"ability_name": player_class.ability_name,
		"ability_description": player_class.ability_description,
		"passive_name": player_class.passive_name,
		"passive_description": player_class.passive_description
	}


func get_main_classes_info() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for class_id in MAIN_CLASS_IDS:
		result.append(get_class_info(class_id))
	return result


func get_subclasses_info() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for class_id in SUBCLASS_IDS:
		result.append(get_class_info(class_id))
	return result
