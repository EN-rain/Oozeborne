extends Control

class_name HudMinimap

var player_ref: CharacterBody2D
var slimes: Array = []
var minimap_size: Vector2 = Vector2(212, 169)
var remote_players: Dictionary = {}
var world_size: Vector2 = Vector2(800, 600)

@export var player_color: Color = Color.GREEN
@export var remote_player_color: Color = Color.GREEN
@export var slime_color: Color = Color.RED
@export var lancer_color: Color = Color.PURPLE
@export var archer_color: Color = Color.ORANGE
@export var player_size: float = 8.0
@export var remote_player_size: float = 6.0
@export var slime_size: float = 4.0
@export var elite_size: float = 5.0
@export var minimap_background_color: Color = Color(0.04, 0.07, 0.11, 0.88)
@export var minimap_grid_color: Color = Color(0.55, 0.78, 0.92, 0.14)
@export var minimap_ring_color: Color = Color(0.72, 0.9, 1.0, 0.2)
@export var minimap_outline_color: Color = Color(0.82, 0.95, 1.0, 0.55)
@export var minimap_world_radius: float = 950.0
@export var map_bounds_group_name: StringName = &"map_bounds"
@export var environment_group_name: StringName = &"environment"
@export_range(0.02, 0.5, 0.01) var redraw_interval_sec: float = 0.08

const DEFAULT_MINIMAP_BACKGROUND_COLOR := Color(0.04, 0.07, 0.11, 0.88)
const DEFAULT_MINIMAP_GRID_COLOR := Color(0.55, 0.78, 0.92, 0.14)
const DEFAULT_MINIMAP_RING_COLOR := Color(0.72, 0.9, 1.0, 0.2)
const DEFAULT_MINIMAP_OUTLINE_COLOR := Color(0.82, 0.95, 1.0, 0.55)

var _redraw_accumulator: float = 0.0
var _minimap_dirty: bool = true
var _cached_map_bounds: ReferenceRect = null
var _ping_label: Label = null


func _ready() -> void:
	if not is_inside_tree():
		return
	resized.connect(_on_resized)
	_find_map_bounds()
	_refresh_minimap_size()
	visible = true
	if not draw.is_connected(_draw_minimap):
		draw.connect(_draw_minimap)
	# Create ping indicator label
	_ping_label = Label.new()
	_ping_label.name = "PingLabel"
	_ping_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ping_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_ping_label.add_theme_font_size_override("font_size", 10)
	_ping_label.position = Vector2(0, 0)
	_ping_label.size = Vector2(minimap_size.x, 14)
	_ping_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ping_label)
	if Engine.is_editor_hint():
		queue_minimap_redraw()


func _process(_delta: float) -> void:
	if not is_inside_tree():
		return
	_redraw_accumulator += _delta
	if _redraw_accumulator < redraw_interval_sec and not _minimap_dirty:
		return
	_redraw_accumulator = 0.0
	_refresh_minimap_size()
	_update_ping_label()
	queue_minimap_redraw()


func set_player(player: CharacterBody2D) -> void:
	player_ref = player
	visible = true
	queue_minimap_redraw()


func register_slime(slime: Node) -> void:
	if slime not in slimes:
		slimes.append(slime)
		slime.tree_exiting.connect(_on_slime_removed.bind(slime))
		queue_minimap_redraw()


func register_remote_player(user_id: String, ign: String) -> void:
	remote_players[user_id] = {"pos": Vector2.ZERO, "ign": ign}
	queue_minimap_redraw()


func update_remote_player_ign(user_id: String, ign: String) -> void:
	if remote_players.has(user_id):
		remote_players[user_id]["ign"] = ign
		queue_minimap_redraw()


func update_remote_player_pos(user_id: String, pos: Vector2) -> void:
	if remote_players.has(user_id):
		remote_players[user_id]["pos"] = pos
		queue_minimap_redraw()


func unregister_remote_player(user_id: String) -> void:
	remote_players.erase(user_id)
	queue_minimap_redraw()


func queue_minimap_redraw() -> void:
	if not is_inside_tree():
		return
	_minimap_dirty = false
	queue_redraw()


func _on_slime_removed(slime: Node) -> void:
	slimes.erase(slime)
	queue_minimap_redraw()


func _find_map_bounds() -> void:
	if not is_inside_tree():
		return
	if _cached_map_bounds != null and is_instance_valid(_cached_map_bounds):
		world_size = _cached_map_bounds.size
		_minimap_dirty = true
		return
	var map_bounds = get_tree().get_first_node_in_group(map_bounds_group_name)
	if map_bounds == null:
		var env = get_tree().get_first_node_in_group(environment_group_name)
		if env:
			map_bounds = env.get_node_or_null("MapBounds")
		if map_bounds == null:
			for node in get_tree().get_nodes_in_group(map_bounds_group_name):
				map_bounds = node
				break
			if map_bounds == null:
				map_bounds = get_tree().root.find_child("MapBounds", true, false)
	if map_bounds and map_bounds is ReferenceRect:
		_cached_map_bounds = map_bounds as ReferenceRect
		world_size = _cached_map_bounds.size
	else:
		push_warning("[Minimap] MapBounds node not found, using default world_size: %s" % world_size)
	_minimap_dirty = true
	queue_minimap_redraw()


func _draw_minimap() -> void:
	var minimap_rect := Rect2(Vector2.ZERO, minimap_size)
	draw_rect(minimap_rect, _safe_color(minimap_background_color, DEFAULT_MINIMAP_BACKGROUND_COLOR))
	draw_rect(minimap_rect.grow(-1.0), Color(0.08, 0.14, 0.2, 0.5), false, 2.0)
	_draw_minimap_grid()

	if Engine.is_editor_hint():
		var preview_center := minimap_size / 2.0
		_draw_center_focus(preview_center)
		draw_circle(preview_center, player_size, Color(0.25, 0.95, 0.45, 0.9))
		return

	if not player_ref or not is_instance_valid(player_ref):
		return

	var player_minimap_pos := minimap_size / 2
	_draw_center_focus(player_minimap_pos)
	draw_circle(player_minimap_pos, player_size + 3.0, Color(0, 0, 0, 0.35))
	draw_circle(player_minimap_pos, player_size, player_color)

	var minimap_radius := _get_minimap_draw_radius()
	for enemy in slimes:
		if not is_instance_valid(enemy):
			continue
		var enemy_minimap_pos := world_to_minimap(enemy.global_position, player_minimap_pos, minimap_radius)
		enemy_minimap_pos = clamp_to_minimap(enemy_minimap_pos)

		var enemy_color := slime_color
		var enemy_size := slime_size
		if enemy.get_script():
			var script_path: String = str(enemy.get_script().resource_path)
			if "lancer" in script_path.to_lower():
				enemy_color = lancer_color
				enemy_size = elite_size
			elif "archer" in script_path.to_lower():
				enemy_color = archer_color
				enemy_size = elite_size

		draw_circle(enemy_minimap_pos, enemy_size + 2.0, Color(0, 0, 0, 0.35))
		draw_circle(enemy_minimap_pos, enemy_size, enemy_color)

	for user_id in remote_players:
		var rp_data = remote_players[user_id]
		var rp_pos: Vector2 = rp_data["pos"]
		var rp_minimap_pos := world_to_minimap(rp_pos, player_minimap_pos, minimap_radius)
		rp_minimap_pos = clamp_to_minimap(rp_minimap_pos)
		draw_circle(rp_minimap_pos, remote_player_size + 2.0, Color(0, 0, 0, 0.35))
		draw_circle(rp_minimap_pos, remote_player_size, remote_player_color)


func _draw_minimap_grid() -> void:
	var center := minimap_size / 2.0
	var grid_color := _safe_color(minimap_grid_color, DEFAULT_MINIMAP_GRID_COLOR)
	var ring_color := _safe_color(minimap_ring_color, DEFAULT_MINIMAP_RING_COLOR)
	draw_line(Vector2(center.x, 0), Vector2(center.x, minimap_size.y), grid_color, 1.0)
	draw_line(Vector2(0, center.y), Vector2(minimap_size.x, center.y), grid_color, 1.0)
	draw_arc(center, min(minimap_size.x, minimap_size.y) * 0.28, 0.0, TAU, 48, ring_color, 1.0)
	draw_arc(center, min(minimap_size.x, minimap_size.y) * 0.44, 0.0, TAU, 48, ring_color, 1.0)


func _draw_center_focus(center: Vector2) -> void:
	draw_circle(center, 12.0, Color(1, 1, 1, 0.04))
	draw_arc(center, 16.0, 0.0, TAU, 32, _safe_color(minimap_outline_color, DEFAULT_MINIMAP_OUTLINE_COLOR), 1.0)


func _get_minimap_draw_radius() -> float:
	return max(min(minimap_size.x, minimap_size.y) * 0.5 - 12.0, 1.0)


func world_to_minimap(world_pos: Vector2, center: Vector2, minimap_radius: float) -> Vector2:
	var relative_pos: Vector2 = world_pos - player_ref.global_position
	var distance: float = relative_pos.length()
	if distance <= 0.001:
		return center
	var distance_scale: float = min(distance / minimap_world_radius, 1.0)
	return center + relative_pos.normalized() * (distance_scale * minimap_radius)


func clamp_to_minimap(pos: Vector2) -> Vector2:
	var center := minimap_size * 0.5
	var radial_offset: Vector2 = pos - center
	var max_radius: float = _get_minimap_draw_radius()
	if radial_offset.length() > max_radius:
		radial_offset = radial_offset.normalized() * max_radius
		pos = center + radial_offset
	return Vector2(
		clamp(pos.x, slime_size, minimap_size.x - slime_size),
		clamp(pos.y, slime_size, minimap_size.y - slime_size)
	)


func _refresh_minimap_size() -> void:
	var current_size := size
	if current_size.x <= 0.0 or current_size.y <= 0.0:
		current_size = custom_minimum_size
		if current_size.x <= 0.0 or current_size.y <= 0.0:
			return
	minimap_size = current_size
	_minimap_dirty = true


func _on_resized() -> void:
	_refresh_minimap_size()
	_minimap_dirty = true
	if _ping_label:
		_ping_label.size = Vector2(minimap_size.x, 14)
	queue_minimap_redraw()

func _update_ping_label() -> void:
	if _ping_label == null:
		return
	var ping_ms := int(MultiplayerUtils.get_ping() * 1000)
	var color: Color
	if ping_ms < 50:
		color = Color(0.4, 1.0, 0.4, 0.8)  # Green
	elif ping_ms < 100:
		color = Color(1.0, 0.9, 0.3, 0.8)  # Yellow
	else:
		color = Color(1.0, 0.35, 0.35, 0.8)  # Red
	_ping_label.add_theme_color_override("font_color", color)
	_ping_label.text = "%d ms" % ping_ms


func _safe_color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	return fallback
