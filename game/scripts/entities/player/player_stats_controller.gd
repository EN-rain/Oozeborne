extends Node
class_name PlayerStatsController

var _player: CharacterBody2D
var _health: Node


func setup(player: CharacterBody2D, health: Node) -> void:
	_player = player
	_health = health


func _ensure_refs() -> void:
	if _player == null:
		_player = get_parent() as CharacterBody2D
	if _health == null and _player != null:
		_health = _player.get_node_or_null("Health")


func register_player() -> void:
	_ensure_refs()
	if _player == null:
		return
	LevelSystem.register_player(_player, max(1, MultiplayerManager.player_level))


func unregister_player() -> void:
	_ensure_refs()
	if _player == null:
		return
	LevelSystem.unregister_player(_player)


func apply_class_modifiers() -> void:
	_ensure_refs()
	if _player == null:
		return
	var level_stats: Dictionary = LevelSystem.get_current_stats(_player)
	if level_stats.is_empty():
		LevelSystem.register_player(_player, max(1, MultiplayerManager.player_level))
		level_stats = LevelSystem.get_current_stats(_player)
	reapply_class_modifiers_after_level_sync(level_stats)
	var main_class = MultiplayerManager.player_class
	if main_class != null:
		print("[Player] Applied class modifiers: %s" % main_class.display_name)


func apply_subclass_modifiers(player_subclass: PlayerClass) -> void:
	_ensure_refs()
	if player_subclass == null:
		return
	reapply_class_modifiers_after_level_sync(LevelSystem.get_current_stats(_player))
	print("[Player] Applied subclass modifiers: %s" % player_subclass.display_name)


func reapply_class_modifiers_after_level_sync(base_stats: Dictionary) -> void:
	_ensure_refs()
	var main_class: PlayerClass = MultiplayerManager.player_class
	var player_subclass: PlayerClass = MultiplayerManager.player_subclass

	if _player == null or main_class == null:
		return

	var speed_mult: float = main_class.modifiers_speed
	var damage_mult: float = main_class.modifiers_damage
	var hp_mult: float = main_class.modifiers_hp
	var defense_mult: float = main_class.modifiers_defense
	var atk_speed_mult: float = main_class.modifiers_attack_speed
	var crit_chance_bonus: float = maxf(main_class.modifiers_crit_chance - 1.0, 0.0)
	var crit_damage_bonus: float = maxf(main_class.modifiers_crit_damage - 1.0, 0.0)
	var lifesteal: float = 0.0
	var dodge: float = 0.0

	if player_subclass != null:
		speed_mult *= 1.0 + (player_subclass.modifiers_speed - 1.0) * 0.5
		damage_mult *= 1.0 + (player_subclass.modifiers_damage - 1.0) * 0.5
		hp_mult *= 1.0 + (player_subclass.modifiers_hp - 1.0) * 0.5
		defense_mult *= 1.0 + (player_subclass.modifiers_defense - 1.0) * 0.5
		atk_speed_mult *= 1.0 + (player_subclass.modifiers_attack_speed - 1.0) * 0.5
		crit_chance_bonus += maxf(player_subclass.modifiers_crit_chance - 1.0, 0.0) * 0.5
		crit_damage_bonus += maxf(player_subclass.modifiers_crit_damage - 1.0, 0.0) * 0.5

	var raw_speed: float = float(base_stats.get("speed", _player.speed))
	var raw_dash_speed: float = float(base_stats.get("dash_speed", _player.dash_speed))
	var raw_dash_cd: float = float(base_stats.get("dash_cooldown", _player.dash_cooldown))
	var raw_attack_damage: int = int(base_stats.get("attack_damage", _player.attack_damage))
	var raw_crit_chance: float = float(base_stats.get("crit_chance", 0.05))
	var raw_crit_damage: float = float(base_stats.get("crit_damage", 1.10))

	_player.speed = raw_speed * speed_mult
	_player.dash_speed = raw_dash_speed * speed_mult
	_player.dash_cooldown = raw_dash_cd / max(atk_speed_mult, 0.01)
	_player.attack_damage = int(raw_attack_damage * damage_mult)

	if _health:
		var raw_max_health: int = int(base_stats.get("max_health", _health.max_health))
		var ratio: float = float(_health.current_health) / float(max(_health.max_health, 1))
		_health.max_health = int(raw_max_health * hp_mult)
		_health.current_health = int(_health.max_health * clamp(ratio, 0.0, 1.0))

	_player.set_meta("lifesteal", lifesteal)
	_player.set_meta("dodge_chance", dodge)
	_player.set_meta("crit_chance", clampf(raw_crit_chance + crit_chance_bonus, 0.0, 0.75))
	_player.set_meta("crit_damage", raw_crit_damage + crit_damage_bonus)
	_player.set_meta("defense_modifier", defense_mult)
