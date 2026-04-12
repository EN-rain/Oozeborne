extends Node
class_name ManaComponent

signal mana_changed(current_mana: int, max_mana: int)

@export var max_mana: int = 0 ## 0 = non-mana class; set by player based on class + level
@export var base_mana_regen: float = 3.0 ## MP/s in combat
@export var out_of_combat_regen_multiplier: float = 2.0 ## Doubles regen out of combat
@export var out_of_combat_threshold: float = 2.0 ## Seconds without taking damage to be "out of combat"

var current_mana: int = 0
var mana_regen_bonus: float = 0.0 ## Additional MP/s from stats/skills
var _combat_timer: float = 0.0
var _is_in_combat: bool = false


func _ready() -> void:
	if max_mana > 0:
		current_mana = max_mana
	set_process(max_mana > 0)


func _process(delta: float) -> void:
	if max_mana <= 0:
		return

	# Track combat state
	if _is_in_combat:
		_combat_timer -= delta
		if _combat_timer <= 0.0:
			_is_in_combat = false

	# Regenerate mana
	var regen_rate := base_mana_regen + mana_regen_bonus
	if not _is_in_combat:
		regen_rate *= out_of_combat_regen_multiplier

	var mana_before := current_mana
	current_mana = mini(current_mana + int(regen_rate * delta), max_mana)
	if current_mana != mana_before:
		mana_changed.emit(current_mana, max_mana)


func use_mana(amount: int) -> bool:
	if amount > current_mana:
		return false
	current_mana = maxi(current_mana - amount, 0)
	mana_changed.emit(current_mana, max_mana)
	return true


func restore_mana(amount: int) -> void:
	var mana_before := current_mana
	current_mana = mini(current_mana + amount, max_mana)
	if current_mana != mana_before:
		mana_changed.emit(current_mana, max_mana)


func has_mana(amount: int) -> bool:
	return current_mana >= amount


func enter_combat() -> void:
	_is_in_combat = true
	_combat_timer = out_of_combat_threshold


func set_max_mana(new_max: int) -> void:
	var ratio: float = float(current_mana) / float(maxi(max_mana, 1))
	max_mana = maxi(new_max, 0)
	current_mana = mini(int(max_mana * ratio), max_mana)
	mana_changed.emit(current_mana, max_mana)


func get_mana_percent() -> float:
	if max_mana <= 0:
		return 0.0
	return float(current_mana) / float(max_mana)
