extends Node
signal active_class_changed(active_class)

const CAROUSEL_SLOT_RELS := [-2, -1, 0, 1, 2]

@export var drag_snap_distance: float = 140.0
@export var drag_trigger_distance: float = 55.0
@export var class_name_idle_pulse_speed: float = 3.2
@export var class_name_idle_lift: float = 5.0
@export var class_name_center_scale: float = 1.16
@export var class_name_side_alpha: float = 0.72

@export var slime_preview_shader: Shader

var _preview_slime_variants: Dictionary = {}
var _slime_rng := RandomNumberGenerator.new()
var _view: RoomLobbyView
var _class_slots: Array = []
var _left_button: Button
var _right_button: Button
var _current_class_index: int = 0
var _carousel_nodes: Array = []
var _carousel_layouts: Array = []
var _carousel_slot_refs: Array = []
var _carousel_progress: float = 0.0
var _is_dragging_carousel: bool = false
var _interaction_enabled: bool = true
var _drag_start_pos := Vector2.ZERO
var _drag_delta_x: float = 0.0
var _carousel_tween: Tween = null
var _carousel_idle_time: float = 0.0
var _last_active_class_name: String = ""
var _base_viewport_size: Vector2 = Vector2(1920.0, 1080.0)
var _viewport_scale: float = 1.0
var _base_sprite_position: Vector2 = Vector2(128, 170)
var _base_label_offsets: Dictionary = {"left": -60.0, "top": 3.0, "right": 60.0, "bottom": 26.0}
var _base_sprite_scale: Vector2 = Vector2.ONE
var _base_font_size: int = 12
func setup(view: RoomLobbyView, class_slots: Array, left_button: Button, right_button: Button) -> void:
	_view = view
	_class_slots = class_slots
	_left_button = left_button
	_right_button = right_button
	_slime_rng.randomize()
	if is_instance_valid(_left_button) and not _left_button.pressed.is_connected(_on_left_pressed):
		_left_button.pressed.connect(_on_left_pressed)
	if is_instance_valid(_right_button) and not _right_button.pressed.is_connected(_on_right_pressed):
		_right_button.pressed.connect(_on_right_pressed)
	_assign_random_preview_variants()
	_setup_carousel()
	render_carousel(0.0)


func get_active_class_name() -> String:
	if _view == null:
		return ""
	return _view.get_class_order()[_wrap_class_index(_current_class_index)]


func get_slime_scene_path_for_class(_selected_name: String) -> String:
	return SlimePaletteRegistry.get_scene_path(MultiplayerManager.player_slime_variant)


func render_carousel(progress: float = 0.0) -> void:
	_render_carousel(progress)


func move_left() -> void:
	if not _interaction_enabled:
		return
	_on_left_pressed()


func move_right() -> void:
	if not _interaction_enabled:
		return
	_on_right_pressed()


func set_interaction_enabled(enabled: bool) -> void:
	_interaction_enabled = enabled
	_is_dragging_carousel = false
	_drag_delta_x = 0.0
	if is_instance_valid(_left_button):
		_left_button.disabled = not enabled
	if is_instance_valid(_right_button):
		_right_button.disabled = not enabled
	if not enabled:
		_animate_carousel_back_to_center(0.1)


func _process(delta: float) -> void:
	_carousel_idle_time += delta
	_update_viewport_scale()
	if _carousel_nodes.is_empty() or _is_dragging_carousel:
		return
	if _carousel_tween != null and _carousel_tween.is_running():
		return
	_render_carousel(0.0)


func _input(event: InputEvent) -> void:
	if _carousel_nodes.is_empty() or not _interaction_enabled:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _is_in_carousel_area(event.position):
			_is_dragging_carousel = true
			_drag_start_pos = event.position
			_drag_delta_x = 0.0
			if _carousel_tween:
				_carousel_tween.kill()
			get_viewport().set_input_as_handled()
			return

		if not event.pressed and _is_dragging_carousel:
			_is_dragging_carousel = false
			if abs(_drag_delta_x) >= drag_trigger_distance:
				_animate_carousel_shift(1 if _drag_delta_x < 0.0 else -1)
			else:
				var clicked_slot_idx: int = _get_clicked_carousel_slot_index(event.position)
				if clicked_slot_idx != -1:
					var clicked_rel: int = CAROUSEL_SLOT_RELS[clicked_slot_idx]
					if clicked_rel != 0:
						_animate_carousel_shift(clicked_rel)
					else:
						_animate_carousel_back_to_center(0.12)
				else:
					_animate_carousel_back_to_center(0.12)
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion and _is_dragging_carousel:
		_drag_delta_x = event.position.x - _drag_start_pos.x
		_render_carousel(clamp(_drag_delta_x / drag_snap_distance, -1.0, 1.0))
		get_viewport().set_input_as_handled()


func _setup_carousel() -> void:
	if _class_slots.size() < 5:
		return
	_carousel_nodes = [_class_slots[3], _class_slots[4], _class_slots[0], _class_slots[2], _class_slots[1]]
	_carousel_layouts.clear()
	_carousel_slot_refs.clear()
	var center_slot: Control = _class_slots[0]
	var baseline_y: float = 0.0
	for slot in _carousel_nodes:
		baseline_y += slot.position.y
	baseline_y /= float(_carousel_nodes.size())
	var center_sprite: AnimatedSprite2D = center_slot.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var center_label: Label = center_slot.get_node_or_null("ClassName") as Label
	_base_sprite_position = center_sprite.position if center_sprite else Vector2(128, 170)
	if center_label:
		_base_label_offsets = {
			"left": center_label.offset_left,
			"top": center_label.offset_top,
			"right": center_label.offset_right,
			"bottom": center_label.offset_bottom,
		}
	_base_sprite_scale = center_sprite.scale if center_sprite else Vector2.ONE
	_base_font_size = center_label.get_theme_font_size("font_size") if center_label else 12

	for slot in _carousel_nodes:
		var sprite: AnimatedSprite2D = slot.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		var name_label: Label = slot.get_node_or_null("ClassName") as Label
		if sprite:
			var material := ShaderMaterial.new()
			material.shader = slime_preview_shader
			sprite.material = material
			sprite.play("idle")
			sprite.stop()
			sprite.frame = 0
		_carousel_slot_refs.append({
			"node": slot,
			"sprite": sprite,
			"label": name_label,
		})
		var flat_position: Vector2 = Vector2(slot.position.x, baseline_y)
		slot.position = flat_position
		if sprite:
			sprite.position = _base_sprite_position
		if name_label:
			name_label.offset_left = _base_label_offsets["left"]
			name_label.offset_top = _base_label_offsets["top"]
			name_label.offset_right = _base_label_offsets["right"]
			name_label.offset_bottom = _base_label_offsets["bottom"]
		_carousel_layouts.append({
			"position": flat_position,
			"scale": _base_sprite_scale,
			"font_size": _base_font_size,
			"label_top": _base_label_offsets["top"],
			"label_bottom": _base_label_offsets["bottom"],
		})


func _wrap_class_index(index: int) -> int:
	var count = _view.get_class_order().size()
	return ((index % count) + count) % count


func _get_class_name_for_slot(slot_idx: int) -> String:
	var class_idx = _wrap_class_index(_current_class_index + CAROUSEL_SLOT_RELS[slot_idx])
	return _view.get_class_order()[class_idx]


func _render_carousel(progress: float = 0.0) -> void:
	_carousel_progress = clamp(progress, -1.0, 1.0)
	var direction = 0
	if _carousel_progress < 0.0:
		direction = -1
	elif _carousel_progress > 0.0:
		direction = 1
	var t = abs(_carousel_progress)

	for slot_idx in range(_carousel_slot_refs.size()):
		var slot_ref: Dictionary = _carousel_slot_refs[slot_idx]
		var slot: Control = slot_ref["node"]
		var target_idx = wrapi(slot_idx + direction, 0, _carousel_layouts.size()) if direction != 0 else slot_idx
		var from_layout = _carousel_layouts[slot_idx]
		var to_layout = _carousel_layouts[target_idx]
		var sprite: AnimatedSprite2D = slot_ref["sprite"]
		var name_label: Label = slot_ref["label"]

		slot.position = from_layout["position"].lerp(to_layout["position"], t)
		if sprite:
			sprite.scale = from_layout["scale"].lerp(to_layout["scale"], t)
			var is_center_slot := slot_idx == 2 and direction == 0
			if is_center_slot:
				if sprite.animation != "idle":
					sprite.play("idle")
				elif not sprite.is_playing():
					sprite.play()
				sprite.speed_scale = 1.0
			else:
				if sprite.animation != "idle":
					sprite.play("idle")
				sprite.stop()
				sprite.frame = 0
				sprite.speed_scale = 1.0
			_apply_preview_slime_to_sprite(sprite, _get_class_name_for_slot(slot_idx))
		if name_label:
			name_label.text = _get_class_name_for_slot(slot_idx)
			var from_center_weight: float = float(abs(slot_idx - 2))
			var to_center_weight: float = float(abs(target_idx - 2))
			var blended_center_weight: float = float(lerp(from_center_weight, to_center_weight, t))
			var focus: float = float(clamp(1.0 - blended_center_weight * 0.52, 0.0, 1.0))
			var pulse: float = 0.0
			if direction == 0:
				pulse = float(max(sin(_carousel_idle_time * class_name_idle_pulse_speed), 0.0) * focus)
			var font_size: float = float(lerp(float(from_layout["font_size"]), float(to_layout["font_size"]), t) + focus * 3.0 + pulse * 2.0)
			name_label.add_theme_font_size_override("font_size", roundi(font_size))
			name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			name_label.scale = Vector2.ONE.lerp(Vector2.ONE * class_name_center_scale, focus)
			name_label.scale += Vector2.ONE * pulse * 0.03
			var label_top: float = float(from_layout["label_top"])
			var label_bottom: float = float(from_layout["label_bottom"])
			var lift: float = 0.0
			if direction == 0:
				label_top = float(to_layout["label_top"])
				label_bottom = float(to_layout["label_bottom"])
				lift = float(focus * 8.0 + pulse * class_name_idle_lift)
			name_label.offset_top = label_top - lift
			name_label.offset_bottom = label_bottom - lift
			name_label.modulate = Color(1, 1, 1, clamp(class_name_side_alpha + focus * 0.48 + pulse * 0.08, 0.0, 1.0))

		var center_weight = abs((slot_idx - 2) + _carousel_progress)
		var alpha = clamp(1.0 - center_weight * 0.22, 0.3, 1.0)
		slot.modulate = Color(1, 1, 1, alpha)
		slot.z_index = 10 - int(center_weight * 10.0)

	if direction == 0 and _view != null:
		var active_class_name := get_active_class_name()
		_view.update_active_class_panels(active_class_name)
		if active_class_name != _last_active_class_name:
			_last_active_class_name = active_class_name
			active_class_changed.emit(active_class_name)


func _animate_carousel_back_to_center(duration: float = 0.16) -> void:
	if _carousel_tween:
		_carousel_tween.kill()
	_carousel_tween = create_tween()
	_carousel_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_carousel_tween.tween_method(_render_carousel, _carousel_progress, 0.0, duration)


func _animate_carousel_shift(step: int) -> void:
	if step == 0:
		_animate_carousel_back_to_center(0.12)
		return
	if _carousel_tween:
		_carousel_tween.kill()

	var direction: int = 1 if step > 0 else -1
	var segments: int = abs(step)
	_run_carousel_shift_segment(direction, segments)


func _run_carousel_shift_segment(direction: int, remaining_segments: int) -> void:
	if remaining_segments <= 0:
		_render_carousel(0.0)
		return

	var target_progress: float = -1.0 if direction > 0 else 1.0
	_carousel_tween = create_tween()
	_carousel_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_carousel_tween.tween_method(_render_carousel, 0.0, target_progress, 0.15)
	_carousel_tween.finished.connect(func() -> void:
		_current_class_index = _wrap_class_index(_current_class_index + direction)
		_render_carousel(0.0)
		_run_carousel_shift_segment(direction, remaining_segments - 1)
	)


func _update_viewport_scale() -> void:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return
	var new_scale: float = clampf(minf(vp_size.x / _base_viewport_size.x, vp_size.y / _base_viewport_size.y), 0.5, 1.5)
	if not is_equal_approx(new_scale, _viewport_scale):
		_viewport_scale = new_scale
		if not _carousel_layouts.is_empty():
			_recompute_carousel_layouts()
			render_carousel(0.0)


func _recompute_carousel_layouts() -> void:
	if _carousel_slot_refs.is_empty():
		return
	var baseline_y: float = 0.0
	for slot in _carousel_nodes:
		baseline_y += slot.position.y
	baseline_y /= float(_carousel_nodes.size())

	for i in range(_carousel_slot_refs.size()):
		var slot: Control = _carousel_slot_refs[i]["node"]
		var sprite: AnimatedSprite2D = _carousel_slot_refs[i]["sprite"]
		var name_label: Label = _carousel_slot_refs[i]["label"]
		var flat_position: Vector2 = Vector2(slot.position.x, baseline_y)
		slot.position = flat_position
		if sprite:
			sprite.position = _base_sprite_position * _viewport_scale
		if name_label:
			name_label.offset_left = _base_label_offsets["left"] * _viewport_scale
			name_label.offset_top = _base_label_offsets["top"] * _viewport_scale
			name_label.offset_right = _base_label_offsets["right"] * _viewport_scale
			name_label.offset_bottom = _base_label_offsets["bottom"] * _viewport_scale
		_carousel_layouts[i] = {
			"position": flat_position,
			"scale": _base_sprite_scale * _viewport_scale,
			"font_size": roundi(float(_base_font_size) * _viewport_scale),
			"label_top": _base_label_offsets["top"] * _viewport_scale,
			"label_bottom": _base_label_offsets["bottom"] * _viewport_scale,
		}


func _is_in_carousel_area(point: Vector2) -> bool:
	var root := get_parent() as Control
	if root == null:
		return false
	return point.y > 90.0 * _viewport_scale and point.y < 560.0 * _viewport_scale and abs(point.x - root.size.x * 0.5) < 520.0 * _viewport_scale


func _get_clicked_carousel_slot_index(point: Vector2) -> int:
	var sorted_slots: Array = _carousel_slot_refs.duplicate()
	sorted_slots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_node: Control = a["node"]
		var b_node: Control = b["node"]
		return a_node.z_index > b_node.z_index
	)

	for slot_ref in sorted_slots:
		var slot: Control = slot_ref["node"]
		if slot.get_global_rect().has_point(point):
			return _carousel_slot_refs.find(slot_ref)
	return -1


func _on_left_pressed() -> void:
	if not _interaction_enabled:
		return
	_animate_carousel_shift(-1)


func _on_right_pressed() -> void:
	if not _interaction_enabled:
		return
	_animate_carousel_shift(1)


func _assign_random_preview_variants() -> void:
	# Use deterministic seed based on match_id so all clients get the same shuffle
	var seed_string: String = MultiplayerManager.match_id
	if seed_string.is_empty():
		seed_string = str(Time.get_unix_time_from_system())
	_slime_rng.seed = hash(seed_string)
	
	var available_variants: Array = SlimePaletteRegistry.get_variant_order()
	_seeded_shuffle(available_variants, _slime_rng)
	_preview_slime_variants.clear()
	for selected_name in _view.get_class_order():
		if available_variants.is_empty():
			available_variants = SlimePaletteRegistry.get_variant_order()
			_seeded_shuffle(available_variants, _slime_rng)
		_preview_slime_variants[selected_name] = String(available_variants.pop_front())


func _seeded_shuffle(arr: Array, rng: RandomNumberGenerator) -> void:
	# Fisher-Yates shuffle with custom RNG
	for i in range(arr.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func _get_preview_variant_for_class(selected_name: String) -> String:
	return String(_preview_slime_variants.get(selected_name, MultiplayerManager.player_slime_variant))


func _apply_preview_slime_to_sprite(sprite: AnimatedSprite2D, selected_name: String) -> void:
	if sprite == null:
		return
	var material := sprite.material as ShaderMaterial
	if material == null:
		return
	var palette: Dictionary = SlimePaletteRegistry.get_preview_palette(_get_preview_variant_for_class(selected_name))
	material.set_shader_parameter("highlight_color", palette["highlight"])
	material.set_shader_parameter("mid_color", palette["mid"])
	material.set_shader_parameter("shadow_color", palette["shadow"])
	material.set_shader_parameter("outline_color", palette["outline"])
	material.set_shader_parameter("iris_color", palette["iris"])
