extends Control
class_name LoadingScreen

## Loading Screen - Shows player character while waiting for all players to load
## After loading, fades in environment elements one by one

signal loading_complete
signal all_players_ready

@export var main_game_scene_path: String = "res://scenes/levels/main.tscn"
@export var class_selection_scene_path: String = "res://scenes/ui/class_selection.tscn"
@export var min_loading_time: float = 2.0
@export var fade_in_delay: float = 0.3
@export var environment_fade_interval: float = 0.15

@onready var player_display: AnimatedSprite2D = $PlayerDisplay
@onready var loading_bar: ProgressBar = $LoadingBar
@onready var loading_label: Label = $LoadingLabel
@onready var player_count_label: Label = $PlayerCountLabel
@onready var environment_container: Node2D = $EnvironmentContainer
@onready var background: ColorRect = $Background
@onready var fade_overlay: ColorRect = $FadeOverlay

var _is_loading: bool = false
var _loading_progress: float = 0.0
var _players_loaded: Dictionary = {}  # user_id -> bool
var _expected_player_count: int = 0
var _scene_to_load: String = ""
var _needs_class_selection: bool = false


func _ready() -> void:
	_setup_signals()
	_setup_player_display()
	_start_loading()


func _setup_signals() -> void:
	if MultiplayerManager.socket:
		if not MultiplayerManager.socket.received_match_state.is_connected(_on_match_state):
			MultiplayerManager.socket.received_match_state.connect(_on_match_state)
	if not MultiplayerManager.player_joined.is_connected(_on_player_joined):
		MultiplayerManager.player_joined.connect(_on_player_joined)
	if not MultiplayerManager.player_left.is_connected(_on_player_left):
		MultiplayerManager.player_left.connect(_on_player_left)


func _setup_player_display() -> void:
	# Set player sprite based on selected class
	var player_class = MultiplayerManager.player_class
	if player_class != null and player_class.player_scene != null:
		# Use class-specific player scene
		var instance = player_class.player_scene.instantiate()
		if instance.has_node("AnimatedSprite2D"):
			var sprite = instance.get_node("AnimatedSprite2D")
			player_display.sprite_frames = sprite.sprite_frames
			player_display.play("idle")
		instance.queue_free()
	else:
		# Default idle animation
		if player_display.sprite_frames != null:
			player_display.play("idle")
	
	# Position player at bottom center
	player_display.position = Vector2(get_viewport_rect().size.x / 2, get_viewport_rect().size.y - 100)
	player_display.modulate.a = 0.0


func _start_loading() -> void:
	_is_loading = true
	_loading_progress = 0.0
	_expected_player_count = _get_expected_player_count()
	
	# Check if player needs class selection
	_needs_class_selection = MultiplayerManager.player_class == null
	
	# Register self as loaded
	var my_user_id = MultiplayerManager.session.user_id if MultiplayerManager.session else "local"
	_players_loaded[my_user_id] = true
	
	# Broadcast that we're loaded
	_broadcast_loaded()
	
	# Start loading animation
	_animate_loading()


func _animate_loading() -> void:
	# Fade in player
	var tween = create_tween()
	tween.tween_property(player_display, "modulate:a", 1.0, 0.5)
	
	# Animate loading bar
	while _loading_progress < 1.0:
		_loading_progress += 0.02
		loading_bar.value = _loading_progress * 100
		
		# Update player count display
		_update_player_count_display()
		
		# Check if all players loaded
		if _are_all_players_loaded() and _loading_progress >= 1.0:
			break
		
		await get_tree().create_timer(0.05).timeout
	
	# Ensure minimum loading time
	await get_tree().create_timer(max(0, min_loading_time - (min_loading_time * _loading_progress))).timeout
	
	# All players ready - start environment fade-in
	_on_all_players_ready()


func _update_player_count_display() -> void:
	var loaded_count = _players_loaded.values().filter(func(v): return v == true).size()
	player_count_label.text = "Players Ready: %d / %d" % [loaded_count, max(_expected_player_count, loaded_count)]


func _are_all_players_loaded() -> bool:
	if _expected_player_count <= 0:
		return true
	return _players_loaded.values().filter(func(v): return v == true).size() >= _expected_player_count


func _broadcast_loaded() -> void:
	if MultiplayerManager.is_socket_open() and not MultiplayerManager.match_id.is_empty():
		MultiplayerManager.send_match_state({
			"type": "player_loaded",
			"user_id": MultiplayerManager.session.user_id if MultiplayerManager.session else "local"
		})


func _on_match_state(match_state) -> void:
	var data = JSON.parse_string(match_state.data)
	if data == null:
		return

	if match_state.op_code == 0:
		var msg_type = str(data.get("type", ""))
		if msg_type == "player_loaded":
			var user_id = str(data.get("user_id", ""))
			if not user_id.is_empty():
				_players_loaded[user_id] = true
				_update_player_count_display()
		return

	if match_state.op_code == MultiplayerUtils.OP_STATE and data.has("players"):
		_expected_player_count = max(_expected_player_count, int(data["players"].size()))
		_update_player_count_display()


func _on_player_joined(_user_id: String, _ign: String, _is_host: bool) -> void:
	_expected_player_count = _get_expected_player_count()
	_update_player_count_display()


func _on_player_left(_user_id: String) -> void:
	_expected_player_count = _get_expected_player_count()
	_update_player_count_display()


func _get_expected_player_count() -> int:
	var count := MultiplayerManager.players.size()
	if MultiplayerManager.session != null and not MultiplayerManager.players.has(MultiplayerManager.session.user_id):
		count += 1
	return max(1, count)


func _on_all_players_ready() -> void:
	loading_label.text = "Ready!"
	all_players_ready.emit()
	
	# Fade in environment elements one by one
	await _fade_in_environment()
	
	# Transition to next scene
	_transition_to_next_scene()


func _fade_in_environment() -> void:
	# Show environment container
	environment_container.visible = true
	
	# Fade in each child with delay
	for child in environment_container.get_children():
		if child is CanvasItem:
			child.modulate.a = 0.0
	
	for child in environment_container.get_children():
		if child is CanvasItem:
			var tween = create_tween()
			tween.tween_property(child, "modulate:a", 1.0, 0.3)
			await get_tree().create_timer(environment_fade_interval).timeout
	
	# Final fade overlay
	var final_tween = create_tween()
	final_tween.tween_property(fade_overlay, "modulate:a", 0.0, 0.5)
	await get_tree().create_timer(0.5).timeout


func _transition_to_next_scene() -> void:
	loading_complete.emit()
	
	# Determine which scene to load
	if _needs_class_selection:
		_scene_to_load = class_selection_scene_path
	else:
		_scene_to_load = main_game_scene_path
	
	# Fade out and change scene
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	get_tree().change_scene_to_file(_scene_to_load)


func _exit_tree() -> void:
	if MultiplayerManager.socket and MultiplayerManager.socket.received_match_state.is_connected(_on_match_state):
		MultiplayerManager.socket.received_match_state.disconnect(_on_match_state)
	if MultiplayerManager.player_joined.is_connected(_on_player_joined):
		MultiplayerManager.player_joined.disconnect(_on_player_joined)
	if MultiplayerManager.player_left.is_connected(_on_player_left):
		MultiplayerManager.player_left.disconnect(_on_player_left)
