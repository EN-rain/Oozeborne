extends Area2D
class_name Coin

## Coin - Collectible coin dropped by enemies

@export var value: int = 1
@export var attract_speed: float = 200.0
@export var attract_range: float = 50.0
@export var collect_range: float = 20.0
@export var lifetime: float = 30.0
@export var player_group_name: StringName = &"player"

var _elapsed: float = 0.0
var _target_player: Node2D = null
var _is_attracting: bool = false
var _velocity: Vector2 = Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collect_area: Area2D = $CollectArea


func _ready():
	# Connect collection
	if collect_area:
		collect_area.body_entered.connect(_on_body_entered)
	
	# Start animation
	if sprite and sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
	
	# Random initial velocity for scatter effect
	_velocity = Vector2(randf_range(-100, 100), randf_range(-150, -50))


func _physics_process(delta):
	_elapsed += delta
	
	# Lifetime check
	if _elapsed >= lifetime:
		queue_free()
		return
	
	# Apply scatter velocity initially
	if _velocity.length() > 10:
		position += _velocity * delta
		_velocity = _velocity.move_toward(Vector2.ZERO, 300 * delta)
	else:
		# Check for nearby player to attract
		_find_nearby_player()
		
		if _target_player and is_instance_valid(_target_player):
			var dir = (_target_player.global_position - global_position).normalized()
			var dist = global_position.distance_to(_target_player.global_position)
			
			if dist <= collect_range:
				_collect()
			elif dist <= attract_range:
				_is_attracting = true
				position += dir * attract_speed * delta


func _find_nearby_player():
	if _target_player != null:
		return
	
	var players = get_tree().get_nodes_in_group(player_group_name)
	for player in players:
		if is_instance_valid(player):
			var dist = global_position.distance_to(player.global_position)
			if dist <= attract_range:
				_target_player = player
				return


func _on_body_entered(body):
	if body.is_in_group(player_group_name):
		_collect()


func _collect():
	# Add coins to manager
	CoinManager.add_coins(value)
	
	# Spawn collect effect/number
	DamageNumbers.spawn_custom(global_position, "+%d" % value, Color(1.0, 0.85, 0.2), 18)
	
	queue_free()


func setup(coin_value: int, start_pos: Vector2):
	value = coin_value
	global_position = start_pos
