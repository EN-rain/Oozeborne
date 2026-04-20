extends PanelContainer

## Player info panel - shows name, class, level, HP, and MP bar
## Positioned on the left-middle of the HUD — displays OTHER players only

@onready var header_label: Label = %InfoHeaderLabel
@onready var hp_bar: ProgressBar = %InfoHPBar
@onready var hp_label: Label = %InfoHPLabel
@onready var mana_bar: ProgressBar = %InfoManaBar
@onready var mana_label: Label = %InfoManaLabel

var _player_ref: CharacterBody2D = null


func _ready() -> void:
	_refresh_display()


func set_player(player: CharacterBody2D) -> void:
	# Disconnect previous signals
	if _player_ref != null and is_instance_valid(_player_ref):
		var prev_health = _player_ref.get_node_or_null("Health")
		if prev_health != null and prev_health.health_changed.is_connected(_on_health_changed):
			prev_health.health_changed.disconnect(_on_health_changed)
		var prev_mana = _player_ref.get_node_or_null("Mana")
		if prev_mana != null and prev_mana.mana_changed.is_connected(_on_mana_changed):
			prev_mana.mana_changed.disconnect(_on_mana_changed)
	_player_ref = player
	if _player_ref == null:
		return
	var health = _player_ref.get_node_or_null("Health")
	if health != null:
		if not health.health_changed.is_connected(_on_health_changed):
			health.health_changed.connect(_on_health_changed)
		_on_health_changed(health.current_health, health.max_health)
	var mana_node = _player_ref.get_node_or_null("Mana")
	if mana_node != null:
		if not mana_node.mana_changed.is_connected(_on_mana_changed):
			mana_node.mana_changed.connect(_on_mana_changed)
		_on_mana_changed(mana_node.current_mana, mana_node.max_mana)
	_refresh_display()


func _process(_delta: float) -> void:
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	_refresh_display()


func _refresh_display() -> void:
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	if header_label != null:
		header_label.text = _build_header_text()
	_refresh_mana_display()


func _refresh_mana_display() -> void:
	if _player_ref == null or not is_instance_valid(_player_ref):
		return
	var mana_node = _player_ref.get_node_or_null("Mana")
	if mana_node == null or mana_node.max_mana <= 0:
		# Non-mana class: hide mana bar
		if mana_bar != null:
			mana_bar.visible = false
		if mana_label != null:
			mana_label.visible = false
		return
	if mana_bar != null:
		mana_bar.visible = true
		mana_bar.max_value = mana_node.max_mana
		mana_bar.value = mana_node.current_mana
	if mana_label != null:
		mana_label.visible = true
		mana_label.text = "MP %d / %d" % [mana_node.current_mana, mana_node.max_mana]


func _build_header_text() -> String:
	var level := LevelSystem.get_level(_player_ref)
	var p_class = MultiplayerManager.player_class
	var cls: String = "—"
	if p_class != null:
		cls = str(p_class.display_name)
	var local_line := "%s Lvl%d %s" % [MultiplayerManager.player_ign, level, cls]

	# Show other connected players (names only). Remote HP/MP isn't replicated yet.
	var other_names: Array[String] = []
	if MultiplayerManager.session != null:
		for user_id in MultiplayerManager.players.keys():
			if user_id == MultiplayerManager.session.user_id:
				continue
			var entry = MultiplayerManager.players.get(user_id, {})
			var ign := str(entry.get("ign", ""))
			if ign.is_empty():
				ign = "Player"
			other_names.append(ign)
	other_names.sort()

	if MultiplayerManager.match_id.is_empty():
		return local_line
	if other_names.is_empty():
		return "%s\nAlly: (waiting...)" % local_line
	return "%s\nAlly: %s" % [local_line, ", ".join(other_names)]


func _on_health_changed(current_health: int, max_health: int) -> void:
	if hp_bar != null:
		hp_bar.max_value = max_health
		hp_bar.value = current_health
	if hp_label != null:
		hp_label.text = "HP %d / %d" % [current_health, max_health]


func _on_mana_changed(current_mana: int, max_mana: int) -> void:
	if max_mana <= 0:
		if mana_bar != null:
			mana_bar.visible = false
		if mana_label != null:
			mana_label.visible = false
		return
	if mana_bar != null:
		mana_bar.visible = true
		mana_bar.max_value = max_mana
		mana_bar.value = current_mana
	if mana_label != null:
		mana_label.visible = true
		mana_label.text = "MP %d / %d" % [current_mana, max_mana]
