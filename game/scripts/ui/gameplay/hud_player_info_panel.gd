extends PanelContainer

## Party info panel - shows all connected players (2-4p): level, name, HP, MP.
## Remote HP/MP/level are broadcast via `player_stats` match messages.

@onready var header_label: Label = %InfoHeaderLabel
@onready var hp_bar: ProgressBar = %InfoHPBar
@onready var hp_label: Label = %InfoHPLabel
@onready var mana_bar: ProgressBar = %InfoManaBar
@onready var mana_label: Label = %InfoManaLabel

var _player_ref: CharacterBody2D = null


func _ready() -> void:
	if hp_bar != null:
		hp_bar.visible = false
	if mana_bar != null:
		mana_bar.visible = false
	_refresh_display()


func set_player(player: CharacterBody2D) -> void:
	_player_ref = player
	_refresh_display()


func _process(_delta: float) -> void:
	_refresh_display()


func _refresh_display() -> void:
	if header_label == null or hp_label == null:
		return
	_render_party_info()


func _render_party_info() -> void:
	var entries: Array[Dictionary] = []
	for user_id in MultiplayerManager.players.keys():
		var entry: Dictionary = MultiplayerManager.players.get(user_id, {})
		var ign := str(entry.get("ign", "")).strip_edges()
		if ign.is_empty():
			ign = "Player"
		entries.append({
			"user_id": str(user_id),
			"ign": ign,
			"is_host": bool(entry.get("is_host", false)),
			"level": int(entry.get("level", 1)),
			"hp": entry.get("hp", null),
			"hp_max": entry.get("hp_max", null),
			"mp": entry.get("mp", null),
			"mp_max": entry.get("mp_max", null),
		})

	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.get("is_host", false) != b.get("is_host", false):
			return bool(a.get("is_host", false))
		return str(a.get("ign", "")).nocasecmp_to(str(b.get("ign", ""))) < 0
	)

	header_label.text = "Party (%d/4)" % entries.size()

	var lines: Array[String] = []
	for e in entries:
		var lvl := int(e.get("level", 1))
		var name := str(e.get("ign", "Player"))
		var hp_txt := "?/?"
		if e.get("hp") != null and e.get("hp_max") != null:
			hp_txt = "%d/%d" % [int(e.get("hp")), int(e.get("hp_max"))]
		var mp_txt := "--"
		if e.get("mp_max") != null and int(e.get("mp_max")) > 0:
			if e.get("mp") != null:
				mp_txt = "%d/%d" % [int(e.get("mp")), int(e.get("mp_max"))]
			else:
				mp_txt = "?/?"
		lines.append("Lvl%d %s  HP %s  MP %s" % [lvl, name, hp_txt, mp_txt])

	hp_label.text = "\n".join(lines)
	if mana_label != null:
		mana_label.visible = false

