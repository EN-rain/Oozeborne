extends Node2D
class_name DamageNumber

## DamageNumber - Floating damage text that rises and fades out

@export var damage_number_scene: PackedScene

@export var float_speed: float = 80.0
@export var float_duration: float = 1.0
@export var fade_start: float = 0.6

var _damage: int = 0
var _is_crit: bool = false
var _elapsed: float = 0.0
var _start_y: float = 0.0

@onready var label: Label = $Label


func _ready():
	_start_y = position.y
	_elapsed = 0.0


func setup(damage: int, is_crit: bool = false, color_override: Color = Color.WHITE):
	_damage = damage
	_is_crit = is_crit
	
	# Wait for label to be ready
	if label == null:
		await ready
	
	label.text = str(damage)
	
	# Style based on damage type
	if is_crit:
		label.add_theme_font_size_override("font_size", 28)
		label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))  # Gold for crits
		label.add_theme_color_override("font_outline_color", Color(0.8, 0.2, 0.0))
		label.add_theme_constant_override("outline_size", 4)
		# Add "!" for crits
		label.text = str(damage) + "!"
	elif damage < 0:
		# Healing (negative damage)
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))  # Green for heal
		label.text = "+" + str(abs(damage))
	else:
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_color", color_override)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		label.add_theme_constant_override("outline_size", 3)
	
	# Random horizontal offset for variety
	position.x += randf_range(-15, 15)


func _process(delta):
	_elapsed += delta
	
	# Float upward
	position.y = _start_y - (_elapsed * float_speed)
	
	# Add slight horizontal wobble
	position.x += sin(_elapsed * 8) * 0.5
	
	# Fade out
	if _elapsed > fade_start:
		var fade_progress = (_elapsed - fade_start) / (float_duration - fade_start)
		modulate.a = 1.0 - fade_progress
	
	# Remove when done
	if _elapsed >= float_duration:
		queue_free()
