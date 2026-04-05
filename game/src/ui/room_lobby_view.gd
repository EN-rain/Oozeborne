extends RefCounted
class_name RoomLobbyView

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

const CLASS_ORDER := [
	"Tank",
	"Archer",
	"Mage",
	"Healer",
	"Necromancer",
]
const CLASS_NAME_COLORS := {
	"Tank": Color(0.25, 0.5, 0.75, 1.0),
	"Archer": Color(0.75, 0.25, 0.2, 0.9),
	"Mage": Color(0.75, 0.25, 0.2, 0.9),
	"Healer": Color(0.2, 0.65, 0.35, 0.9),
	"Necromancer": Color(0.2, 0.65, 0.35, 0.9),
}
const SUBCLASS_GROUPS := [
	{"name": "tank", "classes": ["GuardianClass", "BerserkerClass", "PaladinClass"]},
	{"name": "dps", "classes": ["AssassinClass", "RangerClass", "MageClass", "SamuraiClass"]},
	{"name": "support", "classes": ["ClericClass", "BardClass", "AlchemistClass", "NecromancerClass"]},
	{"name": "hybrid", "classes": ["SpellbladeClass", "ShadowKnightClass", "MonkClass"]},
]
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
}
const MAIN_CLASS_TO_SUBCLASS_GROUP := {
	"Tank": "tank",
	"Archer": "dps",
	"Mage": "dps",
	"Healer": "support",
	"Necromancer": "support",
}
const CLASS_PANEL_DATA := {
	"Knight": {
		"stats": {"hp": "1,450", "atk": "245", "def": "180", "spd": "95", "crit": "15%", "evade": "5%", "power": 0.78, "rank": "A-Rank"},
		"talents": [
			{"name": "Bulwark Crest", "desc": "Gain +20% defense while protecting nearby allies.", "accent": Color(0.98, 0.81, 0.22)},
			{"name": "Shield Rush", "desc": "Dash crashes into enemies and briefly stuns them.", "accent": Color(0.62, 0.55, 0.95)},
		],
	},
	"Mage": {
		"stats": {"hp": "980", "atk": "320", "def": "82", "spd": "108", "crit": "22%", "evade": "7%", "power": 0.84, "rank": "S-Rank"},
		"talents": [
			{"name": "Solar Flare", "desc": "Abilities apply burn, dealing bonus damage over time.", "accent": Color(0.98, 0.73, 0.18)},
			{"name": "Aegis Stance", "desc": "Convert a portion of damage taken into a temporary ward.", "accent": Color(0.65, 0.58, 0.98)},
			{"name": "Dawn Dash", "desc": "Dodges leave a streak of light that damages enemies.", "accent": Color(0.95, 0.62, 0.82)},
		],
	},
	"Archer": {
		"stats": {"hp": "1,080", "atk": "268", "def": "104", "spd": "128", "crit": "19%", "evade": "12%", "power": 0.74, "rank": "A-Rank"},
		"talents": [
			{"name": "Falcon Mark", "desc": "Critical hits mark enemies to take bonus team damage.", "accent": Color(0.38, 0.78, 0.58)},
			{"name": "Volley Step", "desc": "Attacking after a dodge fires an extra piercing arrow.", "accent": Color(0.33, 0.67, 0.95)},
		],
	},
	"Healer": {
		"stats": {"hp": "1,220", "atk": "175", "def": "126", "spd": "101", "crit": "9%", "evade": "8%", "power": 0.68, "rank": "B-Rank"},
		"talents": [
			{"name": "Mercy Bloom", "desc": "Healing pulses grant allies a brief regeneration buff.", "accent": Color(0.44, 0.86, 0.55)},
			{"name": "Sanctuary Veil", "desc": "Low-health allies gain a small protective barrier.", "accent": Color(0.56, 0.78, 0.95)},
		],
	},
	"Necromancer": {
		"stats": {"hp": "920", "atk": "286", "def": "78", "spd": "96", "crit": "11%", "evade": "6%", "power": 0.8, "rank": "A-Rank"},
		"talents": [
			{"name": "Soul Harvest", "desc": "Defeated enemies restore health and briefly amplify shadow damage.", "accent": Color(0.62, 0.42, 0.85)},
			{"name": "Grave Swarm", "desc": "Vengeful spirits seek nearby enemies and keep pressure on clustered targets.", "accent": Color(0.38, 0.78, 0.62)},
		],
	},
	"Tank": {
		"stats": {"hp": "1,680", "atk": "190", "def": "225", "spd": "82", "crit": "8%", "evade": "3%", "power": 0.81, "rank": "A-Rank"},
		"talents": [
			{"name": "Iron Bastion", "desc": "Standing still builds armor and reflects minor damage.", "accent": Color(0.95, 0.74, 0.32)},
			{"name": "Groundbreaker", "desc": "Heavy strikes create shockwaves that slow enemies.", "accent": Color(0.75, 0.62, 0.42)},
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
var _power_fill: ColorRect
var _power_rank_label: Label
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
	_power_fill = refs["power_fill"]
	_power_rank_label = refs["power_rank_label"]
	_talent_cards = refs["talent_cards"]
	_stat_cards = refs["stat_cards"]

func get_class_order() -> Array:
	return CLASS_ORDER

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
		entries.append({
			"user_id": user_id,
			"ign": entry.get("ign", "Unknown"),
			"is_host": entry.get("is_host", false),
			"accent_color": entry.get("accent_color", Color(0.5, 0.6, 0.85)),
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
	var group_name: String = str(MAIN_CLASS_TO_SUBCLASS_GROUP.get(active_class, "")).strip_edges()
	if group_name.is_empty():
		return "No subclasses available."

	var group_classes = []
	for group in SUBCLASS_GROUPS:
		if str(group.get("name", "")) == group_name:
			group_classes = group.get("classes", [])
			break

	var active_class_resource_name = active_class.replace(" ", "") + "Class"
	var visible_subclasses = []
	for subclass_name in group_classes:
		var subclass_resource_name = str(subclass_name)
		if subclass_resource_name == active_class_resource_name:
			continue
		var subclass_display_name = subclass_resource_name.trim_suffix("Class")
		var subclass_key = subclass_display_name.replace(" ", "")
		var subclass_desc = str(SUBCLASS_DESCRIPTIONS.get(subclass_key, "Specialized path for this class group."))
		visible_subclasses.append("[b]" + subclass_display_name + "[/b] - " + subclass_desc)

	if visible_subclasses.is_empty():
		return "No subclasses available."

	return "\n\n".join(visible_subclasses)

func _build_party_card(entry: Dictionary) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 58)

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

	var padding = MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 10)
	padding.add_theme_constant_override("margin_top", 8)
	padding.add_theme_constant_override("margin_right", 10)
	padding.add_theme_constant_override("margin_bottom", 8)
	card.add_child(padding)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	padding.add_child(row)

	var avatar_holder = Control.new()
	avatar_holder.custom_minimum_size = Vector2(38, 38)
	row.add_child(avatar_holder)

	var avatar = ColorRect.new()
	avatar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	avatar.color = entry.get("accent_color", Color(0.45, 0.55, 0.85))
	avatar_holder.add_child(avatar)

	var avatar_letter = Label.new()
	avatar_letter.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	avatar_letter.text = entry["ign"].substr(0, 1).to_upper()
	avatar_letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar_letter.add_theme_font_size_override("font_size", 18)
	avatar_letter.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	avatar_holder.add_child(avatar_letter)

	var text_col = VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 2)
	row.add_child(text_col)

	var name_label = Label.new()
	name_label.text = entry["ign"]
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(0, 0, 0, 0.92))
	text_col.add_child(name_label)

	var meta_label = Label.new()
	meta_label.text = "Host" if entry.get("is_host", false) else "Party Member"
	meta_label.add_theme_font_size_override("font_size", 11)
	meta_label.add_theme_color_override("font_color", Color(0, 0, 0, 0.72))
	text_col.add_child(meta_label)

	var badge = Label.new()
	badge.text = "â˜…" if entry.get("is_host", false) else "â€¢"
	badge.add_theme_font_size_override("font_size", 16)
	badge.add_theme_color_override("font_color", entry.get("accent_color", PARTY_CARD_BORDER))
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(badge)

	return card

func _build_waiting_card(slot_number: int) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 48)

	var style = StyleBoxFlat.new()
	style.bg_color = PARTY_CARD_MUTED
	card.add_theme_stylebox_override("panel", style)

	var padding = MarginContainer.new()
	padding.add_theme_constant_override("margin_left", 12)
	padding.add_theme_constant_override("margin_top", 8)
	padding.add_theme_constant_override("margin_right", 12)
	padding.add_theme_constant_override("margin_bottom", 8)
	card.add_child(padding)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	padding.add_child(row)

	var avatar = ColorRect.new()
	avatar.custom_minimum_size = Vector2(32, 32)
	avatar.color = Color(0.86, 0.83, 0.92, 1.0)
	row.add_child(avatar)

	var text_col = VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 1)
	row.add_child(text_col)

	var name_label = Label.new()
	name_label.text = "Waiting for Player"
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color(0, 0, 0, 0.72))
	text_col.add_child(name_label)

	var meta_label = Label.new()
	meta_label.text = "Open Slot %d" % slot_number
	meta_label.add_theme_font_size_override("font_size", 11)
	meta_label.add_theme_color_override("font_color", Color(0, 0, 0, 0.52))
	text_col.add_child(meta_label)

	return card

func _get_class_panel_data(class_id: String) -> Dictionary:
	var fallback: Dictionary = {
		"stats": {"hp": "--", "atk": "--", "def": "--", "spd": "--", "crit": "--", "evade": "--", "power": 0.45, "rank": "C-Rank"},
		"talents": [{"name": "Talent Locked", "desc": "Select a class to preview its combat talents.", "accent": Color(0.76, 0.66, 0.28)}]
	}
	return CLASS_PANEL_DATA.get(class_id, fallback)

func _set_stat_card_value(label: Label, value: String, color: Color = PARTY_TEXT_PRIMARY) -> void:
	if is_instance_valid(label):
		label.text = value
		label.remove_theme_color_override("font_color")

func _rebuild_talent_cards(talents: Array) -> void:
	if not is_instance_valid(_talent_cards):
		return

	for child in _talent_cards.get_children():
		child.queue_free()

	for talent in talents:
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 72)

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
		card.add_theme_stylebox_override("panel", style)
		_talent_cards.add_child(card)

		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_bottom", 10)
		card.add_child(margin)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		margin.add_child(row)

		var text_col = VBoxContainer.new()
		text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_col.add_theme_constant_override("separation", 3)
		row.add_child(text_col)

		var title = Label.new()
		title.text = talent.get("name", "Talent")
		title.add_theme_font_size_override("font_size", 13)
		title.add_theme_color_override("font_color", Color(1, 1, 1, 0.96))
		text_col.add_child(title)

		var desc = Label.new()
		desc.text = talent.get("desc", "")
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", 11)
		desc.add_theme_color_override("font_color", Color(1, 1, 1, 0.88))
		text_col.add_child(desc)

func _update_class_panels(class_id: String) -> void:
	var panel_data: Dictionary = _get_class_panel_data(class_id)
	var stats: Dictionary = panel_data.get("stats", {})

	_set_stat_card_value(_hp_value_label, str(stats.get("hp", "--")))
	_set_stat_card_value(_atk_value_label, str(stats.get("atk", "--")))
	_set_stat_card_value(_def_value_label, str(stats.get("def", "--")))
	_set_stat_card_value(_spd_value_label, str(stats.get("spd", "--")))
	_set_stat_card_value(_crit_value_label, str(stats.get("crit", "--")))
	_set_stat_card_value(_evade_value_label, str(stats.get("evade", "--")))

	if is_instance_valid(_power_fill):
		_power_fill.size_flags_stretch_ratio = float(stats.get("power", 0.45))
	if is_instance_valid(_power_rank_label):
		_power_rank_label.text = str(stats.get("rank", "C-Rank"))
	if is_instance_valid(_talent_cards):
		for child in _talent_cards.get_children():
			child.queue_free()
