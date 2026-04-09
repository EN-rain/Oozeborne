extends Node
class_name PlayerVisualController

const MOVE_FLIP_DEADZONE := 0.08
const SLIME_VISUAL_SCALE := 0.85
const SLIME_COLLISION_SCALE := 0.9

var _player: CharacterBody2D
var _player_sprite: AnimatedSprite2D
var _dash_particles: CPUParticles2D
var _dash_trail: CPUParticles2D
var _damage_particles: CPUParticles2D
var _original_slime_shader_colors: Dictionary = {}


func setup(
	player: CharacterBody2D,
	player_sprite: AnimatedSprite2D,
	dash_particles: CPUParticles2D,
	dash_trail: CPUParticles2D,
	damage_particles: CPUParticles2D
) -> void:
	_player = player
	_player_sprite = player_sprite
	_dash_particles = dash_particles
	_dash_trail = dash_trail
	_damage_particles = damage_particles


func apply_ready_setup() -> void:
	_apply_slime_size_tuning()
	_configure_dash_particles()
	_capture_original_slime_shader_colors()
	_apply_slime_effect_colors()


func update_sprite_facing(motion_dir: Vector2 = Vector2.ZERO) -> void:
	if _player == null or not _player.is_local_player:
		return

	var horizontal_dir: float = motion_dir.x
	if abs(horizontal_dir) <= MOVE_FLIP_DEADZONE:
		var mouse_dir := _player.get_global_mouse_position() - _player.global_position
		horizontal_dir = mouse_dir.x

	if horizontal_dir > MOVE_FLIP_DEADZONE:
		_player.facing = 1
		_player_sprite.flip_h = true
	elif horizontal_dir < -MOVE_FLIP_DEADZONE:
		_player.facing = -1
		_player_sprite.flip_h = false


func on_dash_started(direction: Vector2) -> void:
	update_sprite_facing(direction)
	if _player_sprite.sprite_frames and _player_sprite.sprite_frames.has_animation("dash"):
		_player_sprite.play("dash")

	_player_sprite.modulate = Color(1.2, 1.2, 1.5)

	var angle := direction.angle()
	if _dash_particles:
		_dash_particles.direction = Vector2(cos(angle), sin(angle))
		_dash_particles.emitting = true
	if _dash_trail:
		_dash_trail.direction = Vector2(cos(angle), sin(angle))
		_dash_trail.emitting = true


func on_dash_finished() -> void:
	_player_sprite.modulate = Color.WHITE
	if _dash_particles:
		_dash_particles.emitting = false
	if _dash_trail:
		_dash_trail.emitting = false


func on_animation_finished() -> void:
	if _player_sprite.animation == "took_damage" and not _player.damage_flash_active:
		_player.is_taking_damage = false


func play_hit_flash() -> void:
	if _player.damage_flash_active:
		return

	_player.damage_flash_active = true
	if _player_sprite.sprite_frames != null and _player_sprite.sprite_frames.has_animation("dash"):
		_player_sprite.play("dash")
	else:
		_player_sprite.play("took_damage")

	_apply_white_hit_flash()
	call_deferred("_finish_hit_flash")


func get_slime_effect_palette() -> Dictionary:
	var fallback_primary := Color(0.95, 0.95, 1.0, 1.0)
	var fallback_secondary := Color(0.75, 0.85, 1.0, 1.0)
	return {
		"primary": _original_slime_shader_colors.get("mid_color", fallback_primary),
		"secondary": _original_slime_shader_colors.get("highlight_color", fallback_secondary),
		"outline": _original_slime_shader_colors.get("outline_color", Color(0.1, 0.1, 0.1, 1.0))
	}


func get_slash_effect_color() -> Color:
	return get_slime_effect_palette().get("secondary", Color.WHITE)


func get_explosion_effect_color() -> Color:
	var palette := get_slime_effect_palette()
	var primary: Color = palette.get("primary", Color.WHITE)
	var secondary: Color = palette.get("secondary", Color.WHITE)
	return primary.lerp(secondary, 0.35)


func _apply_slime_size_tuning() -> void:
	if _player_sprite:
		_player_sprite.scale = Vector2.ONE * SLIME_VISUAL_SCALE

	var collision := _player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision and collision.shape is CapsuleShape2D:
		var capsule := collision.shape as CapsuleShape2D
		capsule.radius *= SLIME_COLLISION_SCALE
		capsule.height *= SLIME_COLLISION_SCALE


func _configure_dash_particles() -> void:
	_dash_particles.position = Vector2(0, 6)
	_dash_particles.z_index = -1
	_dash_particles.amount = 26
	_dash_particles.lifetime = 0.22
	_dash_particles.one_shot = false
	_dash_particles.explosiveness = 0.85
	_dash_particles.randomness = 0.7
	_dash_particles.spread = 30.0
	_dash_particles.gravity = Vector2(0, 20)
	_dash_particles.initial_velocity_min = 80.0
	_dash_particles.initial_velocity_max = 160.0
	_dash_particles.scale_amount_min = 0.9
	_dash_particles.scale_amount_max = 1.6
	_dash_particles.color = Color(1, 1, 1, 0.95)
	_dash_particles.emitting = false

	_dash_trail.position = Vector2(0, 8)
	_dash_trail.z_index = -1
	_dash_trail.amount = 42
	_dash_trail.lifetime = 0.35
	_dash_trail.one_shot = false
	_dash_trail.explosiveness = 0.25
	_dash_trail.randomness = 0.9
	_dash_trail.spread = 55.0
	_dash_trail.gravity = Vector2(0, 25)
	_dash_trail.initial_velocity_min = 30.0
	_dash_trail.initial_velocity_max = 85.0
	_dash_trail.scale_amount_min = 0.6
	_dash_trail.scale_amount_max = 1.2
	_dash_trail.color = Color(1, 1, 1, 0.7)
	_dash_trail.emitting = false


func _capture_original_slime_shader_colors() -> void:
	var shader_material := _player_sprite.material as ShaderMaterial
	if shader_material == null:
		return

	for parameter_name in [
		"highlight_color",
		"mid_color",
		"shadow_color",
		"outline_color",
		"iris_color",
		"eye_highlight_color"
	]:
		_original_slime_shader_colors[parameter_name] = shader_material.get_shader_parameter(parameter_name)


func _apply_slime_effect_colors() -> void:
	if _damage_particles != null:
		_damage_particles.color = get_explosion_effect_color()


func _apply_white_hit_flash() -> void:
	var shader_material := _player_sprite.material as ShaderMaterial
	if shader_material == null:
		_player_sprite.modulate = Color.WHITE
		return

	for parameter_name in _original_slime_shader_colors.keys():
		shader_material.set_shader_parameter(parameter_name, Color.WHITE)


func _restore_slime_shader_colors() -> void:
	var shader_material := _player_sprite.material as ShaderMaterial
	if shader_material == null:
		_player_sprite.modulate = Color.WHITE
		return

	for parameter_name in _original_slime_shader_colors.keys():
		shader_material.set_shader_parameter(parameter_name, _original_slime_shader_colors[parameter_name])


func _finish_hit_flash() -> void:
	await get_tree().process_frame
	_restore_slime_shader_colors()
	_player.damage_flash_active = false
	_player.is_taking_damage = false

	if _player.is_death_sequence_active or _player.is_dashing:
		return

	if _player.velocity.length() > 0.0:
		_player_sprite.play("walk")
	else:
		_player_sprite.play("idle")
