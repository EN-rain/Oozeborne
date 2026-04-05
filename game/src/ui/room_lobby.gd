extends Control


# ── Node References (matching new prototype layout) ──────────────────────────
@onready var room_code_button: Button = $RoomCode
@onready var leave_button: Button = $LeaveLobby
@onready var start_button: Button = $StartGame
@onready var select_class_button: Button = $SelectClass
@onready var left_button: Button = $LeftButton
@onready var right_button: Button = $RightButton
@onready var title_label: Label = $Label
@onready var title_edit: LineEdit = $LobbyNameEdit
@onready var subclass_hint_label: Label = $Label/Label
@onready var players_title: Label = $Players/VBox/PlayersTitle
@onready var players_list: VBoxContainer = $Players/VBox/PlayersList
@onready var stats_content: RichTextLabel = $ClassStats/StatsVBox/StatsContent
@onready var subclass_content: RichTextLabel = $SubClassInfo/VBox/SubclassContent
@onready var hp_value_label: Label = $ClassStats/StatsVBox/StatsCards/HPCard/Margin/VBox/Value
@onready var atk_value_label: Label = $ClassStats/StatsVBox/StatsCards/AttackCard/Margin/VBox/Value
@onready var def_value_label: Label = $ClassStats/StatsVBox/StatsCards/DefenseCard/Margin/VBox/Value
@onready var spd_value_label: Label = $ClassStats/StatsVBox/StatsCards/SpeedCard/Margin/VBox/Value
@onready var crit_value_label: Label = $ClassStats/StatsVBox/StatsCards/CritCard/Margin/VBox/Value
@onready var evade_value_label: Label = $ClassStats/StatsVBox/StatsCards/EvadeCard/Margin/VBox/Value
@onready var hp_card: PanelContainer = $ClassStats/StatsVBox/StatsCards/HPCard
@onready var attack_card: PanelContainer = $ClassStats/StatsVBox/StatsCards/AttackCard
@onready var defense_card: PanelContainer = $ClassStats/StatsVBox/StatsCards/DefenseCard
@onready var speed_card: PanelContainer = $ClassStats/StatsVBox/StatsCards/SpeedCard
@onready var crit_card: PanelContainer = $ClassStats/StatsVBox/StatsCards/CritCard
@onready var evade_card: PanelContainer = $ClassStats/StatsVBox/StatsCards/EvadeCard
@onready var power_fill: ColorRect = get_node_or_null("ClassStats/StatsVBox/PowerRow/PowerTrack/PowerFill") as ColorRect
@onready var power_rank_label: Label = get_node_or_null("ClassStats/StatsVBox/PowerRow/PowerRank") as Label
@onready var talent_cards: VBoxContainer = $SubClassInfo/VBox/TalentCards

# ── Chat nodes ──────────────────────────────────────────────────────────────
@onready var chat_log: RichTextLabel = $ChatBox/VBox/ChatLog
@onready var chat_input: LineEdit = $ChatBox/VBox/InputRow/ChatInput
@onready var send_button: Button = $ChatBox/VBox/InputRow/SendButton

# ── Class slot nodes ─────────────────────────────────────────────────────────
@onready var class_slots: Array = [
	$Class1, $Class2, $Class3, $Class4, $Class5
]

const MAIN_GAME_SCENE = "res://scenes/levels/main.tscn"
const MAIN_MENU_SCENE = "res://scenes/ui/main_menu.tscn"
const CROWN_EMOJI = "👑 "

const SLIME_PREVIEW_SHADER = preload("res://assets/shaders/slime_color.gdshader")
const SLIME_VARIANT_ORDER := [
	"blue", "red", "green", "purple", "gold",
	"pink", "dark", "orange", "white", "cyan",
	"lime", "crimson", "teal", "brown",
]
const SLIME_SCENE_PATHS := {
	"blue": "res://scenes/entities/player/slime_blue.tscn",
	"red": "res://scenes/entities/player/slime_red.tscn",
	"green": "res://scenes/entities/player/slime_green.tscn",
	"purple": "res://scenes/entities/player/slime_purple.tscn",
	"gold": "res://scenes/entities/player/slime_gold.tscn",
	"pink": "res://scenes/entities/player/slime_pink.tscn",
	"dark": "res://scenes/entities/player/slime_dark.tscn",
	"orange": "res://scenes/entities/player/slime_orange.tscn",
	"white": "res://scenes/entities/player/slime_white.tscn",
	"cyan": "res://scenes/entities/player/slime_cyan.tscn",
	"lime": "res://scenes/entities/player/slime_lime.tscn",
	"crimson": "res://scenes/entities/player/slime_crimson.tscn",
	"teal": "res://scenes/entities/player/slime_teal.tscn",
	"brown": "res://scenes/entities/player/slime_brown.tscn",
}
const SLIME_PREVIEW_COLORS := {
	"blue": {"highlight": Color(0.52549, 0.890196, 0.996078, 1), "mid": Color(0.454902, 0.843137, 1, 1), "shadow": Color(0.34902, 0.741176, 0.905882, 1), "outline": Color(0.082353, 0.141176, 0.27451, 1), "iris": Color(0.109804, 0.184314, 0.360784, 1)},
	"red": {"highlight": Color(1, 0.52549, 0.52549, 1), "mid": Color(1, 0.337255, 0.337255, 1), "shadow": Color(1, 0.196078, 0.196078, 1), "outline": Color(0.368627, 0.047059, 0.047059, 1), "iris": Color(0.380392, 0.058824, 0.117647, 1)},
	"green": {"highlight": Color(0.52549, 0.996078, 0.690196, 1), "mid": Color(0.337255, 0.909804, 0.478431, 1), "shadow": Color(0.196078, 0.788235, 0.341176, 1), "outline": Color(0.058824, 0.286275, 0.121569, 1), "iris": Color(0.086275, 0.258824, 0.14902, 1)},
	"purple": {"highlight": Color(0.847059, 0.52549, 0.996078, 1), "mid": Color(0.756863, 0.337255, 1, 1), "shadow": Color(0.6, 0.196078, 1, 1), "outline": Color(0.231373, 0.070588, 0.380392, 1), "iris": Color(0.203922, 0.078431, 0.321569, 1)},
	"gold": {"highlight": Color(0.996078, 0.941176, 0.52549, 1), "mid": Color(1, 0.85098, 0.196078, 1), "shadow": Color(1, 0.737255, 0, 1), "outline": Color(0.431373, 0.27451, 0.043137, 1), "iris": Color(0.34902, 0.219608, 0.054902, 1)},
	"pink": {"highlight": Color(1, 0.701961, 0.85098, 1), "mid": Color(1, 0.501961, 0.752941, 1), "shadow": Color(1, 0.301961, 0.65098, 1), "outline": Color(0.470588, 0.082353, 0.278431, 1), "iris": Color(0.431373, 0.098039, 0.278431, 1)},
	"dark": {"highlight": Color(0.541176, 0.541176, 0.619608, 1), "mid": Color(0.290196, 0.290196, 0.415686, 1), "shadow": Color(0.101961, 0.101961, 0.227451, 1), "outline": Color(0.035294, 0.035294, 0.109804, 1), "iris": Color(0.760784, 0.733333, 0.878431, 1)},
	"orange": {"highlight": Color(0.996078, 0.784314, 0.52549, 1), "mid": Color(1, 0.615686, 0.25098, 1), "shadow": Color(1, 0.466667, 0, 1), "outline": Color(0.427451, 0.180392, 0.031373, 1), "iris": Color(0.407843, 0.180392, 0.05098, 1)},
	"white": {"highlight": Color(1, 1, 1, 1), "mid": Color(0.839216, 0.941176, 1, 1), "shadow": Color(0.658824, 0.847059, 0.941176, 1), "outline": Color(0.305882, 0.447059, 0.560784, 1), "iris": Color(0.360784, 0.541176, 0.760784, 1)},
	"cyan": {"highlight": Color(0.682353, 0.996078, 1, 1), "mid": Color(0.384314, 0.952941, 1, 1), "shadow": Color(0.117647, 0.784314, 0.878431, 1), "outline": Color(0.047059, 0.286275, 0.329412, 1), "iris": Color(0.058824, 0.270588, 0.317647, 1)},
	"lime": {"highlight": Color(0.847059, 1, 0.52549, 1), "mid": Color(0.658824, 0.960784, 0.258824, 1), "shadow": Color(0.454902, 0.823529, 0.121569, 1), "outline": Color(0.196078, 0.321569, 0.047059, 1), "iris": Color(0.211765, 0.317647, 0.062745, 1)},
	"crimson": {"highlight": Color(1, 0.603922, 0.635294, 1), "mid": Color(1, 0.360784, 0.423529, 1), "shadow": Color(0.788235, 0.164706, 0.227451, 1), "outline": Color(0.411765, 0.062745, 0.145098, 1), "iris": Color(0.380392, 0.05098, 0.129412, 1)},
	"teal": {"highlight": Color(0.560784, 1, 0.878431, 1), "mid": Color(0.211765, 0.85098, 0.705882, 1), "shadow": Color(0.082353, 0.560784, 0.470588, 1), "outline": Color(0.043137, 0.243137, 0.184314, 1), "iris": Color(0.054902, 0.239216, 0.180392, 1)},
	"brown": {"highlight": Color(0.85098, 0.627451, 0.4, 1), "mid": Color(0.658824, 0.419608, 0.235294, 1), "shadow": Color(0.431373, 0.239216, 0.121569, 1), "outline": Color(0.203922, 0.109804, 0.047059, 1), "iris": Color(0.219608, 0.12549, 0.054902, 1)},
}
const CAROUSEL_SLOT_RELS := [-2, -1, 0, 1, 2]
const DRAG_SNAP_DISTANCE := 140.0
const DRAG_TRIGGER_DISTANCE := 55.0
const CLASS_NAME_IDLE_PULSE_SPEED := 3.2
const CLASS_NAME_IDLE_LIFT := 5.0
const CLASS_NAME_CENTER_SCALE := 1.16
const CLASS_NAME_SIDE_ALPHA := 0.72

var _player_entries: Dictionary = {}
var _last_state_log_time: int = 0
var _last_btn_log_time: int = 0
var _is_transitioning: bool = false
var _selected_class: PlayerClass = null
var _selected_subclass: PlayerClass = null
var _current_class_index: int = 0
var _carousel_nodes: Array = []
var _carousel_layouts: Array = []
var _carousel_slot_refs: Array = []
var _carousel_progress: float = 0.0
var _is_dragging_carousel: bool = false
var _drag_start_pos := Vector2.ZERO
var _drag_delta_x: float = 0.0
var _carousel_tween: Tween = null
var _view: RoomLobbyView
var _carousel_idle_time: float = 0.0
var _class_slime_variants: Dictionary = {}
var _slime_rng := RandomNumberGenerator.new()

func _get_player_count() -> int:
	return MultiplayerManager.players.size()

func _get_host_ign() -> String:
	if MultiplayerManager.is_host and not MultiplayerManager.player_ign.strip_edges().is_empty():
		return MultiplayerManager.player_ign

	for entry in _player_entries.values():
		if bool(entry.get("is_host", false)):
			var host_ign: String = str(entry.get("ign", "")).replace(" (You)", "").strip_edges()
			if not host_ign.is_empty():
				return host_ign

	if not MultiplayerManager.player_ign.strip_edges().is_empty():
		return MultiplayerManager.player_ign
	return "Player"

func _build_default_lobby_name(host_ign: String) -> String:
	var safe_host_ign: String = host_ign.strip_edges()
	if safe_host_ign.is_empty():
		safe_host_ign = "Player"
	return "%s's Lobby" % safe_host_ign

func _get_current_lobby_name() -> String:
	var current_name: String = MultiplayerManager.lobby_name.strip_edges()
	if current_name.is_empty():
		return _build_default_lobby_name(_get_host_ign())
	return current_name

func _refresh_lobby_title() -> void:
	var current_name: String = _get_current_lobby_name()
	title_label.text = current_name
	if is_instance_valid(title_edit):
		title_edit.editable = MultiplayerManager.is_host
		title_edit.placeholder_text = _build_default_lobby_name(_get_host_ign())
		if not title_edit.has_focus():
			title_edit.text = current_name

func _begin_lobby_title_edit() -> void:
	if not MultiplayerManager.is_host or not is_instance_valid(title_edit):
		return
	title_edit.text = _get_current_lobby_name()
	title_edit.visible = true
	title_label.visible = false
	title_edit.grab_focus()
	title_edit.select_all()

func _finish_lobby_title_edit(cancel: bool = false) -> void:
	if not is_instance_valid(title_edit):
		return
	if cancel:
		title_edit.text = _get_current_lobby_name()
	else:
		var next_name: String = title_edit.text.strip_edges()
		if next_name.is_empty():
			next_name = _build_default_lobby_name(_get_host_ign())
		MultiplayerManager.lobby_name = next_name
	title_edit.visible = false
	title_label.visible = true
	_refresh_lobby_title()

func _broadcast_lobby_name() -> void:
	if MultiplayerManager.is_socket_open() and not MultiplayerManager.match_id.is_empty():
		MultiplayerManager.send_match_state({
			"type": "lobby_name",
			"name": _get_current_lobby_name()
		})

func _commit_lobby_title_edit() -> void:
	if not MultiplayerManager.is_host or not is_instance_valid(title_edit) or not title_edit.visible:
		return
	_finish_lobby_title_edit(false)
	_broadcast_lobby_name()

func _on_title_label_gui_input(event: InputEvent) -> void:
	if not MultiplayerManager.is_host:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_begin_lobby_title_edit()
		get_viewport().set_input_as_handled()

func _on_title_edit_text_submitted(_new_text: String) -> void:
	_commit_lobby_title_edit()

func _on_title_edit_focus_exited() -> void:
	if title_edit.visible:
		_commit_lobby_title_edit()

func _on_title_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_finish_lobby_title_edit(true)
		get_viewport().set_input_as_handled()

func _refresh_start_button_state() -> void:
	if not is_instance_valid(start_button):
		return

	start_button.visible = MultiplayerManager.is_host
	start_button.disabled = not MultiplayerManager.is_host or _get_player_count() < 2
	
	if MultiplayerManager.is_host:
		var current_time = Time.get_ticks_msec()
		if current_time - _last_btn_log_time > 2000:
			_last_btn_log_time = current_time
			print("[Lobby] Start button state: visible=", start_button.visible, " disabled=", start_button.disabled, " players=", _get_player_count())

func _update_player_count():
	_refresh_party_cards()

func _ready():
	_slime_rng.randomize()
	# Check if game is already in progress - late joiner scenario
	if MultiplayerManager.match_phase == "in_game":
		_show_join_game_ui()
		return

	start_button.pressed.connect(_on_start_pressed)
	leave_button.pressed.connect(_on_back_pressed)
	room_code_button.pressed.connect(_on_copy_code_pressed)
	select_class_button.pressed.connect(_on_select_class_pressed)
	left_button.pressed.connect(_on_left_pressed)
	right_button.pressed.connect(_on_right_pressed)
	send_button.pressed.connect(_on_send_chat)
	chat_input.text_submitted.connect(_on_chat_submitted)
	title_label.mouse_filter = Control.MOUSE_FILTER_STOP
	title_label.gui_input.connect(_on_title_label_gui_input)
	title_edit.text_submitted.connect(_on_title_edit_text_submitted)
	title_edit.focus_exited.connect(_on_title_edit_focus_exited)
	title_edit.gui_input.connect(_on_title_edit_gui_input)
	_view = RoomLobbyView.new({
		"players_title": players_title,
		"players_list": players_list,
		"stats_content": stats_content,
		"subclass_content": subclass_content,
		"hp_value_label": hp_value_label,
		"atk_value_label": atk_value_label,
		"def_value_label": def_value_label,
		"spd_value_label": spd_value_label,
		"crit_value_label": crit_value_label,
		"evade_value_label": evade_value_label,
		"power_fill": power_fill,
		"power_rank_label": power_rank_label,
		"talent_cards": talent_cards,
		"stat_cards": [hp_card, attack_card, defense_card, speed_card, crit_card, evade_card],
	})
	_view.setup_right_panels()
	_assign_random_slime_variants()
	_setup_carousel()
	_render_carousel(0.0)
	_refresh_lobby_title()
	chat_input.grab_focus()

	_add_chat_message("System", "Welcome to the lobby!", Color(0.9, 0.75, 0.3))

	room_code_button.text = MultiplayerManager.room_code
	
	if MultiplayerManager.session == null:
		_refresh_party_cards()
		return

	# Add self with crown if host
	var prefix = CROWN_EMOJI if MultiplayerManager.is_host else ""
	_add_player_entry(MultiplayerManager.session.user_id, MultiplayerManager.player_ign + " (You)", prefix, MultiplayerManager.is_host)
	
	# Add any players already stored
	for user_id in MultiplayerManager.players:
		if user_id != MultiplayerManager.session.user_id:
			var info = MultiplayerManager.players[user_id]
			var is_host_flag = info.get("is_host", false)
			var ign = info.get("ign", "Unknown")
			_add_player_entry(user_id, ign, CROWN_EMOJI if is_host_flag else "", is_host_flag)

	_refresh_start_button_state()
	
	# Listen for signals
	if not MultiplayerManager.player_joined.is_connected(_on_player_joined_signal):
		MultiplayerManager.player_joined.connect(_on_player_joined_signal)
	if not MultiplayerManager.player_left.is_connected(_on_player_left_signal):
		MultiplayerManager.player_left.connect(_on_player_left_signal)
	if not MultiplayerManager.match_phase_changed.is_connected(_on_match_phase_changed):
		MultiplayerManager.match_phase_changed.connect(_on_match_phase_changed)
	
	# Listen for match state events
	if MultiplayerManager.socket:
		if not MultiplayerManager.socket.received_match_state.is_connected(_on_match_state):
			MultiplayerManager.socket.received_match_state.connect(_on_match_state)
		# Announce ourselves
		MultiplayerManager.send_match_state({"type": "player_info", "user_id": MultiplayerManager.session.user_id, "ign": MultiplayerManager.player_ign, "is_host": MultiplayerManager.is_host})
		if MultiplayerManager.is_host:
			_broadcast_lobby_name()
	print("[Lobby] Ready, is_host: ", MultiplayerManager.is_host, " match_id: ", MultiplayerManager.match_id, " socket_connected: ", MultiplayerManager.socket.is_connected_to_host() if MultiplayerManager.socket else false)
	
	# Highlight current selected class slot
	_update_class_highlight()
	_refresh_party_cards()

func _process(delta: float) -> void:
	_carousel_idle_time += delta
	if _carousel_nodes.is_empty() or _is_dragging_carousel:
		return
	if _carousel_tween != null and _carousel_tween.is_running():
		return
	_render_carousel(0.0)

func _exit_tree() -> void:
	if MultiplayerManager.player_joined.is_connected(_on_player_joined_signal):
		MultiplayerManager.player_joined.disconnect(_on_player_joined_signal)
	if MultiplayerManager.player_left.is_connected(_on_player_left_signal):
		MultiplayerManager.player_left.disconnect(_on_player_left_signal)
	if MultiplayerManager.match_phase_changed.is_connected(_on_match_phase_changed):
		MultiplayerManager.match_phase_changed.disconnect(_on_match_phase_changed)
	if MultiplayerManager.socket and MultiplayerManager.socket.received_match_state.is_connected(_on_match_state):
		MultiplayerManager.socket.received_match_state.disconnect(_on_match_state)

func _transition_to_game_scene(source: String) -> void:
	if _is_transitioning or not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null:
		return
	_is_transitioning = true
	print("[Lobby] Transitioning to game scene from ", source, "...")
	tree.change_scene_to_file(MAIN_GAME_SCENE)

# ── Player list management ───────────────────────────────────────────────────
func _add_player_entry(user_id: String, ign: String, _prefix: String, is_host_flag: bool):
	# If entry exists, update it
	if _player_entries.has(user_id):
		var entry = _player_entries[user_id]
		entry.ign = ign
		entry.is_host = is_host_flag
		_refresh_party_cards()
		return
	
	# Check if player already exists by IGN
	for entry in _player_entries.values():
		if entry.ign == ign:
			return
	
	var accent_color = _view.get_next_player_accent(_player_entries.size())
	
	_player_entries[user_id] = {"ign": ign, "is_host": is_host_flag, "accent_color": accent_color}
	_refresh_party_cards()
	_refresh_lobby_title()
	
	# Chat notification
	_add_chat_message("System", ign + " joined the lobby.", Color(0.35, 0.65, 0.45))

func _on_player_joined_signal(user_id: String, ign: String, is_host_flag: bool):
	print("[Lobby] Player joined signal: ", ign)
	_add_player_entry(user_id, ign, CROWN_EMOJI if is_host_flag else "", is_host_flag)
	_refresh_start_button_state()

func _on_player_left_signal(user_id: String):
	print("[Lobby] Player left signal")
	if _player_entries.has(user_id):
		var entry = _player_entries[user_id]
		_add_chat_message("System", entry.ign + " left the lobby.", Color(0.75, 0.35, 0.35))
		_player_entries.erase(user_id)
	_refresh_start_button_state()
	_refresh_party_cards()
	_refresh_lobby_title()

func _refresh_party_cards() -> void:
	if _view == null:
		return
	_view.refresh_party_cards(_player_entries)

func _setup_carousel() -> void:
	_carousel_nodes = [$Class4, $Class5, $Class1, $Class3, $Class2]
	_carousel_layouts.clear()
	_carousel_slot_refs.clear()
	var center_slot: Control = $Class1
	var center_y: float = center_slot.position.y
	var center_sprite: AnimatedSprite2D = center_slot.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var center_label: Label = center_slot.get_node_or_null("ClassName") as Label
	var center_sprite_position: Vector2 = center_sprite.position if center_sprite else Vector2(128, 170)
	var center_label_left: float = center_label.offset_left if center_label else -60.0
	var center_label_top: float = center_label.offset_top if center_label else 3.0
	var center_label_right: float = center_label.offset_right if center_label else 60.0
	var center_label_bottom: float = center_label.offset_bottom if center_label else 26.0

	for slot in _carousel_nodes:
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sprite: AnimatedSprite2D = slot.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		var name_label: Label = slot.get_node_or_null("ClassName") as Label
		if sprite:
			var material := ShaderMaterial.new()
			material.shader = SLIME_PREVIEW_SHADER
			sprite.material = material
			sprite.play("idle")
			sprite.stop()
			sprite.frame = 0
		if name_label:
			name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_carousel_slot_refs.append({
			"node": slot,
			"sprite": sprite,
			"label": name_label,
		})
		var flat_position: Vector2 = Vector2(slot.position.x, center_y)
		slot.position = flat_position
		if sprite:
			sprite.position = center_sprite_position
		if name_label:
			name_label.offset_left = center_label_left
			name_label.offset_top = center_label_top
			name_label.offset_right = center_label_right
			name_label.offset_bottom = center_label_bottom
		_carousel_layouts.append({
			"position": flat_position,
			"scale": sprite.scale if sprite else Vector2.ONE,
			"font_size": name_label.get_theme_font_size("font_size") if name_label else 12,
			"label_top": name_label.offset_top if name_label else center_label_top,
			"label_bottom": name_label.offset_bottom if name_label else center_label_bottom,
		})

func _wrap_class_index(index: int) -> int:
	var count = _view.get_class_order().size()
	return ((index % count) + count) % count

func _get_active_class_name() -> String:
	return _view.get_class_order()[_wrap_class_index(_current_class_index)]

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
				if sprite.animation != "walk":
					sprite.play("walk")
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
				pulse = float(max(sin(_carousel_idle_time * CLASS_NAME_IDLE_PULSE_SPEED), 0.0) * focus)
			var font_size: float = float(lerp(float(from_layout["font_size"]), float(to_layout["font_size"]), t) + focus * 3.0 + pulse * 2.0)
			name_label.add_theme_font_size_override("font_size", roundi(font_size))
			name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			name_label.scale = Vector2.ONE.lerp(Vector2.ONE * CLASS_NAME_CENTER_SCALE, focus)
			name_label.scale += Vector2.ONE * pulse * 0.03
			var label_top: float = float(lerp(float(from_layout["label_top"]), float(to_layout["label_top"]), t))
			var label_bottom: float = float(lerp(float(from_layout["label_bottom"]), float(to_layout["label_bottom"]), t))
			var lift: float = float(focus * 8.0 + pulse * CLASS_NAME_IDLE_LIFT)
			name_label.offset_top = label_top - lift
			name_label.offset_bottom = label_bottom - lift
			name_label.modulate = Color(1, 1, 1, clamp(CLASS_NAME_SIDE_ALPHA + focus * 0.48 + pulse * 0.08, 0.0, 1.0))

		var center_weight = abs((slot_idx - 2) + _carousel_progress)
		var alpha = clamp(1.0 - center_weight * 0.22, 0.3, 1.0)
		slot.modulate = Color(1, 1, 1, alpha)
		slot.z_index = 10 - int(center_weight * 10.0)

	if direction == 0:
		_update_active_class_panels()

func _update_active_class_panels() -> void:
	var selected_class_id: String = _get_active_class_name()
	_view.update_active_class_panels(selected_class_id)

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

func _is_in_carousel_area(point: Vector2) -> bool:
	return point.y > 90.0 and point.y < 560.0 and abs(point.x - size.x * 0.5) < 520.0

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

func _input(event: InputEvent) -> void:
	if _carousel_nodes.is_empty():
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
			if abs(_drag_delta_x) >= DRAG_TRIGGER_DISTANCE:
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
		_render_carousel(clamp(_drag_delta_x / DRAG_SNAP_DISTANCE, -1.0, 1.0))
		get_viewport().set_input_as_handled()


# ── Chat system ──────────────────────────────────────────────────────────────
func _escape_chat_bbcode(value: String) -> String:
	return value.replace("[", "[lb]").replace("]", "[rb]")

func _get_chat_sender_name() -> String:
	if MultiplayerManager.player_ign.strip_edges().is_empty():
		return "You"
	return MultiplayerManager.player_ign

func _add_chat_message(sender: String, message: String, color: Color = Color(0.7, 0.65, 0.85)):
	if not is_instance_valid(chat_log):
		return
	var hex = color.to_html(false)
	var safe_sender = _escape_chat_bbcode(sender)
	var safe_message = _escape_chat_bbcode(message)
	chat_log.append_text("[color=#" + hex + "][b]" + safe_sender + ":[/b] " + safe_message + "[/color]\n")

func _on_send_chat():
	if not is_instance_valid(chat_input):
		return
	var msg = chat_input.text.strip_edges()
	if msg.is_empty():
		return
	
	# Display locally
	var sender_name = _get_chat_sender_name()
	_add_chat_message(sender_name, msg, Color(0.5, 0.75, 0.95))
	
	# Send to other players via match state
	if MultiplayerManager.is_socket_open() and not MultiplayerManager.match_id.is_empty():
		MultiplayerManager.send_match_state({
			"type": "chat_message",
			"sender": sender_name,
			"message": msg
		})
	
	chat_input.text = ""
	chat_input.grab_focus()

func _on_chat_submitted(_msg: String):
	_on_send_chat()

# ── Class navigation ─────────────────────────────────────────────────────────
func _on_left_pressed():
	_animate_carousel_shift(-1)

func _on_right_pressed():
	_animate_carousel_shift(1)

func _update_class_highlight():
	_render_carousel(0.0)

func _on_select_class_pressed():
	var active_class: String = _get_active_class_name()
	_selected_class = _get_player_class_for_name(active_class)
	if _selected_class:
		var slime_scene_path := _get_slime_scene_path_for_class(active_class)
		if not slime_scene_path.is_empty():
			_selected_class.player_scene = load(slime_scene_path) as PackedScene
		MultiplayerManager.player_class = _selected_class
		_add_chat_message("System", "Selected class: " + active_class, Color(0.4, 0.7, 0.9))
		print("[Lobby] Selected class: ", active_class, " with player_scene: ", _selected_class.player_scene)
		# Broadcast class selection to other players
		if MultiplayerManager.is_socket_open() and not MultiplayerManager.match_id.is_empty():
			MultiplayerManager.send_match_state({
				"type": "class_selected",
				"user_id": MultiplayerManager.session.user_id,
				"class_name": active_class
			})
	else:
		_add_chat_message("System", "Selected class: " + active_class, Color(0.4, 0.7, 0.9))
		print("[Lobby] Selected class: ", active_class)

func _get_player_class_for_name(selected_name: String) -> PlayerClass:
	var class_map := {
		"Tank": preload("res://src/resources/classes/tank/guardian_class.gd"),
		"Archer": preload("res://src/resources/classes/dps/ranger_class.gd"),
		"Mage": preload("res://src/resources/classes/dps/mage_class.gd"),
		"Healer": preload("res://src/resources/classes/support/cleric_class.gd"),
		"Necromancer": preload("res://src/resources/classes/support/necromancer_class.gd"),
	}
	if class_map.has(selected_name):
		return class_map[selected_name].new()
	return null

func _assign_random_slime_variants() -> void:
	var available_variants: Array = SLIME_VARIANT_ORDER.duplicate()
	available_variants.shuffle()
	_class_slime_variants.clear()
	for selected_name in _view.get_class_order():
		if available_variants.is_empty():
			available_variants = SLIME_VARIANT_ORDER.duplicate()
			available_variants.shuffle()
		_class_slime_variants[selected_name] = String(available_variants.pop_front())

func _get_slime_variant_for_class(selected_name: String) -> String:
	return String(_class_slime_variants.get(selected_name, "blue"))

func _get_slime_scene_path_for_class(selected_name: String) -> String:
	var variant := _get_slime_variant_for_class(selected_name)
	return String(SLIME_SCENE_PATHS.get(variant, SLIME_SCENE_PATHS["blue"]))

func _apply_preview_slime_to_sprite(sprite: AnimatedSprite2D, selected_name: String) -> void:
	if sprite == null:
		return
	var material := sprite.material as ShaderMaterial
	if material == null:
		return
	var variant := _get_slime_variant_for_class(selected_name)
	var palette: Dictionary = SLIME_PREVIEW_COLORS.get(variant, SLIME_PREVIEW_COLORS["blue"])
	material.set_shader_parameter("highlight_color", palette["highlight"])
	material.set_shader_parameter("mid_color", palette["mid"])
	material.set_shader_parameter("shadow_color", palette["shadow"])
	material.set_shader_parameter("outline_color", palette["outline"])
	material.set_shader_parameter("iris_color", palette["iris"])

# ── Match state handling ─────────────────────────────────────────────────────
func _on_match_state(match_state):
	# Handle start game
	if match_state.op_code == MultiplayerUtils.OP_START_GAME:
		print("[Lobby] >>> RECEIVED START_GAME OP_CODE 5 <<<")
		_transition_to_game_scene("op_code_5")
		return
	
	# Rate limit op_code 2 (state snapshots)
	if match_state.op_code == 2:
		var current_time = Time.get_ticks_msec()
		if current_time - _last_state_log_time > 2000:
			_last_state_log_time = current_time
			var tick_value = "?"
			if match_state.data:
				var parsed_snapshot = JSON.parse_string(match_state.data)
				if parsed_snapshot is Dictionary:
					tick_value = parsed_snapshot.get("tick", "?")
			print("[Lobby] State snapshot tick: ", tick_value)
	
	elif match_state.op_code != MultiplayerUtils.OP_STATE:
		print("[Lobby] >>> MATCH STATE RECEIVED: op_code=", match_state.op_code, " data=", match_state.data)
	
	var data = JSON.parse_string(match_state.data)
	if data == null:
		return
	
	# Handle server state snapshots
	if data.has("players") and data.has("tick"):
		if str(data.get("phase", "lobby")) == "in_game":
			print("[Lobby] Snapshot reports in_game phase")
			_transition_to_game_scene("snapshot_phase")
			return

		for player_data in data.players:
			var user_id = player_data.get("user_id", "")
			var ign = player_data.get("ign", "")
			var is_host = player_data.get("is_host", false)
			
			if user_id.is_empty() or user_id == MultiplayerManager.session.user_id:
				continue
			
			if MultiplayerManager.players.has(user_id):
				MultiplayerManager.players[user_id]["ign"] = ign
				MultiplayerManager.players[user_id]["is_host"] = is_host
			
			_add_player_entry(user_id, ign, CROWN_EMOJI if is_host else "", is_host)
		_refresh_start_button_state()
		return
	
	var msg_type = data.get("type", "")
	
	match msg_type:
		"player_info":
			var ign = data.get("ign", "")
			var is_host = data.get("is_host", false)
			var entry_id = data.get("user_id", "")
			
			if entry_id.is_empty():
				return
			
			if MultiplayerManager.players.has(entry_id):
				MultiplayerManager.players[entry_id]["ign"] = ign
				MultiplayerManager.players[entry_id]["is_host"] = is_host
			else:
				MultiplayerManager.players[entry_id] = {"ign": ign, "is_host": is_host, "presence": null}
			
			_add_player_entry(entry_id, ign, CROWN_EMOJI if is_host else "", is_host)
			_refresh_start_button_state()
		
		"request_players":
			MultiplayerManager.send_match_state({
				"type": "player_info",
				"user_id": MultiplayerManager.session.user_id,
				"ign": MultiplayerManager.player_ign,
				"is_host": MultiplayerManager.is_host
			})
			if MultiplayerManager.is_host:
				_broadcast_lobby_name()
		
		"lobby_name":
			MultiplayerManager.lobby_name = str(data.get("name", "")).strip_edges()
			_refresh_lobby_title()

		"chat_message":
			# Receive chat from other players
			var sender = data.get("sender", "Unknown")
			var message = data.get("message", "")
			if not message.is_empty():
				_add_chat_message(sender, message, Color(0.7, 0.65, 0.85))
		
		"start_game":
			pass
		
		"class_selected":
			# Another player selected their class
			var sender_id = data.get("user_id", "")
			var selected_name = data.get("class_name", "")
			if not sender_id.is_empty() and sender_id != MultiplayerManager.session.user_id:
				var player_class = _get_player_class_for_name(selected_name)
				if player_class:
					MultiplayerManager.set_player_class(sender_id, player_class)
					print("[Lobby] Player ", sender_id.substr(0, 8), " selected class: ", selected_name)

func _on_start_pressed():
	print("[Lobby] ========== START BUTTON PRESSED ==========")
	print("[Lobby] is_host: ", MultiplayerManager.is_host)
	print("[Lobby] socket: ", MultiplayerManager.socket != null)
	print("[Lobby] match_id: ", MultiplayerManager.match_id)
	
	if MultiplayerManager.is_host:
		if _get_player_count() < 2:
			print("[Lobby] Cannot start game with fewer than 2 players")
			_refresh_start_button_state()
			return
		if MultiplayerManager.is_socket_open() and not MultiplayerManager.match_id.is_empty():
			print("[Lobby] >>> SENDING START_GAME OP_CODE 5 <<<")
			await MultiplayerManager.socket.send_match_state_async(
				MultiplayerManager.match_id,
				MultiplayerUtils.OP_START_GAME,
				JSON.stringify({"type": "start_game"}),
				null
			)
			print("[Lobby] Sent start_game with op_code 5 (awaited)")
		else:
			print("[Lobby] ERROR: Cannot send - socket or match_id missing!")
			return
		start_button.disabled = true
		print("[Lobby] Waiting for authoritative phase change from server...")
	else:
		print("[Lobby] Only host can start the game")

func _show_join_game_ui():
	"""Show UI for late joiners - game is already in progress"""
	print("[Lobby] Game already in progress - showing Join Game UI")
	room_code_button.text = MultiplayerManager.room_code
	
	leave_button.pressed.connect(_on_back_pressed)
	room_code_button.pressed.connect(_on_copy_code_pressed)
	
	# Repurpose start button as join button
	start_button.text = "⚡ Join Quest"
	start_button.visible = true
	start_button.disabled = false
	if not start_button.pressed.is_connected(_on_join_game_pressed):
		start_button.pressed.connect(_on_join_game_pressed)
	
	_add_player_entry(MultiplayerManager.session.user_id, MultiplayerManager.player_ign + " (You)", "", false)
	
	for user_id in MultiplayerManager.players:
		if user_id != MultiplayerManager.session.user_id:
			var info = MultiplayerManager.players[user_id]
			var is_host_flag = info.get("is_host", false)
			var ign = info.get("ign", "Unknown")
			_add_player_entry(user_id, ign, CROWN_EMOJI if is_host_flag else "", is_host_flag)
	
	if MultiplayerManager.socket:
		if not MultiplayerManager.socket.received_match_state.is_connected(_on_match_state):
			MultiplayerManager.socket.received_match_state.connect(_on_match_state)

func _on_join_game_pressed():
	print("[Lobby] ========== JOIN GAME BUTTON PRESSED ==========")
	_transition_to_game_scene("join_game_button")

func _on_back_pressed():
	MultiplayerManager.disconnect_server()
	var tree := get_tree()
	if tree != null:
		tree.change_scene_to_file(MAIN_MENU_SCENE)

func _on_copy_code_pressed():
	DisplayServer.clipboard_set(MultiplayerManager.room_code)
	print("Room code copied: " + MultiplayerManager.room_code)

func _on_match_phase_changed(new_phase: String) -> void:
	if new_phase == "in_game":
		print("[Lobby] Manager phase changed to in_game")
		if not MultiplayerManager.is_host and start_button.visible:
			print("[Lobby] Game started while in lobby - switching to Join Game UI")
			_show_join_game_ui()
		else:
			_transition_to_game_scene("manager_phase")

# ── Preserved class selection API ────────────────────────────────────────────
func get_selected_class() -> PlayerClass:
	return _selected_class

func get_selected_subclass() -> PlayerClass:
	return _selected_subclass
