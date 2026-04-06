extends Node2D

signal sequence_finished(killer_name: String)

@export var sprite_path: NodePath = ^"../AnimatedSprite2D"
@export var collision_shape_path: NodePath = ^"../CollisionShape2D"
@export var camera_path: NodePath = ^"../Camera2D"
@export var damage_particles_path: NodePath = ^"../DamageParticles"
@export var death_explosion_path: NodePath = ^"../DamageParticles"

var is_active := false
var _killer_name := ""

@onready var _player_sprite: AnimatedSprite2D = get_node_or_null(sprite_path) as AnimatedSprite2D
@onready var _collision_shape: CollisionShape2D = get_node_or_null(collision_shape_path) as CollisionShape2D
@onready var _damage_particles: CPUParticles2D = get_node_or_null(damage_particles_path) as CPUParticles2D
@onready var _death_explosion: CPUParticles2D = get_node_or_null(death_explosion_path) as CPUParticles2D


func start(player: CharacterBody2D, killer_name: String, skill_manager: Node = null) -> void:
	if is_active:
		return

	is_active = true
	_killer_name = killer_name.strip_edges()
	_lock_player(player, skill_manager)
	
	await _play_sequence(player)
	sequence_finished.emit(_resolve_killer_name())
	
	# Only hide the sprite, keep player node fully active to preserve camera
	if _player_sprite != null:
		_player_sprite.visible = false
	# Disable collision but keep camera working
	if _collision_shape != null:
		_collision_shape.disabled = true
	# Don't hide entire player, don't disable process_mode - keep camera alive



func _lock_player(player: CharacterBody2D, skill_manager: Node) -> void:
	player.is_death_sequence_active = true
	player.is_taking_damage = false
	player.can_move = false
	player.can_dash = false
	player.can_basic_attack = false
	player.is_dashing = false
	player.velocity = Vector2.ZERO
	player.knockback_velocity = Vector2.ZERO
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)

	if skill_manager != null:
		skill_manager.unbind_player(player)
	if _collision_shape != null:
		_collision_shape.set_deferred("disabled", true)

	player.collision_layer = 0
	player.collision_mask = 0

	if _damage_particles != null:
		_damage_particles.emitting = false


func _play_sequence(player: CharacterBody2D) -> void:
	# Store original position to prevent any movement during death animation
	var original_position := player.global_position
	if _player_sprite == null:
		_play_death_explosion(player)
		return

	var flash_steps := [
		{"duration": 0.16, "color": Color(1.0, 1.0, 1.0, 1.0)},
		{"duration": 0.13, "color": Color(1.15, 1.15, 1.15, 1.0)},
		{"duration": 0.1, "color": Color(1.3, 1.3, 1.3, 1.0)},
		{"duration": 0.08, "color": Color(1.45, 1.45, 1.45, 1.0)},
		{"duration": 0.06, "color": Color(1.6, 1.6, 1.6, 1.0)},
		{"duration": 0.04, "color": Color(1.8, 1.8, 1.8, 1.0)}
	]
	for index in range(flash_steps.size()):
		var step: Dictionary = flash_steps[index]
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(_player_sprite, "modulate", step["color"], step["duration"])
		await tween.finished
		# Lock player position after each tween step
		player.global_position = original_position

	_play_death_explosion(player)
	player.visible = false
	
	await get_tree().create_timer(0.2).timeout


func _play_death_explosion(player: CharacterBody2D) -> void:
	if _death_explosion == null:
		return

	_death_explosion.global_position = player.global_position
	_death_explosion.one_shot = true
	_death_explosion.explosiveness = 1.0
	_death_explosion.amount = 64
	_death_explosion.lifetime = 0.65
	_death_explosion.local_coords = false
	_death_explosion.direction = Vector2.UP
	_death_explosion.spread = 180.0
	_death_explosion.gravity = Vector2.ZERO
	_death_explosion.initial_velocity_min = 120.0
	_death_explosion.initial_velocity_max = 260.0
	_death_explosion.scale_amount_min = 1.4
	_death_explosion.scale_amount_max = 2.8
	_death_explosion.color = Color(0.98, 0.98, 0.98, 1.0)
	_death_explosion.z_index = 6
	_death_explosion.emitting = false
	_death_explosion.restart()
	_death_explosion.emitting = true


func _resolve_killer_name() -> String:
	if not _killer_name.is_empty():
		return _killer_name
	return "something rude"
