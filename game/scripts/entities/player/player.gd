extends CharacterBody2D

signal death_sequence_finished(killer_name: String)

const PLAYER_VISUAL_CONTROLLER_SCRIPT := preload("res://scripts/entities/player/player_visual_controller.gd")
const PLAYER_COMBAT_CONTROLLER_SCRIPT := preload("res://scripts/entities/player/player_combat_controller.gd")
const PLAYER_STATS_CONTROLLER_SCRIPT := preload("res://scripts/entities/player/player_stats_controller.gd")

@export var speed := 100.0
@export var knockback_decay := 800.0
@export var hit_stun_time := 0.2
@export var dash_speed := 400.0
@export var dash_duration := 0.2
@export var dash_cooldown := 3.0
@export var basic_attack_cooldown := 0.4
@export var camera_zoom_step := 0.25
@export var camera_zoom_min := 0.8
@export var camera_zoom_max := 6.0
@export var slash_effect_scene: PackedScene

var attack_damage := 25

@onready var player_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player_camera: Camera2D = $Camera2D
@onready var hit_stun_timer: Timer = $HitStunTimer
@onready var health = $Health
@onready var death_sequence = $DeathSequence
@onready var dash_timer: Timer = Timer.new()
@onready var dash_particles: CPUParticles2D = $DashParticles
@onready var dash_trail: CPUParticles2D = $DashTrail
@onready var damage_particles: CPUParticles2D = $DamageParticles
@onready var visual_controller: PlayerVisualController = _ensure_controller("PlayerVisualController", PLAYER_VISUAL_CONTROLLER_SCRIPT) as PlayerVisualController
@onready var combat_controller: PlayerCombatController = _ensure_controller("PlayerCombatController", PLAYER_COMBAT_CONTROLLER_SCRIPT) as PlayerCombatController
@onready var stats_controller: PlayerStatsController = _ensure_controller("PlayerStatsController", PLAYER_STATS_CONTROLLER_SCRIPT) as PlayerStatsController

var is_local_player := true
var is_taking_damage := false
var last_attacker_name: String = ""
var is_death_sequence_active := false
var facing := 1
var knockback_velocity := Vector2.ZERO
var can_move := true
var is_dashing := false
var can_dash := true
var can_basic_attack := true
var dash_direction := Vector2.ZERO
var damage_flash_active := false


func _get_player_skill_manager() -> Node:
	return PlayerSkillManager


func _ensure_controller(node_name: String, script_resource: Script) -> Node:
	var controller: Node = get_node_or_null(node_name)
	if controller == null:
		controller = Node.new()
		controller.name = node_name
		controller.set_script(script_resource)
		add_child(controller)
		controller.owner = self
	return controller


func _ready() -> void:
	visual_controller.setup(self, player_sprite, dash_particles, dash_trail, damage_particles)
	combat_controller.setup(self, health, death_sequence, hit_stun_timer, dash_timer, visual_controller)
	stats_controller.setup(self, health)
	visual_controller.apply_ready_setup()

	player_sprite.animation_finished.connect(_on_animation_finished)
	hit_stun_timer.timeout.connect(_on_hit_stun_timeout)
	health.died.connect(_on_player_died)
	if death_sequence != null:
		death_sequence.sequence_finished.connect(_on_death_sequence_finished)

	call_deferred("_finalize_stats_runtime_setup")

	dash_timer.wait_time = dash_duration
	dash_timer.one_shot = true
	dash_timer.timeout.connect(_on_dash_finished)
	add_child(dash_timer)

	if is_local_player:
		var skill_manager: Node = _get_player_skill_manager()
		if skill_manager != null:
			skill_manager.bind_player(self)


func _finalize_stats_runtime_setup() -> void:
	stats_controller.register_player()
	stats_controller.apply_class_modifiers()


func _physics_process(delta: float) -> void:
	if not is_local_player:
		return
	if is_death_sequence_active:
		velocity = Vector2.ZERO
		return
	if _is_hud_blocking_input():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_dir := Vector2.ZERO
	if can_move and not is_dashing:
		input_dir.x = Input.get_action_strength("right") - Input.get_action_strength("left")
		input_dir.y = Input.get_action_strength("down") - Input.get_action_strength("up")
		if input_dir != Vector2.ZERO:
			input_dir = input_dir.normalized()

	if is_dashing:
		velocity = dash_direction * dash_speed
	else:
		velocity = input_dir * speed

	if not is_dashing:
		velocity += knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)

	visual_controller.update_sprite_facing(input_dir if not is_dashing else dash_direction)
	move_and_slide()

	if is_local_player:
		var skill_manager: Node = _get_player_skill_manager()
		if skill_manager != null:
			skill_manager.process_local_input(self, input_dir)

	if is_taking_damage or is_dashing:
		return

	if velocity.length() > 0.0:
		if player_sprite.animation != "walk":
			player_sprite.play("walk")
	else:
		if player_sprite.animation != "idle":
			player_sprite.play("idle")


func _unhandled_input(event: InputEvent) -> void:
	if not is_local_player or is_death_sequence_active:
		return
	if _is_hud_blocking_input():
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if not mouse_event.pressed:
			return

		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if _is_pointer_over_ui():
				return
			start_basic_attack()
			return

		if player_camera == null:
			return
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_apply_camera_zoom(-camera_zoom_step)
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_apply_camera_zoom(camera_zoom_step)


func start_basic_attack() -> void:
	if is_death_sequence_active:
		return
	if _is_hud_blocking_input():
		return
	if get_tree() != null and get_tree().paused:
		return
	var skill_manager: Node = _get_player_skill_manager()
	if skill_manager != null:
		skill_manager.request_basic_attack(self)


func perform_basic_attack() -> void:
	combat_controller.perform_basic_attack()


func emit_attack_particles_at(world_pos: Vector2, rotation_angle: float) -> void:
	combat_controller.emit_attack_particles_at(world_pos, rotation_angle)


func _apply_camera_zoom(delta_zoom: float) -> void:
	var next_zoom := clampf(player_camera.zoom.x + delta_zoom, camera_zoom_min, camera_zoom_max)
	player_camera.zoom = Vector2.ONE * next_zoom


func start_dash(dir: Vector2) -> void:
	if is_death_sequence_active:
		return
	if _is_hud_blocking_input():
		return
	var skill_manager: Node = _get_player_skill_manager()
	if skill_manager != null:
		skill_manager.request_dash(self, dir)


func _get_hud() -> Node:
	var scene_tree := get_tree()
	if scene_tree == null:
		return null
	var current_scene := scene_tree.current_scene
	if current_scene == null:
		return null
	return current_scene.get_node_or_null("HUD")


func _is_hud_blocking_input() -> bool:
	var hud := _get_hud()
	return hud != null and hud.has_method("has_blocking_overlay_open") and bool(hud.call("has_blocking_overlay_open"))


func _is_pointer_over_ui() -> bool:
	var viewport := get_viewport()
	if viewport == null:
		return false
	var hud := _get_hud()
	if hud != null and hud.has_method("is_pointer_over_ui"):
		return bool(hud.call("is_pointer_over_ui", viewport.get_mouse_position()))
	return viewport.gui_get_hovered_control() != null


func perform_dash(dir: Vector2) -> void:
	combat_controller.perform_dash(dir)


func _on_dash_finished() -> void:
	combat_controller.on_dash_finished()


func set_ign(_ign: String) -> void:
	pass


func _on_animation_finished() -> void:
	visual_controller.on_animation_finished()


func apply_damage(amount: int, source_position: Vector2, force: float, attacker_name: String = "") -> void:
	combat_controller.apply_damage(amount, source_position, force, attacker_name)


func _on_hit_stun_timeout() -> void:
	combat_controller.on_hit_stun_timeout()


func _on_player_died() -> void:
	combat_controller.on_player_died()


func is_targetable() -> bool:
	return combat_controller.is_targetable()


func _on_death_sequence_finished(killer_name: String) -> void:
	combat_controller.on_death_sequence_finished(killer_name)


func notify_death_sequence_finished(killer_name: String) -> void:
	death_sequence_finished.emit(killer_name)


func _exit_tree() -> void:
	stats_controller.unregister_player()
	if is_local_player:
		var skill_manager: Node = _get_player_skill_manager()
		if skill_manager != null:
			skill_manager.unbind_player(self)


func get_slime_effect_palette() -> Dictionary:
	return visual_controller.get_slime_effect_palette()


func get_slash_effect_color() -> Color:
	return visual_controller.get_slash_effect_color()


func get_explosion_effect_color() -> Color:
	return visual_controller.get_explosion_effect_color()


func _apply_class_modifiers() -> void:
	stats_controller.apply_class_modifiers()


func apply_subclass_modifiers(player_subclass: PlayerClass) -> void:
	stats_controller.apply_subclass_modifiers(player_subclass)


func reapply_class_modifiers_after_level_sync(base_stats: Dictionary) -> void:
	stats_controller.reapply_class_modifiers_after_level_sync(base_stats)
