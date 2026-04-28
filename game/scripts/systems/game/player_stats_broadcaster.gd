extends RefCounted
class_name PlayerStatsBroadcaster

var _interval_sec: float
var _timer_sec: float = 0.0


func _init(interval_sec: float = 0.35) -> void:
	_interval_sec = interval_sec


func tick(delta: float, player: Node) -> void:
	if not MultiplayerManager.is_socket_open() or MultiplayerManager.session == null or player == null or not is_instance_valid(player):
		return
	_timer_sec += delta
	if _timer_sec < _interval_sec:
		return
	_timer_sec = 0.0

	var health := player.get_node_or_null("Health")
	var hp := int(health.current_health) if health != null and "current_health" in health else 0
	var hp_max := int(health.max_health) if health != null and "max_health" in health else 0
	var mana := player.get_node_or_null("Mana")
	var mp := int(mana.current_mana) if mana != null and "current_mana" in mana else 0
	var mp_max := int(mana.max_mana) if mana != null and "max_mana" in mana else 0
	var lvl := int(LevelSystem.get_level(player)) if LevelSystem != null else int(MultiplayerManager.player_level)
	var uid := str(MultiplayerManager.session.user_id)

	if MultiplayerManager.players.has(uid):
		MultiplayerManager.players[uid]["level"] = lvl
		MultiplayerManager.players[uid]["hp"] = hp
		MultiplayerManager.players[uid]["hp_max"] = hp_max
		MultiplayerManager.players[uid]["mp"] = mp
		MultiplayerManager.players[uid]["mp_max"] = mp_max

	MultiplayerManager.send_match_state({
		"type": "player_stats",
		"user_id": uid,
		"level": lvl,
		"hp": hp,
		"hp_max": hp_max,
		"mp": mp,
		"mp_max": mp_max,
	})

