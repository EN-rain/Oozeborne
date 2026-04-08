extends Control
class_name DamageNumber

## DamageNumber - Floating damage text that rises and fades out

@export var damage_number_scene: PackedScene

@export var float_speed: float = 80.0
@export var float_duration: float = 1.0
@export var fade_start: float = 0.6
@export var horizontal_spread: float = 2.0
@export var wobble_amplitude: float = 0.0
@export var wobble_frequency: float = 8.0

var _damage: int = 0
var _is_crit: bool = false
var _elapsed: float = 0.0
var _start_position: Vector2 = Vector2.ZERO
var _is_configured: bool = false

@onready var label: Label = $Label


func _ready():
	top_level = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	set_process(false)


func setup(damage: int, is_crit: bool = false, color_override: Color = Color.WHITE):
	_damage = damage
	_is_crit = is_crit
	
	# Wait for label to be ready
	if label == null:
		await ready
	
	label.text = str(damage)
	
	# Style based on damage type
	if is_crit:
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))  # Gold for crits
		label.add_theme_color_override("font_outline_color", Color(0.8, 0.2, 0.0))
		label.add_theme_constant_override("outline_size", 2)
		# Add "!" for crits
		label.text = str(damage) + "!"
	elif damage < 0:
		# Healing (negative damage)
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))  # Green for heal
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		label.add_theme_constant_override("outline_size", 1)
		label.text = "+" + str(abs(damage))
	else:
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", color_override)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		label.add_theme_constant_override("outline_size", 1)

	_finish_setup(str(label.text))


func setup_custom(text: String, color: Color = Color.WHITE, font_size: int = 20) -> void:
	if label == null:
		await ready

	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 1)

	_finish_setup(text)


func _finish_setup(_text: String) -> void:
	_elapsed = 0.0
	_start_position = position + Vector2(randf_range(-horizontal_spread, horizontal_spread), 0.0)
	position = _start_position
	modulate.a = 1.0
	_is_configured = true
	visible = true
	set_process(true)


func _process(delta):
	if not _is_configured:
		return

	_elapsed += delta
	
	# Float upward
	position.y = _start_position.y - (_elapsed * float_speed)
	
	# Wobble around the spawn point instead of drifting away every frame
	position.x = _start_position.x + sin(_elapsed * wobble_frequency) * wobble_amplitude
	
	# Fade out
	if _elapsed > fade_start:
		var fade_progress = (_elapsed - fade_start) / (float_duration - fade_start)
		modulate.a = 1.0 - fade_progress
	
	# Remove when done
	if _elapsed >= float_duration:
		queue_free()
