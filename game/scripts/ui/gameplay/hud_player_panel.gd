extends Control
class_name HudPlayerPanel

signal player_died(killer_name: String)

@onready var health_bar: ProgressBar = %HealtBar
@onready var xp_bar: ProgressBar = %ManaBar
@onready var level_label: Label = %LevelLabel
@onready var player_name_label: Label = %PlayerName
@onready var coin_label: Label = %CoinLabel

var _player_ref: CharacterBody2D = null


func _ready() -> void:
	if CoinManager != null and not CoinManager.coins_changed.is_connected(_on_coins_changed):
		CoinManager.coins_changed.connect(_on_coins_changed)
	_on_coins_changed(CoinManager.get_coins() if CoinManager != null else 0)


func set_player(player: CharacterBody2D) -> void:
	if _player_ref != null and is_instance_valid(_player_ref):
		var previous_health = _player_ref.get_node_or_null("Health")
		if previous_health != null and previous_health.health_changed.is_connected(_on_health_changed):
			previous_health.health_changed.disconnect(_on_health_changed)
		if _player_ref.has_signal("death_sequence_finished") and _player_ref.death_sequence_finished.is_connected(_on_player_died):
			_player_ref.death_sequence_finished.disconnect(_on_player_died)

	_player_ref = player
	if _player_ref == null:
		return

	var health = _player_ref.get_node_or_null("Health")
	if health != null and not health.health_changed.is_connected(_on_health_changed):
		health.health_changed.connect(_on_health_changed)
		_on_health_changed(health.current_health, health.max_health)
	if _player_ref.has_signal("death_sequence_finished") and not _player_ref.death_sequence_finished.is_connected(_on_player_died):
		_player_ref.death_sequence_finished.connect(_on_player_died)

	if player_name_label != null:
		player_name_label.text = MultiplayerManager.player_ign
	refresh_level_display(LevelSystem.get_level(_player_ref), LevelSystem.get_xp_progress(_player_ref))


func refresh_level_display(level: int, xp_progress: float) -> void:
	if level_label != null:
		level_label.text = "Lv.%d" % level
	if xp_bar != null:
		xp_bar.value = xp_progress * 100.0


func _on_health_changed(current_health: float, max_health: float) -> void:
	if health_bar != null:
		health_bar.max_value = max_health
		health_bar.value = current_health


func _on_coins_changed(total: int) -> void:
	if coin_label != null:
		coin_label.text = str(total)


func _on_player_died(killer_name: String = "") -> void:
	player_died.emit(killer_name)
