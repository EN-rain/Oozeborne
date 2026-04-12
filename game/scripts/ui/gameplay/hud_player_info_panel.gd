extends PanelContainer

## Player info panel - shows name, class, level, HP, and mana/XP bar
## Positioned on the left-middle of the HUD

@onready var header_label: Label = %InfoHeaderLabel
@onready var hp_bar: ProgressBar = %InfoHPBar
@onready var hp_label: Label = %InfoHPLabel
@onready var mana_bar: ProgressBar = %InfoManaBar
@onready var mana_label: Label = %InfoManaLabel

var _player_ref: CharacterBody2D = null


func _ready() -> void:
	_refresh_display()


func set_player(player: CharacterBody2D) -> void:
	if _player_ref != null and is_instance_valid(_player_ref):
		var prev_health = _player_ref.get_node_or_null("Health")
		if prev_health != null and prev_health.health_changed.is_connected(_on_health_changed):
			prev_health.health_changed.disconnect(_on_health_changed)
	_player_ref = player
	if _player_ref == null:
		return
	var health = _player_ref.get_node_or_null("Health")
	if health != null:
		if not health.health_changed.is_connected(_on_health_changed):
			health.health_changed.connect(_on_health_changed)
		_on_health_changed(health.current_health, health.max_health)
	_refresh_display()


func _process(_delta: float) -> void:
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	_refresh_xp_display()


func _refresh_display() -> void:
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	if header_label != null:
		header_label.text = _build_header_text()
	_refresh_xp_display()


func _refresh_xp_display() -> void:
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	var xp_progress := LevelSystem.get_xp_progress(_player_ref)
	if header_label != null:
		header_label.text = _build_header_text()
	if mana_bar != null:
		mana_bar.value = xp_progress * 100.0
	if mana_label != null:
		mana_label.text = "%d%%" % int(xp_progress * 100.0)


func _build_header_text() -> String:
	var level := LevelSystem.get_level(_player_ref)
	var p_class = MultiplayerManager.player_class
	var cls: String = "—"
	if p_class != null:
		cls = str(p_class.display_name)
	return "%s Lvl%d %s" % [MultiplayerManager.player_ign, level, cls]


func _on_health_changed(current_health: int, max_health: int) -> void:
	if hp_bar != null:
		hp_bar.max_value = max_health
		hp_bar.value = current_health
	if hp_label != null:
		hp_label.text = "HP %d / %d" % [current_health, max_health]
