extends CanvasLayer

@onready var health_bar: ProgressBar = %HealtBar
@onready var xp_bar: ProgressBar = %ManaBar
@onready var level_label: Label = %LevelLabel
@onready var player_name_label: Label = %PlayerName
@onready var coin_label: Label = %CoinLabel
@onready var score_label: Label = %Score
@onready var mob_count_label: Label = %MobCount
@onready var round_level_label: Label = %RoundLevelPopup
@onready var minimap: Control = %Map
@onready var death_screen: Control = %Death
@onready var store_button: Button = %Store
@onready var skill_tree_button: Button = %SkillTree
@onready var dev_tools_button: Button = %DevTools
@onready var shop_ui: ShopUI = %ShopUI
@onready var skill_tree_ui: SkillTreeUI = %SkillTreeUI
@onready var dev_tools_panel: PanelContainer = %DevToolsPanel
@onready var skills_root: Control = %Skills
@onready var skill_slots_host: HBoxContainer = %SkillSlots
@onready var active_skill_strip_host: HBoxContainer = %ActiveSkillStrip
@onready var passive_scroll_host: ScrollContainer = %PassiveScroll
@onready var passive_strip_host: HBoxContainer = %PassiveStrip

var current_score: int = 0
var player_ref: CharacterBody2D
var slimes: Array = []
var minimap_size: Vector2 = Vector2(212, 169)
var remote_players: Dictionary = {}  # user_id -> { "pos": Vector2, "ign": String }
var _overlay_pause_active: bool = false

var world_size: Vector2 = Vector2(800, 600)
@export var active_skill_slot_scene: PackedScene
@export var passive_skill_icon_scene: PackedScene
@export var player_color: Color = Color.GREEN
@export var remote_player_color: Color = Color.GREEN  # Same as local player
@export var slime_color: Color = Color.RED
@export var lancer_color: Color = Color.PURPLE
@export var archer_color: Color = Color.ORANGE
@export var player_size: float = 8.0
@export var remote_player_size: float = 6.0  # Slightly smaller to distinguish
@export var slime_size: float = 4.0
@export var elite_size: float = 5.0
@export var minimap_background_color: Color = Color(0.04, 0.07, 0.11, 0.88)
@export var minimap_grid_color: Color = Color(0.55, 0.78, 0.92, 0.14)
@export var minimap_ring_color: Color = Color(0.72, 0.9, 1.0, 0.2)
@export var minimap_outline_color: Color = Color(0.82, 0.95, 1.0, 0.55)
@export var minimap_world_radius: float = 950.0
@export var map_bounds_group_name: StringName = &"map_bounds"
@export var environment_group_name: StringName = &"environment"
@export var block_input_when_overlay_open: bool = false

const DEFAULT_MINIMAP_BACKGROUND_COLOR := Color(0.04, 0.07, 0.11, 0.88)
const DEFAULT_MINIMAP_GRID_COLOR := Color(0.55, 0.78, 0.92, 0.14)
const DEFAULT_MINIMAP_RING_COLOR := Color(0.72, 0.9, 1.0, 0.2)
const DEFAULT_MINIMAP_OUTLINE_COLOR := Color(0.82, 0.95, 1.0, 0.55)

var _round_popup_tween: Tween
var _hud_active_icon_nodes: Array[HudActiveSkillSlot] = []
var _hud_passive_strip: HBoxContainer
var _hud_passive_signature: String = ""
var _hud_needs_refresh: bool = true


func _queue_minimap_redraw() -> void:
	if minimap == null:
		return
	if not is_inside_tree():
		return
	minimap.queue_redraw()

func _ready():
	if not is_inside_tree():
		return
	_find_map_bounds()
	_refresh_minimap_size()
	if minimap != null:
		minimap.visible = true
		if not minimap.draw.is_connected(_draw_minimap):
			minimap.draw.connect(_draw_minimap)

	if Engine.is_editor_hint():
		_queue_minimap_redraw()
		return
	
	# Connect to coin changes
	CoinManager.coins_changed.connect(_on_coins_changed)
	_on_coins_changed(CoinManager.get_coins())
	
	if shop_ui:
		shop_ui.hide()
	if skill_tree_ui:
		skill_tree_ui.hide()
	if dev_tools_panel:
		dev_tools_panel.hide()
	if mob_count_label:
		mob_count_label.text = "Mobs: 0"
	if round_level_label:
		round_level_label.visible = false
		round_level_label.modulate = Color(1, 1, 1, 0)
		round_level_label.scale = Vector2(0.92, 0.92)
	_setup_skill_hud()
	_connect_skill_tree_signals()
	_refresh_skill_hud()

func _find_map_bounds() -> void:
	if not is_inside_tree():
		return
	# Look for MapBounds node in the scene tree
	var map_bounds = get_tree().get_first_node_in_group(map_bounds_group_name)
	if map_bounds == null:
		# Try to find by name in environment
		var env = get_tree().get_first_node_in_group(environment_group_name)
		if env:
			map_bounds = env.get_node_or_null("MapBounds")
		if map_bounds == null:
			# Fallback: search entire scene
			for node in get_tree().get_nodes_in_group(map_bounds_group_name):
				map_bounds = node
				break
			if map_bounds == null:
				# Try direct path from root
				map_bounds = get_tree().root.find_child("MapBounds", true, false)
	if map_bounds and map_bounds is ReferenceRect:
		world_size = map_bounds.size
		print("[Minimap] Found MapBounds, world_size: %s" % world_size)
	else:
		push_warning("[Minimap] MapBounds node not found, using default world_size: %s" % world_size)
	_queue_minimap_redraw()

func _process(_delta):
	if not is_inside_tree():
		return
	if minimap == null:
		return
	_refresh_minimap_size()
	_queue_minimap_redraw()
	_refresh_skill_hud_if_needed()

func set_player(player):
	if player_ref and is_instance_valid(player_ref) and player_ref.has_node("Health"):
		var previous_health = player_ref.health
		if previous_health.health_changed.is_connected(_on_health_changed):
			previous_health.health_changed.disconnect(_on_health_changed)
	if player_ref and is_instance_valid(player_ref) and player_ref.has_signal("death_sequence_finished"):
		if player_ref.death_sequence_finished.is_connected(_on_player_died):
			player_ref.death_sequence_finished.disconnect(_on_player_died)

	if LevelSystem.xp_gained.is_connected(_on_xp_gained):
		LevelSystem.xp_gained.disconnect(_on_xp_gained)
	if LevelSystem.level_up.is_connected(_on_level_up):
		LevelSystem.level_up.disconnect(_on_level_up)
	if LevelSystem.stats_updated.is_connected(_on_stats_updated):
		LevelSystem.stats_updated.disconnect(_on_stats_updated)

	player_ref = player
	var health = player.health
	if not health.health_changed.is_connected(_on_health_changed):
		health.health_changed.connect(_on_health_changed)
	if player_ref.has_signal("death_sequence_finished") and not player_ref.death_sequence_finished.is_connected(_on_player_died):
		player_ref.death_sequence_finished.connect(_on_player_died)
	_on_health_changed(health.current_health, health.max_health)

	# Set player name in UI
	if player_name_label:
		player_name_label.text = MultiplayerManager.player_ign

	# Connect to LevelSystem singleton for XP/level updates
	if not LevelSystem.xp_gained.is_connected(_on_xp_gained):
		LevelSystem.xp_gained.connect(_on_xp_gained)
	if not LevelSystem.level_up.is_connected(_on_level_up):
		LevelSystem.level_up.connect(_on_level_up)
	if not LevelSystem.stats_updated.is_connected(_on_stats_updated):
		LevelSystem.stats_updated.connect(_on_stats_updated)
	# Initialize display
	_update_level_display(LevelSystem.get_level(player), LevelSystem.get_xp_progress(player))
	if minimap != null:
		minimap.visible = true
	_queue_minimap_redraw()

	# Pass player reference to dev tools panel
	if dev_tools_panel and dev_tools_panel.has_method("set_player"):
		dev_tools_panel.set_player(player)


func set_mob_spawner(spawner: MobSpawner) -> void:
	if dev_tools_panel and dev_tools_panel.has_method("set_mob_spawner"):
		dev_tools_panel.set_mob_spawner(spawner)

func _on_health_changed(current_health, max_health):
	health_bar.max_value = max_health
	health_bar.value = current_health

func _on_player_died(killer_name: String = ""):
	if death_screen != null and death_screen.has_method("show_death_screen"):
		death_screen.show_death_screen(current_score, killer_name)

func _on_xp_gained(entity_id: int, _amount: int, _total: int):
	if player_ref and player_ref.get_instance_id() == entity_id:
		_update_level_display(LevelSystem.get_level(player_ref), LevelSystem.get_xp_progress(player_ref))

func _on_level_up(entity_id: int, new_level: int, _stats: Dictionary):
	if player_ref and player_ref.get_instance_id() == entity_id:
		print("[UI] Player leveled up to %d!" % new_level)
		_update_level_display(new_level, LevelSystem.get_xp_progress(player_ref))

func _on_stats_updated(entity_id: int, _stats: Dictionary):
	# Stats are applied by LevelSystem directly to player
	if player_ref and player_ref.get_instance_id() == entity_id:
		_update_level_display(LevelSystem.get_level(player_ref), LevelSystem.get_xp_progress(player_ref))

func _update_level_display(level: int, xp_progress: float):
	if level_label:
		level_label.text = "Lv.%d" % level
	if xp_bar:
		xp_bar.value = xp_progress * 100.0

func add_score(amount: int):
	current_score += amount
	update_score_display()

func update_score_display():
	score_label.text = "Score: " + str(current_score)


func update_mob_counter(current_alive: int, total_in_round: int) -> void:
	if mob_count_label == null:
		return
	mob_count_label.text = "Mobs: %d/%d" % [current_alive, total_in_round]


func show_round_level(round_number: int, added_mobs: int, profile: Dictionary) -> void:
	if round_level_label == null:
		return
	if _round_popup_tween != null and _round_popup_tween.is_valid():
		_round_popup_tween.kill()

	var growth_line := "+%d Mobs  HP +%d%%  DMG +%d%%  SPD +%d%%" % [
		added_mobs,
		int(profile.get("health_growth_pct", 0)),
		int(profile.get("damage_growth_pct", 0)),
		int(profile.get("speed_growth_pct", 0))
	]
	round_level_label.text = "Round %d\n%s" % [round_number, growth_line]
	round_level_label.visible = true
	round_level_label.modulate = Color(1, 1, 1, 0)
	round_level_label.scale = Vector2(0.92, 0.92)

	_round_popup_tween = create_tween()
	_round_popup_tween.set_trans(Tween.TRANS_CUBIC)
	_round_popup_tween.set_ease(Tween.EASE_OUT)
	_round_popup_tween.set_parallel(true)
	_round_popup_tween.tween_property(round_level_label, "modulate", Color.WHITE, 0.25)
	_round_popup_tween.tween_property(round_level_label, "scale", Vector2.ONE, 0.25)
	_round_popup_tween.chain().tween_interval(1.1)
	_round_popup_tween.chain().set_parallel(true)
	_round_popup_tween.tween_property(round_level_label, "modulate", Color(1, 1, 1, 0), 0.35)
	_round_popup_tween.tween_property(round_level_label, "scale", Vector2(1.04, 1.04), 0.35)
	_round_popup_tween.finished.connect(_on_round_popup_finished)


func _on_round_popup_finished() -> void:
	if round_level_label != null:
		round_level_label.visible = false
	_round_popup_tween = null

func register_slime(slime):
	if slime not in slimes:
		slimes.append(slime)
		slime.tree_exiting.connect(_on_slime_removed.bind(slime))
		_queue_minimap_redraw()

func _on_slime_removed(slime):
	slimes.erase(slime)
	_queue_minimap_redraw()

## Register a remote player for minimap display
func register_remote_player(user_id: String, ign: String) -> void:
	remote_players[user_id] = { "pos": Vector2.ZERO, "ign": ign }
	_queue_minimap_redraw()

func update_remote_player_ign(user_id: String, ign: String) -> void:
	if remote_players.has(user_id):
		remote_players[user_id]["ign"] = ign
		_queue_minimap_redraw()

## Update remote player position on minimap
func update_remote_player_pos(user_id: String, pos: Vector2) -> void:
	if remote_players.has(user_id):
		remote_players[user_id]["pos"] = pos
		_queue_minimap_redraw()

## Remove remote player from minimap
func unregister_remote_player(user_id: String) -> void:
	remote_players.erase(user_id)
	_queue_minimap_redraw()

func _draw_minimap():
	var minimap_rect := Rect2(Vector2.ZERO, minimap_size)
	minimap.draw_rect(minimap_rect, _safe_color(minimap_background_color, DEFAULT_MINIMAP_BACKGROUND_COLOR))
	minimap.draw_rect(minimap_rect.grow(-1.0), Color(0.08, 0.14, 0.2, 0.5), false, 2.0)
	_draw_minimap_grid()

	if Engine.is_editor_hint():
		var preview_center := minimap_size / 2.0
		_draw_center_focus(preview_center)
		minimap.draw_circle(preview_center, player_size, Color(0.25, 0.95, 0.45, 0.9))
		return

	if not player_ref or not is_instance_valid(player_ref):
		return
	
	var player_minimap_pos = minimap_size / 2
	_draw_center_focus(player_minimap_pos)
	minimap.draw_circle(player_minimap_pos, player_size + 3.0, Color(0, 0, 0, 0.35))
	minimap.draw_circle(player_minimap_pos, player_size, player_color)
	
	var minimap_radius := _get_minimap_draw_radius()
	
	for enemy in slimes:
		if is_instance_valid(enemy):
			var enemy_minimap_pos = world_to_minimap(enemy.global_position, player_minimap_pos, minimap_radius)
			
			enemy_minimap_pos = clamp_to_minimap(enemy_minimap_pos)
			
			var enemy_color = slime_color
			var enemy_size = slime_size
			
			if enemy.get_script():
				var script_path = enemy.get_script().resource_path
				
				if "lancer" in script_path.to_lower():
					enemy_color = lancer_color
					enemy_size = elite_size
				elif "archer" in script_path.to_lower():
					enemy_color = archer_color
					enemy_size = elite_size
			
			minimap.draw_circle(enemy_minimap_pos, enemy_size + 2.0, Color(0, 0, 0, 0.35))
			minimap.draw_circle(enemy_minimap_pos, enemy_size, enemy_color)
	
	# Draw remote players as green dots
	for user_id in remote_players:
		var rp_data = remote_players[user_id]
		var rp_pos = rp_data["pos"]
		var rp_minimap_pos = world_to_minimap(rp_pos, player_minimap_pos, minimap_radius)
		rp_minimap_pos = clamp_to_minimap(rp_minimap_pos)
		minimap.draw_circle(rp_minimap_pos, remote_player_size + 2.0, Color(0, 0, 0, 0.35))
		minimap.draw_circle(rp_minimap_pos, remote_player_size, remote_player_color)

func _draw_minimap_grid() -> void:
	var center := minimap_size / 2.0
	var grid_color := _safe_color(minimap_grid_color, DEFAULT_MINIMAP_GRID_COLOR)
	var ring_color := _safe_color(minimap_ring_color, DEFAULT_MINIMAP_RING_COLOR)
	minimap.draw_line(Vector2(center.x, 0), Vector2(center.x, minimap_size.y), grid_color, 1.0)
	minimap.draw_line(Vector2(0, center.y), Vector2(minimap_size.x, center.y), grid_color, 1.0)
	minimap.draw_arc(center, min(minimap_size.x, minimap_size.y) * 0.28, 0.0, TAU, 48, ring_color, 1.0)
	minimap.draw_arc(center, min(minimap_size.x, minimap_size.y) * 0.44, 0.0, TAU, 48, ring_color, 1.0)

func _draw_center_focus(center: Vector2) -> void:
	minimap.draw_circle(center, 12.0, Color(1, 1, 1, 0.04))
	minimap.draw_arc(center, 16.0, 0.0, TAU, 32, _safe_color(minimap_outline_color, DEFAULT_MINIMAP_OUTLINE_COLOR), 1.0)

func _get_minimap_draw_radius() -> float:
	return max(min(minimap_size.x, minimap_size.y) * 0.5 - 12.0, 1.0)


func world_to_minimap(world_pos: Vector2, center: Vector2, minimap_radius: float) -> Vector2:
	var relative_pos: Vector2 = world_pos - player_ref.global_position
	var distance: float = relative_pos.length()
	if distance <= 0.001:
		return center
	var distance_scale: float = min(distance / minimap_world_radius, 1.0)
	var minimap_pos: Vector2 = center + relative_pos.normalized() * (distance_scale * minimap_radius)
	return minimap_pos

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
	if minimap == null:
		return
	var current_size := minimap.size
	if current_size.x <= 0.0 or current_size.y <= 0.0:
		current_size = minimap.custom_minimum_size
		if current_size.x <= 0.0 or current_size.y <= 0.0:
			return
	minimap_size = current_size

func _on_coins_changed(total: int) -> void:
	if coin_label:
		coin_label.text = str(total)

func _on_store_pressed():
	toggle_shop()

func toggle_shop():
	if shop_ui:
		if shop_ui.visible:
			shop_ui.close()
		else:
			if skill_tree_ui and skill_tree_ui.visible:
				skill_tree_ui.close()
			shop_ui.open()
		_update_overlay_pause()


func _on_skill_tree_pressed() -> void:
	toggle_skill_tree()


func toggle_skill_tree() -> void:
	if skill_tree_ui:
		if skill_tree_ui.visible:
			skill_tree_ui.close()
		else:
			if shop_ui and shop_ui.visible:
				shop_ui.close()
				if dev_tools_panel and dev_tools_panel.visible:
					dev_tools_panel.hide()
			skill_tree_ui.open()
		_update_overlay_pause()


func _on_dev_tools_pressed() -> void:
	toggle_dev_tools()


func toggle_dev_tools() -> void:
	if dev_tools_panel:
		if dev_tools_panel.visible:
			dev_tools_panel.hide()
		else:
			if shop_ui and shop_ui.visible:
				shop_ui.close()
			if skill_tree_ui and skill_tree_ui.visible:
				skill_tree_ui.close()
			dev_tools_panel.show()
		_update_overlay_pause()


func _on_overlay_closed() -> void:
	_update_overlay_pause()


func _update_overlay_pause() -> void:
	_overlay_pause_active = block_input_when_overlay_open and _is_overlay_open()


func has_blocking_overlay_open() -> bool:
	return _overlay_pause_active


func _is_overlay_open() -> bool:
	return (shop_ui != null and shop_ui.visible) or (skill_tree_ui != null and skill_tree_ui.visible) or (dev_tools_panel != null and dev_tools_panel.visible)


func _safe_color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	return fallback


func _setup_skill_hud() -> void:
	if skill_slots_host == null or active_skill_strip_host == null:
		return
	if active_skill_slot_scene == null:
		push_warning("[HUD] active_skill_slot_scene is not assigned.")
		return

	for child in active_skill_strip_host.get_children():
		child.queue_free()

	_hud_active_icon_nodes.clear()
	_hud_passive_signature = ""

	for slot_index in range(4):
		var slot: HudActiveSkillSlot = active_skill_slot_scene.instantiate() as HudActiveSkillSlot
		slot.set_slot_index(slot_index)
		active_skill_strip_host.add_child(slot)
		_hud_active_icon_nodes.append(slot)

	if passive_strip_host != null:
		_hud_passive_strip = passive_strip_host

func _connect_skill_tree_signals() -> void:
	var manager: Node = SkillTreeManager
	if manager == null:
		return
	if not manager.sp_changed.is_connected(_on_skill_tree_state_changed):
		manager.sp_changed.connect(_on_skill_tree_state_changed)
	if not manager.skill_invested.is_connected(_on_skill_tree_skill_invested):
		manager.skill_invested.connect(_on_skill_tree_skill_invested)
	if not manager.state_loaded.is_connected(_on_skill_tree_loaded):
		manager.state_loaded.connect(_on_skill_tree_loaded)


func _refresh_skill_hud() -> void:
	_hud_needs_refresh = true

func _refresh_skill_hud_if_needed() -> void:
	var manager: Node = SkillTreeManager
	var registry: Node = SkillRegistry
	if manager == null or registry == null or _hud_active_icon_nodes.is_empty():
		return

	# Always update cooldowns (cheap check)
	var cooldowns_changed := false
	for slot_index in range(_hud_active_icon_nodes.size()):
		var slot_ref: HudActiveSkillSlot = _hud_active_icon_nodes[slot_index]
		var cooldown_remaining := PlayerSkillManager.get_ability_cooldown_remaining(slot_index)
		if slot_ref.set_cooldown(cooldown_remaining):
			cooldowns_changed = true

	# Only do expensive rebuild when needed
	if not _hud_needs_refresh and not cooldowns_changed:
		return
	_hud_needs_refresh = false

	for slot_index in range(_hud_active_icon_nodes.size()):
		var slot_ref: HudActiveSkillSlot = _hud_active_icon_nodes[slot_index]
		var skill_id: String = str(manager.call("get_slotted_skill", slot_index))
		if skill_id.is_empty():
			slot_ref.set_empty()
			continue

		slot_ref.set_skill_icon(registry.call("get_skill_icon", skill_id) as Texture2D)

	_refresh_passive_skill_icons(manager, registry)


func _refresh_passive_skill_icons(manager, registry) -> void:
	if _hud_passive_strip == null:
		return
	if passive_skill_icon_scene == null:
		push_warning("[HUD] passive_skill_icon_scene is not assigned.")
		return

	var passive_skill_ids: Array[String] = []
	for skill_id_variant in manager.call("get_learned_skill_ids"):
		var skill_id := str(skill_id_variant)
		var skill = registry.get_skill(skill_id)
		if skill == null:
			continue
		if skill.skill_type == SkillDefinition.SkillType.STAT or skill.skill_type == SkillDefinition.SkillType.PASSIVE:
			passive_skill_ids.append(skill_id)

	passive_skill_ids.sort()
	var signature := "|".join(passive_skill_ids)
	if signature == _hud_passive_signature:
		return
	_hud_passive_signature = signature

	for child in _hud_passive_strip.get_children():
		child.queue_free()

	for skill_id in passive_skill_ids:
		var skill: Resource = registry.get_skill(skill_id)
		var icon_panel: HudPassiveSkillIcon = passive_skill_icon_scene.instantiate() as HudPassiveSkillIcon
		icon_panel.configure(skill, registry.call("get_skill_icon", skill_id) as Texture2D, skill_id)
		_hud_passive_strip.add_child(icon_panel)


func _on_skill_tree_state_changed(_available: int, _total: int) -> void:
	_hud_passive_signature = ""
	_hud_needs_refresh = true


func _on_skill_tree_skill_invested(_skill_id: String, _new_level: int) -> void:
	_hud_passive_signature = ""
	_hud_needs_refresh = true


func _on_skill_tree_loaded(_state: Dictionary) -> void:
	_hud_passive_signature = ""
	_hud_needs_refresh = true
