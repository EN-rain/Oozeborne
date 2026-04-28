extends RefCounted
class_name DebugStatsOverlay

var _label: Label
var _ping_timer: Timer
var _label_update_interval_sec: float
var _label_update_timer_sec: float = 0.0


func setup(ui_root: Node, label_node_path: NodePath, ping_timer: Timer, update_interval_sec: float) -> void:
	_label_update_interval_sec = update_interval_sec
	_ping_timer = ping_timer
	_label = ui_root.get_node_or_null(label_node_path) as Label
	if _label != null:
		_label.visible = true
	if _ping_timer != null and not _ping_timer.timeout.is_connected(_on_ping_timeout):
		_ping_timer.timeout.connect(_on_ping_timeout)
		_ping_timer.start()


func tick(delta: float) -> void:
	if _label == null:
		return
	_label_update_timer_sec += delta
	if _label_update_timer_sec < _label_update_interval_sec:
		return
	_label_update_timer_sec = 0.0
	var fps := Engine.get_frames_per_second()
	var ping_ms := int(MultiplayerUtils.get_ping() * 1000)
	var interp_delay := int(MultiplayerUtils.get_interpolation_delay() * 1000)
	var pending := MultiplayerUtils.get_pending_input_count()
	_label.text = "FPS: %d | MS: %d | Interp: %dms | Pending: %d" % [fps, ping_ms, interp_delay, pending]


func _on_ping_timeout() -> void:
	if MultiplayerManager.socket and MultiplayerManager.match_id:
		MultiplayerManager.send_match_state({
			"type": "ping",
			"timestamp": Time.get_ticks_usec() / 1000000.0,
		})

