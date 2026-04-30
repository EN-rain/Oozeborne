extends Control
class_name LoadingScreen

## Loading Screen - Shows player character while waiting for all players to load
## After loading, fades in environment elements one by one

signal loading_complete
signal all_players_ready

@export_file("*.tscn") var main_game_scene_path: String = "res://scenes/levels/main.tscn"
@export_file("*.tscn") var class_selection_scene_path: String = "res://scenes/ui/class_selection.tscn"
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

var _remote_player_displays: Array[AnimatedSprite2D] = []

var _is_loading: bool = false
var _loading_progress: float = 0.0
var _players_loaded: Dictionary = {}  # user_id -> bool
var _expected_player_count: int = 0
var _needs_class_selection: bool = false


func _ready() -> void:
	_setup_signals()
	_setup_player_display()
	# Defer remote display setup so MultiplayerManager.players can populate from lobby state
	_remote_player_displays_ready.call_deferred()
	_start_loading()


func _setup_signals() -> void:
	if MultiplayerManager.socket:
		if not MultiplayerManager.received_match_state.is_connected(_on_match_state):
			MultiplayerManager.received_match_state.connect(_on_match_state)
	if not MultiplayerManager.player_joined.is_connected(_on_player_joined):
		MultiplayerManager.player_joined.connect(_on_player_joined)
	if not MultiplayerManager.player_left.is_connected(_on_player_left):
		MultiplayerManager.player_left.connect(_on_player_left)


func _setup_player_display() -> void:
	# Set local player sprite based on slime variant
	var local_variant: String = MultiplayerManager.player_slime_variant
	var scene_path: String = SlimePaletteRegistry.get_scene_path(local_variant)
	var player_scene_res = load(scene_path) as PackedScene
	if player_scene_res != null:
		var instance = player_scene_res.instantiate()
		if instance.has_node("AnimatedSprite2D"):
			var sprite = instance.get_node("AnimatedSprite2D")
			# Copy the shader material for correct slime color
			if sprite.material != null:
				player_display.material = sprite.material.duplicate()
			if sprite.sprite_frames != null:
				player_display.sprite_frames = sprite.sprite_frames.duplicate()
				if player_display.sprite_frames.has_animation("idle"):
					player_display.play("idle")
			player_display.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		instance.queue_free()
	
	# Position local player at bottom center
	player_display.position = Vector2(get_viewport_rect().size.x / 2, get_viewport_rect().size.y - 100)
	player_display.modulate.a = 0.0
	
	# Remote player displays are set up after a deferred call


func _remote_player_displays_ready() -> void:
	_setup_remote_player_displays()
	# Fade in any newly created remote displays
	for r_display in _remote_player_displays:
		if is_instance_valid(r_display) and r_display.modulate.a < 1.0:
			var r_tween = create_tween()
			r_tween.tween_property(r_display, "modulate:a", 1.0, 0.5)


func _setup_remote_player_displays() -> void:
	# Clear any existing remote displays
	for old_display in _remote_player_displays:
		if is_instance_valid(old_display):
			old_display.queue_free()
	_remote_player_displays.clear()
	
	var viewport_width = get_viewport_rect().size.x
	var all_players = MultiplayerManager.players.keys()
	# Include local player in the count for positioning
	var total_count = all_players.size()
	if total_count <= 1:
		return  # Only local player, no remote displays needed
	
	# Calculate spacing: spread players evenly across bottom
	var spacing = viewport_width / (total_count + 1)
	
	# Reposition local player display
	var local_index = 0
	if MultiplayerManager.is_authenticated():
		local_index = all_players.find(MultiplayerManager.user_id)
		if local_index < 0:
			local_index = 0
	player_display.position = Vector2(spacing * (local_index + 1), get_viewport_rect().size.y - 100)
	
	# Create displays for each remote player
	var _remote_idx = 0
	for i in range(all_players.size()):
		var user_id = all_players[i]
		if MultiplayerManager.is_authenticated() and user_id == MultiplayerManager.user_id:
			continue  # Skip local player
		
		var player_info = MultiplayerManager.players.get(user_id, {})
		var variant: String = str(player_info.get("slime_variant", "blue"))
		var r_scene_path: String = SlimePaletteRegistry.get_scene_path(variant)
		var r_scene = load(r_scene_path) as PackedScene
		if r_scene == null:
			continue
		
		var r_instance = r_scene.instantiate()
		var r_sprite: AnimatedSprite2D = null
		if r_instance.has_node("AnimatedSprite2D"):
			var source_sprite = r_instance.get_node("AnimatedSprite2D")
			if source_sprite.sprite_frames != null:
				r_sprite = AnimatedSprite2D.new()
				# Copy the shader material for correct slime color
				if source_sprite.material != null:
					r_sprite.material = source_sprite.material.duplicate()
				r_sprite.sprite_frames = source_sprite.sprite_frames.duplicate()
				r_sprite.scale = player_display.scale
				r_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
				if r_sprite.sprite_frames.has_animation("idle"):
					r_sprite.play("idle")
				r_sprite.position = Vector2(spacing * (i + 1), get_viewport_rect().size.y - 100)
				r_sprite.modulate.a = 0.0
				add_child(r_sprite)
				_remote_player_displays.append(r_sprite)
		r_instance.queue_free()
		_remote_idx += 1


func _start_loading() -> void:
	_is_loading = true
	_loading_progress = 0.0
	_expected_player_count = _get_expected_player_count()
	
	# Check if player needs class selection (only for solo play, multiplayer selects in lobby)
	_needs_class_selection = MultiplayerManager.player_class == null and not MultiplayerManager.is_socket_open()
	
	# Register self as loaded
	var my_user_id = MultiplayerManager.user_id if MultiplayerManager.is_authenticated() else "local"
	_players_loaded[my_user_id] = true
	
	# Broadcast that we're loaded
	_broadcast_loaded()
	
	# Start loading animation
	_animate_loading()


func _animate_loading() -> void:
	# Fade in player(s)
	var tween = create_tween()
	tween.tween_property(player_display, "modulate:a", 1.0, 0.5)
	for r_display in _remote_player_displays:
		if is_instance_valid(r_display):
			var r_tween = create_tween()
			r_tween.tween_property(r_display, "modulate:a", 1.0, 0.5)
	
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
			"user_id": MultiplayerManager.user_id if MultiplayerManager.is_authenticated() else "local"
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
		elif msg_type == "player_info":
			var user_id = str(data.get("user_id", ""))
			var slime_variant = str(data.get("slime_variant", "blue"))
			if MultiplayerManager.is_authenticated() and user_id == MultiplayerManager.user_id:
				# Local player echo - don't overwrite, just ensure display is using current variant
				_setup_player_display()
			else:
				# Update remote player's slime variant in MultiplayerManager.players
				if MultiplayerManager.players.has(user_id):
					MultiplayerManager.players[user_id]["slime_variant"] = slime_variant
				# Refresh remote player displays
				_setup_remote_player_displays()
		elif msg_type == "class_selected":
			var user_id = str(data.get("user_id", ""))
			var slime_variant = str(data.get("slime_variant", "blue"))
			if not user_id.is_empty():
				if MultiplayerManager.is_authenticated() and user_id == MultiplayerManager.user_id:
					_setup_player_display()
				else:
					if MultiplayerManager.players.has(user_id):
						MultiplayerManager.players[user_id]["slime_variant"] = slime_variant
					_setup_remote_player_displays()
		return

	if match_state.op_code == MultiplayerUtils.OP_STATE and data.has("players"):
		_expected_player_count = max(_expected_player_count, int(data["players"].size()))
		_update_player_count_display()


func _on_player_joined(_user_id: String, _ign: String, _is_host: bool) -> void:
	_expected_player_count = _get_expected_player_count()
	_update_player_count_display()
	_setup_remote_player_displays()


func _on_player_left(_user_id: String) -> void:
	_expected_player_count = _get_expected_player_count()
	_update_player_count_display()
	_setup_remote_player_displays()


func _get_expected_player_count() -> int:
	var count := MultiplayerManager.players.size()
	if MultiplayerManager.is_authenticated() and not MultiplayerManager.players.has(MultiplayerManager.user_id):
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
	var scene_to_load_path: String = ""
	if _needs_class_selection:
		scene_to_load_path = class_selection_scene_path
	else:
		scene_to_load_path = main_game_scene_path
	
	# Fade out and change scene
	var tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	if not scene_to_load_path.is_empty():
		get_tree().change_scene_to_file(scene_to_load_path)


func _exit_tree() -> void:
	if MultiplayerManager.socket and MultiplayerManager.received_match_state.is_connected(_on_match_state):
		MultiplayerManager.received_match_state.disconnect(_on_match_state)
	if MultiplayerManager.player_joined.is_connected(_on_player_joined):
		MultiplayerManager.player_joined.disconnect(_on_player_joined)
	if MultiplayerManager.player_left.is_connected(_on_player_left):
		MultiplayerManager.player_left.disconnect(_on_player_left)
