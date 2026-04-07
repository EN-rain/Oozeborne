extends Node

## DamageNumberManager - Singleton for spawning damage numbers
## Add to AutoLoad as "DamageNumbers"

@export var damage_number_scene: PackedScene

# Colors for different damage types
const COLOR_NORMAL := Color.WHITE
const COLOR_CRIT := Color(1.0, 0.85, 0.2)  # Gold
const COLOR_HEAL := Color(0.3, 1.0, 0.5)   # Green
const COLOR_PLAYER_DAMAGE := Color(1.0, 0.3, 0.3)  # Red for player taking damage
const COLOR_ENEMY_DAMAGE := Color(1.0, 1.0, 1.0)  # White for enemy damage


func spawn_damage(at_position: Vector2, damage: int, is_crit: bool = false, is_player: bool = false) -> void:
	var instance = _create_damage_number_instance()
	if instance == null:
		return
	get_tree().current_scene.add_child(instance)
	instance.global_position = at_position
	
	var color = COLOR_PLAYER_DAMAGE if is_player else COLOR_ENEMY_DAMAGE
	instance.setup(damage, is_crit, color)


func spawn_heal(at_position: Vector2, amount: int) -> void:
	var instance = _create_damage_number_instance()
	if instance == null:
		return
	get_tree().current_scene.add_child(instance)
	instance.global_position = at_position
	instance.setup(-amount, false, COLOR_HEAL)  # Negative = heal


func spawn_custom(at_position: Vector2, text: String, color: Color = Color.WHITE, font_size: int = 20) -> void:
	var instance = _create_damage_number_instance()
	if instance == null:
		return
	get_tree().current_scene.add_child(instance)
	instance.global_position = at_position
	
	# Custom text setup
	if instance.has_node("Label"):
		var label = instance.get_node("Label")
		label.text = text
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", color)


func _create_damage_number_instance() -> Node:
	if damage_number_scene == null:
		push_error("[DamageNumbers] damage_number_scene is not assigned.")
		return null
	return damage_number_scene.instantiate()
