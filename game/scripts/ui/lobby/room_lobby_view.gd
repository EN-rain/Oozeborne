extends RefCounted
class_name RoomLobbyView

const PartyCardScene := preload("res://scenes/ui/party_card.tscn")
const WaitingCardScene := preload("res://scenes/ui/waiting_card.tscn")
const TalentCardScene := preload("res://scenes/ui/talent_card.tscn")

const MAX_PARTY_SIZE := 4

const PLAYER_ACCENT_COLORS: Array = [
	Color(0.2, 0.65, 0.35, 1.0),
	Color(0.35, 0.45, 0.85, 1.0),
	Color(0.8, 0.4, 0.25, 1.0),
	Color(0.55, 0.35, 0.75, 1.0),
	Color(0.3, 0.65, 0.7, 1.0),
	Color(0.9, 0.75, 0.3, 1.0),
]
const PARTY_CARD_BG := Color(0.98, 0.96, 0.99, 0.96)
const PARTY_CARD_BORDER := Color(0.76, 0.66, 0.28, 1.0)
const PARTY_CARD_MUTED := Color(0, 0, 0, 0)
const PARTY_TEXT_PRIMARY := Color(0.25, 0.19, 0.12, 1.0)
const PARTY_TEXT_SECONDARY := Color(0.46, 0.38, 0.28, 0.9)
const PARTY_PLACEHOLDER_TEXT := Color(0.5, 0.42, 0.31, 0.78)

const CLASS_NAME_COLORS := {
	"Tank": Color(0.25, 0.5, 0.75, 1.0),
	"DPS": Color(0.75, 0.25, 0.2, 0.9),
	"Support": Color(0.2, 0.65, 0.35, 0.9),
	"Hybrid": Color(0.58, 0.4, 0.82, 0.9),
	"Controller": Color(0.22, 0.66, 0.74, 0.9),
}
const SUBCLASS_DESCRIPTIONS := {
	"Guardian": "Frontline protector with high defense and steady control.",
	"Berserker": "Aggressive bruiser that trades safety for raw damage.",
	"Paladin": "Holy defender mixing durability with support utility.",
	"Assassin": "Fast burst killer focused on crits and target deletion.",
	"Ranger": "Mobile ranged hunter with safe, consistent damage.",
	"Mage": "Glass-cannon caster with powerful spell burst.",
	"Samurai": "Precision duelist with fast strikes and disciplined offense.",
	"Cleric": "Healing specialist that keeps allies alive under pressure.",
	"Bard": "Buffer and enabler who boosts team tempo and survivability.",
	"Alchemist": "Utility support using potions, toxins, and battlefield tricks.",
	"Necromancer": "Dark caster with drain, decay, and soul-harvest sustain.",
	"Spellblade": "Hybrid fighter weaving melee attacks with arcane power.",
	"ShadowKnight": "Dark frontliner blending defense, drain, and pressure.",
	"Monk": "Balanced close-range combatant with speed and self-discipline.",
	"Chronomancer": "Time specialist that slows and desynchronizes enemy tempo.",
	"Warden": "Zone defender that roots and controls movement lanes.",
	"Hexbinder": "Curse caster that suppresses enemy output and scaling.",
	"Stormcaller": "Displacement controller using chained shocks and knockback.",
}
const CLASS_PANEL_DATA := {
	"DPS": {
		"stats": {"hp": "1,080", "atk": "268", "def": "104", "spd": "128", "crit": "19%", "crit_damage": "170%", "power": 0.74, "rank": "A-Rank"},
		"talents": [
			{"name": "Falcon Mark", "desc": "Critical hits mark enemies to take bonus team damage.", "accent": Color(0.38, 0.78, 0.58)},
			{"name": "Volley Step", "desc": "Attacking after a dodge fires an extra piercing arrow.", "accent": Color(0.33, 0.67, 0.95)},
		],
	},
	"Support": {
		"stats": {"hp": "1,220", "atk": "175", "def": "126", "spd": "101", "crit": "9%", "crit_damage": "130%", "power": 0.68, "rank": "B-Rank"},
		"talents": [
			{"name": "Mercy Bloom", "desc": "Healing pulses grant allies a brief regeneration buff.", "accent": Color(0.44, 0.86, 0.55)},
			{"name": "Sanctuary Veil", "desc": "Low-health allies gain a small protective barrier.", "accent": Color(0.56, 0.78, 0.95)},
		],
	},
	"Hybrid": {
		"stats": {"hp": "1,150", "atk": "235", "def": "118", "spd": "112", "crit": "14%", "crit_damage": "150%", "power": 0.77, "rank": "A-Rank"},
		"talents": [
			{"name": "Adaptive Combo", "desc": "Alternating mobility and offense grants stacking bonus output.", "accent": Color(0.62, 0.42, 0.85)},
			{"name": "Stance Echo", "desc": "Skill use alternates defensive and offensive aftereffects.", "accent": Color(0.38, 0.78, 0.62)},
		],
	},
	"Tank": {
		"stats": {"hp": "1,680", "atk": "190", "def": "225", "spd": "82", "crit": "8%", "crit_damage": "120%", "power": 0.81, "rank": "A-Rank"},
		"talents": [
			{"name": "Iron Bastion", "desc": "Standing still builds armor and reflects minor damage.", "accent": Color(0.95, 0.74, 0.32)},
			{"name": "Groundbreaker", "desc": "Heavy strikes create shockwaves that slow enemies.", "accent": Color(0.75, 0.62, 0.42)},
		],
	},
	"Controller": {
		"stats": {"hp": "1,040", "atk": "248", "def": "102", "spd": "114", "crit": "13%", "crit_damage": "145%", "power": 0.79, "rank": "A-Rank"},
		"talents": [
			{"name": "Control Field", "desc": "Control zones apply slow and damage suppression.", "accent": Color(0.28, 0.78, 0.83)},
			{"name": "Tempo Lock", "desc": "Controlled targets take increased ability damage.", "accent": Color(0.56, 0.75, 0.94)},
		],
	},
}

var _players_title: Label
var _players_list: VBoxContainer
var _stats_content: RichTextLabel
var _subclass_content: RichTextLabel
var _hp_value_label: Label
var _atk_value_label: Label
var _def_value_label: Label
var _spd_value_label: Label
var _crit_value_label: Label
var _evade_value_label: Label
var _talent_cards: VBoxContainer
var _stat_cards: Array = []

func _init(refs: Dictionary) -> void:
	_players_title = refs["players_title"]
	_players_list = refs["players_list"]
	_stats_content = refs["stats_content"]
	_subclass_content = refs["subclass_content"]
	_hp_value_label = refs["hp_value_label"]
	_atk_value_label = refs["atk_value_label"]
	_def_value_label = refs["def_value_label"]
	_spd_value_label = refs["spd_value_label"]
	_crit_value_label = refs["crit_value_label"]
	_evade_value_label = refs["evade_value_label"]
	_talent_cards = refs["talent_cards"]
	_stat_cards = refs["stat_cards"]

func get_class_order() -> Array:
	return ClassManager.get_main_class_display_order()

func get_class_name_color(class_id: String) -> Color:
	return CLASS_NAME_COLORS.get(class_id, PARTY_TEXT_PRIMARY)

func get_next_player_accent(existing_entry_count: int) -> Color:
	return PLAYER_ACCENT_COLORS[existing_entry_count % PLAYER_ACCENT_COLORS.size()]

func setup_right_panels() -> void:
	for card in _stat_cards:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
		style.border_width_left = 0
		style.border_width_top = 0
		style.border_width_right = 0
		style.border_width_bottom = 0
		style.shadow_size = 0
		card.add_theme_stylebox_override("panel", style)
		var title: Label = card.get_node_or_null("Margin/VBox/Label") as Label
		var value: Label = card.get_node_or_null("Margin/VBox/Value") as Label
		if is_instance_valid(title):
			title.remove_theme_color_override("font_color")
		if is_instance_valid(value):
			value.remove_theme_color_override("font_color")

func refresh_party_cards(player_entries: Dictionary) -> void:
	if not is_instance_valid(_players_list):
		return

	for child in _players_list.get_children():
		child.queue_free()

	var entries: Array = []
	for user_id in player_entries:
		var entry = player_entries[user_id]
		var slime_variant = "blue"
		if MultiplayerManager.players.has(user_id):
			slime_variant = str(MultiplayerManager.players[user_id].get("slime_variant", "blue"))
		entries.append({
			"user_id": user_id,
			"ign": entry.get("ign", "Unknown"),
			"is_host": entry.get("is_host", false),
			"accent_color": entry.get("accent_color", Color(0.5, 0.6, 0.85)),
			"slime_variant": slime_variant,
			"selected_class": entry.get("selected_class", ""),
		})

	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["is_host"] != b["is_host"]:
			return a["is_host"]
		return a["ign"].nocasecmp_to(b["ign"]) < 0
	)

	if is_instance_valid(_players_title):
		_players_title.text = "Party (%d/%d)" % [entries.size(), MAX_PARTY_SIZE]

	for entry in entries:
		_players_list.add_child(_build_party_card(entry))

	for slot_index in range(entries.size(), MAX_PARTY_SIZE):
		_players_list.add_child(_build_waiting_card(slot_index + 1))

func update_active_class_panels(active_class: String) -> void:
	if is_instance_valid(_stats_content):
		_stats_content.clear()
		_stats_content.append_text("[center][b]" + active_class + "[/b][/center]")
	if is_instance_valid(_subclass_content):
		_subclass_content.clear()
		_subclass_content.visible = true
		_subclass_content.append_text(_build_subclass_info_text(active_class))
	if is_instance_valid(_talent_cards):
		_talent_cards.visible = false
	_update_class_panels(active_class)

func _build_subclass_info_text(active_class: String) -> String:
	var main_class_id := ClassManager.display_name_to_class_id(active_class)
	if main_class_id.is_empty():
		return "No subclasses available."

	var visible_subclasses = []
	for subclass_id in ClassManager.get_subclass_ids_for_main_id(main_class_id):
		var subclass_instance := ClassManager.get_class_by_id(subclass_id)
		if subclass_instance == null:
			continue
		var subclass_display_name := subclass_instance.display_name
		var subclass_key = subclass_display_name.replace(" ", "")
		var subclass_desc = str(SUBCLASS_DESCRIPTIONS.get(subclass_key, "Specialized path for this class group."))
		visible_subclasses.append("[b]" + subclass_display_name + "[/b] - " + subclass_desc)

	if visible_subclasses.is_empty():
		return "No subclasses available."

	return "\n\n".join(visible_subclasses)

func _build_party_card(entry: Dictionary) -> Control:
	var card = PartyCardScene.instantiate()

	# Apply dynamic style based on host status
	var style = StyleBoxFlat.new()
	style.bg_color = PARTY_CARD_BG
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = PARTY_CARD_BORDER if entry.get("is_host", false) else Color(0.88, 0.84, 0.94, 1.0)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	card.add_theme_stylebox_override("panel", style)

	# Avatar color from slime variant
	var avatar: ColorRect = card.get_node("Padding/Row/AvatarHolder/Avatar")
	var slime_variant = entry.get("slime_variant", "blue")
	var palette = SlimePaletteRegistry.get_preview_palette(slime_variant)
	avatar.color = palette.get("mid", Color(0.45, 0.55, 0.85))

	# Avatar letter
	var avatar_letter: Label = card.get_node("Padding/Row/AvatarHolder/AvatarLetter")
	avatar_letter.text = entry["ign"].substr(0, 1).to_upper()

	# Text labels
	var name_label: Label = card.get_node("Padding/Row/TextCol/NameLabel")
	name_label.text = entry["ign"]

	var meta_label: Label = card.get_node("Padding/Row/TextCol/MetaLabel")
	meta_label.text = "Party Leader" if entry.get("is_host", false) else "Party Member"

	var class_label: Label = card.get_node("Padding/Row/TextCol/ClassLabel")
	var selected_class = entry.get("selected_class", "")
	class_label.text = "Class: " + selected_class if not selected_class.is_empty() else "No class selected"
	var class_color = get_class_name_color(selected_class) if not selected_class.is_empty() else Color(0.5, 0.5, 0.5, 0.6)
	class_label.add_theme_color_override("font_color", class_color)

	var badge: Label = card.get_node("Padding/Row/Badge")
	badge.text = "*" if entry.get("is_host", false) else "-"
	badge.add_theme_color_override("font_color", entry.get("accent_color", PARTY_CARD_BORDER))

	return card

func _build_waiting_card(slot_number: int) -> Control:
	var card = WaitingCardScene.instantiate()

	var style = StyleBoxFlat.new()
	style.bg_color = PARTY_CARD_MUTED
	card.add_theme_stylebox_override("panel", style)

	var meta_label: Label = card.get_node("Padding/Row/TextCol/MetaLabel")
	meta_label.text = "Open Slot %d" % slot_number

	return card

func _get_class_panel_data(class_id: String) -> Dictionary:
	var fallback: Dictionary = {
		"stats": {"hp": "--", "atk": "--", "def": "--", "spd": "--", "crit": "--", "crit_damage": "--", "power": 0.45, "rank": "C-Rank"},
		"talents": [{"name": "Talent Locked", "desc": "Select a class to preview its combat talents.", "accent": Color(0.76, 0.66, 0.28)}]
	}
	return CLASS_PANEL_DATA.get(class_id, fallback)

func _set_stat_card_value(label: Label, value: String, _color: Color = PARTY_TEXT_PRIMARY) -> void:
	if is_instance_valid(label):
		label.text = value
		label.remove_theme_color_override("font_color")

func _rebuild_talent_cards(talents: Array) -> void:
	if not is_instance_valid(_talent_cards):
		return

	for child in _talent_cards.get_children():
		child.queue_free()

	for talent in talents:
		var card = TalentCardScene.instantiate()

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
		card.add_theme_stylebox_override("panel", style)

		var title: Label = card.get_node("Margin/Row/TextCol/Title")
		title.text = talent.get("name", "Talent")

		var desc: Label = card.get_node("Margin/Row/TextCol/Desc")
		desc.text = talent.get("desc", "")

		_talent_cards.add_child(card)

func _update_class_panels(class_id: String) -> void:
	var panel_data: Dictionary = _get_class_panel_data(class_id)
	var stats: Dictionary = panel_data.get("stats", {})

	_set_stat_card_value(_hp_value_label, str(stats.get("hp", "--")))
	_set_stat_card_value(_atk_value_label, str(stats.get("atk", "--")))
	_set_stat_card_value(_def_value_label, str(stats.get("def", "--")))
	_set_stat_card_value(_spd_value_label, str(stats.get("spd", "--")))
	_set_stat_card_value(_crit_value_label, str(stats.get("crit", "--")))
	_set_stat_card_value(_evade_value_label, str(stats.get("crit_damage", "--")))

	if is_instance_valid(_talent_cards):
		for child in _talent_cards.get_children():
			child.queue_free()
		_rebuild_talent_cards(panel_data.get("talents", []))
		_talent_cards.visible = true
