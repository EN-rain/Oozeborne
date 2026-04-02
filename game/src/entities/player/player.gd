extends CharacterBody2D

@export var speed := 100.0
@export var knockback_decay := 800.0  
@export var hit_stun_time := 0.2        
@export var slash_scene: PackedScene
@export var dash_speed := 400.0
@export var dash_duration := 0.2
@export var dash_cooldown := 3.0

@onready var player_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_stun_timer: Timer = $HitStunTimer
@onready var health = $Health
@onready var dash_timer: Timer = Timer.new()
@onready var dash_cooldown_timer: Timer = Timer.new()
@onready var dash_particles: CPUParticles2D = $DashParticles

var is_local_player := true  # Set to false for remote players
var ign_label: Label

const FLIP_DEADZONE := 8.0
var is_taking_damage := false
var facing := 1
var is_basic_attacking := false
var attack_rotation := 0.0  # Rotation of current attack for multiplayer sync
var knockback_velocity := Vector2.ZERO
var can_move := true
var is_dashing := false
var can_dash := true
var dash_direction := Vector2.ZERO

func _ready():
	player_sprite.animation_finished.connect(_on_animation_finished)
	hit_stun_timer.timeout.connect(_on_hit_stun_timeout)
	health.died.connect(_on_player_died)
	
	# Create IGN label above sprite
	_create_ign_label()
	
	# Setup dash timers
	dash_timer.wait_time = dash_duration
	dash_timer.one_shot = true
	dash_timer.timeout.connect(_on_dash_finished)
	add_child(dash_timer)
	
	dash_cooldown_timer.wait_time = dash_cooldown
	dash_cooldown_timer.one_shot = true
	dash_cooldown_timer.timeout.connect(_on_dash_cooldown_finished)
	add_child(dash_cooldown_timer)

func _physics_process(delta):
	# Remote players are controlled by network interpolation, not physics
	if not is_local_player:
		return
	
	var input_dir := Vector2.ZERO
	
	if can_move and not is_dashing:
		input_dir.x = Input.get_action_strength("right") - Input.get_action_strength("left")
		input_dir.y = Input.get_action_strength("down") - Input.get_action_strength("up")
		
		if input_dir != Vector2.ZERO:
			input_dir = input_dir.normalized()
	
	# BASE MOVEMENT
	if is_dashing:
		velocity = dash_direction * dash_speed
	else:
		velocity = input_dir * speed
	
	# APPLY KNOCKBACK
	if not is_dashing:
		velocity += knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	
	move_and_slide()
	
	if is_local_player:
		if Input.is_action_just_pressed("dash") and can_dash and not is_dashing and not is_taking_damage:
			start_dash(input_dir)
		
		if Input.is_action_just_pressed("basic_attack"):
			if not is_basic_attacking and not is_taking_damage and not is_dashing:
				start_basic_attack()
	
	if is_taking_damage:
		return
	
	if is_basic_attacking or is_dashing:
		return
	
	if velocity.length() > 0.0:
		if player_sprite.animation != "walk":
			player_sprite.play("walk")
	else:
		if player_sprite.animation != "idle":
			player_sprite.play("idle")
	
	if is_local_player:
		var mouse_dir := get_global_mouse_position() - global_position
		if mouse_dir.x > FLIP_DEADZONE:
			facing = 1
			player_sprite.flip_h = false
		elif mouse_dir.x < -FLIP_DEADZONE:
			facing = -1
			player_sprite.flip_h = true

func start_basic_attack():
	is_basic_attacking = true
	player_sprite.play("basic_attack")
	
	var dir := (get_global_mouse_position() - global_position).normalized()
	attack_rotation = dir.angle()  # Store for multiplayer sync
	var slash := slash_scene.instantiate()
	get_tree().current_scene.add_child(slash)
	slash.global_position = global_position + dir * 12
	slash.rotation = dir.angle()
	print("[Player] Local slash rotation: ", dir.angle(), " (", rad_to_deg(dir.angle()), " degrees) dir: ", dir)
	
	# Sync attack to other players
	var main = get_tree().current_scene
	if main.has_method("send_attack"):
		main.send_attack(global_position, dir.angle())

func start_dash(dir):
	if dir == Vector2.ZERO:
		# Dash in facing direction if no input
		dir = Vector2(facing, 0)
	
	is_dashing = true
	can_dash = false
	dash_direction = dir.normalized()
	
	# Visual feedback - blue tint while dashing + particles
	player_sprite.modulate = Color(1.2, 1.2, 1.5)
	dash_particles.emitting = true
	
	dash_timer.start()

func _on_dash_finished():
	is_dashing = false
	player_sprite.modulate = Color.WHITE
	dash_particles.emitting = false
	dash_cooldown_timer.start()

func _on_dash_cooldown_finished():
	can_dash = true

func _create_ign_label():
	ign_label = Label.new()
	ign_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ign_label.add_theme_font_size_override("font_size", 14)
	add_child(ign_label)
	_update_ign_label_position()

func _update_ign_label_position():
	if ign_label and player_sprite:
		# Position above the sprite
		var sprite_height = player_sprite.sprite_frames.get_frame_texture("idle", 0).get_height() if player_sprite.sprite_frames else 32
		ign_label.position = Vector2(-ign_label.size.x / 2, -sprite_height / 2 - 20)

func set_ign(ign: String):
	if ign_label:
		ign_label.text = ign
		_update_ign_label_position()

func _process(_delta):
	# Keep label centered above player
	if ign_label:
		_update_ign_label_position()

func _on_animation_finished():
	if player_sprite.animation == "basic_attack":
		is_basic_attacking = false
	elif player_sprite.animation == "took_damage":
		is_taking_damage = false

#DAMAGE & KNOCKBACK-
func apply_damage(amount: int, source_position: Vector2, force: float):
	# Prevent damage spam animation
	if is_taking_damage:
		return
	
	health.take_damage(amount)
	
	# Cancel any ongoing attack
	is_basic_attacking = false
	
	is_taking_damage = true
	player_sprite.play("took_damage")
	
	# Knockback
	var dir := (global_position - source_position).normalized()
	knockback_velocity = dir * force
	
	can_move = false
	hit_stun_timer.start(hit_stun_time)

func _on_hit_stun_timeout():
	can_move = true

func _on_player_died():
	queue_free()
