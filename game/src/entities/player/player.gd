extends CharacterBody2D

# Player controller script

@export var speed := 100.0
@export var knockback_decay := 800.0  
@export var hit_stun_time := 0.2        
@export var slash_scene: PackedScene
@export var dash_speed := 400.0
@export var dash_duration := 0.2
@export var dash_cooldown := 3.0

# Attack damage is now managed by LevelSystem
var attack_damage := 25

@onready var player_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_stun_timer: Timer = $HitStunTimer
@onready var health = $Health
@onready var dash_timer: Timer = Timer.new()
@onready var dash_cooldown_timer: Timer = Timer.new()
@onready var dash_particles: CPUParticles2D = $DashParticles
@onready var dash_trail: CPUParticles2D = $DashTrail
@onready var damage_particles: CPUParticles2D = $DamageParticles

var is_local_player := true  # Set to false for remote players

const FLIP_DEADZONE := 8.0
var is_taking_damage := false
var facing := 1
var knockback_velocity := Vector2.ZERO
var can_move := true
var is_dashing := false
var can_dash := true
var dash_direction := Vector2.ZERO

func _ready():
	player_sprite.animation_finished.connect(_on_animation_finished)
	hit_stun_timer.timeout.connect(_on_hit_stun_timeout)
	health.died.connect(_on_player_died)
	
	# Register with LevelSystem singleton
	LevelSystem.register_player(self)
	
	# Apply class modifiers if a class is selected
	_apply_class_modifiers()
	
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
		
		if Input.is_action_just_pressed("basic_attack") and not is_taking_damage and not is_dashing:
			start_basic_attack()
	
	if is_taking_damage:
		return
	
	if is_dashing:
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
	var dir := (get_global_mouse_position() - global_position).normalized()
	var slash := slash_scene.instantiate()
	get_tree().current_scene.add_child(slash)
	slash.global_position = global_position + dir * 12
	slash.rotation = dir.angle()
	# Apply level-scaled damage
	slash.set_damage(attack_damage)
	print("[Player] Local slash rotation: ", dir.angle(), " (", rad_to_deg(dir.angle()), " degrees) dir: ", dir, " damage: ", attack_damage)
	
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
	if player_sprite.sprite_frames and player_sprite.sprite_frames.has_animation("dash"):
		player_sprite.play("dash")
	
	# Visual feedback - blue tint while dashing + particles
	player_sprite.modulate = Color(1.2, 1.2, 1.5)
	
	# Set particle direction based on dash direction
	var angle = dash_direction.angle()
	dash_particles.direction = Vector2(cos(angle), sin(angle))
	dash_trail.direction = Vector2(cos(angle), sin(angle))
	
	# Emit particles
	dash_particles.emitting = true
	dash_trail.emitting = true
	
	dash_timer.start()

func _on_dash_finished():
	is_dashing = false
	player_sprite.modulate = Color.WHITE
	dash_particles.emitting = false
	dash_trail.emitting = false
	dash_cooldown_timer.start()

func _on_dash_cooldown_finished():
	can_dash = true

func set_ign(_ign: String):
	# IGN is now displayed in the main UI, not on the player
	pass

func _on_animation_finished():
	if player_sprite.animation == "took_damage":
		is_taking_damage = false

#DAMAGE & KNOCKBACK-
func apply_damage(amount: int, source_position: Vector2, force: float):
	# Prevent damage spam animation
	if is_taking_damage:
		return
	
	# Apply vulnerability modifier if active
	if has_meta("damage_modifier"):
		var modifier = get_meta("damage_modifier")
		amount = int(amount * modifier)
		print("[Player] Damage modified by %.0f%% to %d" % [modifier * 100, amount])
	
	health.take_damage(amount)
	
	# Spawn damage number
	DamageNumbers.spawn_damage(global_position + Vector2(0, -20), amount, false, true)
	
	is_taking_damage = true
	player_sprite.play("took_damage")
	
	# Emit damage particles
	if damage_particles:
		damage_particles.emitting = true
	
	# Knockback
	var dir := (global_position - source_position).normalized()
	knockback_velocity = dir * force
	
	can_move = false
	hit_stun_timer.start(hit_stun_time)

func _on_hit_stun_timeout():
	can_move = true

func _on_player_died():
	queue_free()

# ---------------- CLASS MODIFIERS ----------------
func _apply_class_modifiers():
	var player_class = MultiplayerManager.player_class
	var player_subclass = MultiplayerManager.player_subclass
	
	if player_class == null:
		return
	
	# Apply main class modifiers
	speed *= player_class.modifiers_speed
	attack_damage = int(attack_damage * player_class.modifiers_damage)
	dash_speed *= player_class.modifiers_speed
	dash_cooldown /= player_class.modifiers_attack_speed
	
	# Apply HP modifier
	if health:
		health.max_health = int(health.max_health * player_class.modifiers_hp)
		health.current_health = health.max_health
	
	# Store passive bonuses as metadata
	set_meta("lifesteal", player_class.passive_lifesteal / 100.0)
	set_meta("dodge_chance", player_class.passive_dodge_chance / 100.0)
	set_meta("crit_chance", (player_class.modifiers_crit_chance - 1.0) * 0.5)  # Base 50% scaled
	set_meta("crit_damage", player_class.modifiers_crit_damage)
	set_meta("defense_modifier", player_class.modifiers_defense)
	
	# Apply subclass modifiers if available (level 10+)
	if player_subclass != null:
		# Subclass gives 50% of modifiers
		speed *= 1.0 + (player_subclass.modifiers_speed - 1.0) * 0.5
		attack_damage = int(attack_damage * (1.0 + (player_subclass.modifiers_damage - 1.0) * 0.5))
		
		# Add subclass passives
		var current_lifesteal = get_meta("lifesteal", 0.0)
		set_meta("lifesteal", current_lifesteal + player_subclass.passive_lifesteal / 100.0 * 0.5)
		
		var current_dodge = get_meta("dodge_chance", 0.0)
		set_meta("dodge_chance", current_dodge + player_subclass.passive_dodge_chance / 100.0 * 0.5)
	
	print("[Player] Applied class modifiers: %s" % player_class.display_name)
