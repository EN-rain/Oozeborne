extends Node

## DamageNumberManager - Singleton for spawning damage numbers
## Add to AutoLoad as "DamageNumbers"

const DAMAGE_NUMBER_SCENE = preload("res://scenes/effects/damage_number.tscn")

# Colors for different damage types
const COLOR_NORMAL := Color.WHITE
const COLOR_CRIT := Color(1.0, 0.85, 0.2)  # Gold
const COLOR_HEAL := Color(0.3, 1.0, 0.5)   # Green
const COLOR_PLAYER_DAMAGE := Color(1.0, 0.3, 0.3)  # Red for player taking damage
const COLOR_ENEMY_DAMAGE := Color(1.0, 1.0, 1.0)  # White for enemy damage


func spawn_damage(at_position: Vector2, damage: int, is_crit: bool = false, is_player: bool = false) -> void:
	var instance = DAMAGE_NUMBER_SCENE.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.global_position = at_position
	
	var color = COLOR_PLAYER_DAMAGE if is_player else COLOR_ENEMY_DAMAGE
	instance.setup(damage, is_crit, color)


func spawn_heal(at_position: Vector2, amount: int) -> void:
	var instance = DAMAGE_NUMBER_SCENE.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.global_position = at_position
	instance.setup(-amount, false, COLOR_HEAL)  # Negative = heal


func spawn_custom(at_position: Vector2, text: String, color: Color = Color.WHITE, font_size: int = 20) -> void:
	var instance = DAMAGE_NUMBER_SCENE.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.global_position = at_position
	
	# Custom text setup
	if instance.has_node("Label"):
		var label = instance.get_node("Label")
		label.text = text
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", color)
