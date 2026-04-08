extends Node
class_name StatusEffect

## StatusEffect - Base class for buffs and debuffs
## Attach to player to apply timed effects

signal effect_expired(effect_name: String)

@export var effect_name: String = "unknown"
@export var duration: float = 5.0
@export var is_debuff: bool = true
@export var popup_text: String = ""
@export var popup_color: Color = Color(1.0, 0.45, 0.3, 1.0)
@export var show_apply_popup: bool = true

var target: Node = null
var time_remaining: float = 0.0
var is_active: bool = false


func apply(target_node: Node) -> void:
	if is_active:
		return
	
	target = target_node
	is_active = true
	time_remaining = duration
	
	_on_apply()
	_print_status("applied")


func remove() -> void:
	if not is_active:
		return
	
	is_active = false
	_on_remove()
	_print_status("removed")
	effect_expired.emit(effect_name)


func tick(delta: float) -> void:
	if not is_active:
		return
	
	time_remaining -= delta
	
	_on_tick(delta)
	
	if time_remaining <= 0:
		remove()


func refresh() -> void:
	time_remaining = duration
	_print_status("refreshed")


## Override in subclasses
func _on_apply() -> void:
	pass


func _on_remove() -> void:
	pass


func _on_tick(_delta: float) -> void:
	pass


func _print_status(action: String) -> void:
	print("[StatusEffect] %s %s (%.1fs remaining)" % [effect_name, action, time_remaining])
