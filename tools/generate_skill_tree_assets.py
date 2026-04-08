from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GAME_ROOT = ROOT / "game"
REFERENCE_PATH = ROOT / "docs" / "SkillTreeReference.md"
SKILL_ROOT = GAME_ROOT / "resources" / "skills"
RUNTIME_DATA_PATH = GAME_ROOT / "scripts" / "globals" / "skill_tree_runtime_data.gd"

SPECIAL_MAIN_CLASSES = {"tank", "dps", "support", "hybrid", "controller"}
SKILL_TYPE_ENUM = {
    "Stat": 0,
    "Ability": 1,
    "Passive": 2,
    "Special": 3,
}


@dataclass
class SkillRow:
    main_class: str
    tree_key: str
    name: str
    skill_type: str
    description: str
    initial: str
    per_level: str
    max_value: str

    @property
    def normalized_name(self) -> str:
        return slugify(self.name)

    @property
    def skill_id(self) -> str:
        suffix = self.skill_type.lower()
        return f"{self.main_class}_{self.tree_key}_{self.normalized_name}_{suffix}"

    @property
    def resource_dir(self) -> Path:
        return SKILL_ROOT / self.main_class / self.tree_key

    @property
    def resource_name(self) -> str:
        return f"{self.skill_id}.tres"


STAT_RULES = {
    "tank_main_fortify_stat": {"kind": "property_percent", "target": "max_health", "value": 0.05},
    "tank_main_iron_skin_stat": {"kind": "meta_flat", "target": "armor_flat_bonus", "value": 3.0},
    "tank_guardian_stalwart_stat": {"kind": "meta_percent", "target": "block_chance_bonus", "value": 0.02},
    "tank_guardian_ironclad_stat": {"kind": "meta_percent", "target": "armor_penetration_resistance_bonus", "value": 0.05},
    "tank_berserker_rage_stat": {"kind": "property_percent", "target": "attack_damage", "value": 0.04},
    "tank_berserker_endurance_stat": {"kind": "meta_flat", "target": "hp_regen_bonus", "value": 1.0},
    "tank_paladin_holy_might_stat": {"kind": "meta_percent", "target": "holy_damage_bonus", "value": 0.05},
    "tank_paladin_grace_stat": {"kind": "meta_percent", "target": "healing_received_bonus", "value": 0.04},
    "dps_main_sharpen_stat": {"kind": "property_percent", "target": "attack_damage", "value": 0.03},
    "dps_main_precision_stat": {"kind": "meta_percent", "target": "crit_chance_bonus", "value": 0.02},
    "dps_assassin_lethal_edge_stat": {"kind": "meta_percent", "target": "crit_damage_bonus", "value": 0.10},
    "dps_assassin_evasion_stat": {"kind": "meta_percent", "target": "dodge_chance_bonus", "value": 0.02},
    "dps_ranger_hawk_eye_stat": {"kind": "meta_percent", "target": "attack_range_bonus", "value": 0.05},
    "dps_ranger_swift_shot_stat": {"kind": "meta_percent", "target": "attack_speed_bonus", "value": 0.03},
    "dps_mage_arcane_surge_stat": {"kind": "meta_percent", "target": "spell_damage_bonus", "value": 0.05},
    "dps_mage_focus_stat": {"kind": "meta_flat", "target": "mana_bonus", "value": 10.0},
    "dps_samurai_blade_mastery_stat": {"kind": "meta_percent", "target": "physical_damage_bonus", "value": 0.04},
    "dps_samurai_composure_stat": {"kind": "meta_percent", "target": "crit_resistance_bonus", "value": 0.03},
    "support_main_mending_stat": {"kind": "meta_percent", "target": "healing_power_bonus", "value": 0.04},
    "support_main_resilience_stat": {"kind": "meta_percent", "target": "ally_defense_aura_bonus", "value": 0.03},
    "support_cleric_sanctify_stat": {"kind": "meta_percent", "target": "holy_healing_bonus", "value": 0.05},
    "support_cleric_devotion_stat": {"kind": "meta_flat", "target": "buff_duration_bonus", "value": 1.0},
    "support_bard_inspiration_stat": {"kind": "meta_percent", "target": "buff_strength_bonus", "value": 0.03},
    "support_bard_rhythm_stat": {"kind": "property_percent", "target": "speed", "value": 0.04},
    "support_alchemist_toxicology_stat": {"kind": "meta_percent", "target": "poison_damage_bonus", "value": 0.05},
    "support_alchemist_preparation_stat": {"kind": "meta_flat", "target": "ability_item_slots_bonus", "value": 0.2},
    "support_necromancer_undead_mastery_stat": {"kind": "meta_percent", "target": "minion_power_bonus", "value": 0.10},
    "support_necromancer_soul_reaping_stat": {"kind": "meta_flat", "target": "max_summon_count_bonus", "value": 0.2},
    "hybrid_main_arcane_blade_stat": {"kind": "meta_percent", "target": "magic_melee_damage_bonus", "value": 0.04},
    "hybrid_main_mystic_armor_stat": {"kind": "meta_multi", "entries": [
        {"kind": "meta_flat", "target": "armor_flat_bonus", "value": 3.0},
        {"kind": "meta_flat", "target": "spell_resistance_flat_bonus", "value": 3.0},
    ]},
    "hybrid_spellblade_mana_blade_stat": {"kind": "meta_percent", "target": "magic_melee_damage_bonus", "value": 0.05},
    "hybrid_spellblade_resonance_stat": {"kind": "meta_percent", "target": "spell_cooldown_reduction_bonus", "value": 0.02},
    "hybrid_shadow_knight_shadow_power_stat": {"kind": "meta_percent", "target": "dark_damage_bonus", "value": 0.05},
    "hybrid_shadow_knight_eclipse_stat": {"kind": "meta_percent", "target": "low_health_damage_bonus", "value": 0.04},
    "hybrid_monk_chi_flow_stat": {"kind": "meta_flat", "target": "resource_regen_bonus", "value": 2.0},
    "hybrid_monk_discipline_stat": {"kind": "meta_percent", "target": "combo_damage_bonus", "value": 0.03},
    "controller_main_command_stat": {"kind": "meta_flat", "target": "control_duration_bonus", "value": 0.4},
    "controller_main_tactical_mind_stat": {"kind": "meta_percent", "target": "control_cooldown_reduction_bonus", "value": 0.03},
    "controller_chronomancer_time_warp_stat": {"kind": "property_percent", "target": "speed", "value": 0.03},
    "controller_chronomancer_decay_stat": {"kind": "meta_flat", "target": "control_dot_bonus", "value": 5.0},
    "controller_warden_fortification_stat": {"kind": "meta_percent", "target": "barrier_hp_bonus", "value": 0.10},
    "controller_warden_entrapment_stat": {"kind": "meta_flat", "target": "root_duration_bonus", "value": 0.4},
    "controller_hexbinder_dark_mark_stat": {"kind": "meta_percent", "target": "curse_damage_bonus", "value": 0.04},
    "controller_hexbinder_affliction_stat": {"kind": "meta_percent", "target": "curse_debuff_strength_bonus", "value": 0.03},
    "controller_stormcaller_voltage_stat": {"kind": "meta_percent", "target": "lightning_damage_bonus", "value": 0.05},
    "controller_stormcaller_surge_stat": {"kind": "meta_percent", "target": "knockback_and_stun_bonus", "value": 0.10},
}


PASSIVE_RULES = {
    "tank_main_unbreakable_passive": {"target": "damage_reduction_above_half_hp", "kind": "meta_percent", "value": 0.02},
    "tank_guardian_allied_ward_passive": {"target": "allied_damage_reduction_per_ally", "kind": "meta_percent", "value": 0.01},
    "tank_berserker_adrenaline_passive": {"target": "missing_hp_damage_bonus", "kind": "meta_percent", "value": 0.10},
    "tank_paladin_holy_light_passive": {"target": "damage_to_healing_ratio", "kind": "meta_percent", "value": 0.01},
    "dps_main_executioner_passive": {"target": "execute_damage_bonus", "kind": "meta_percent", "value": 0.10},
    "dps_assassin_backstab_passive": {"target": "backstab_damage_bonus", "kind": "meta_percent", "value": 0.10},
    "dps_ranger_hunters_mark_passive": {"target": "marked_damage_taken_bonus", "kind": "meta_percent", "value": 0.03},
    "dps_mage_mana_shield_passive": {"target": "mana_shield_conversion", "kind": "meta_percent", "value": 0.02},
    "dps_samurai_way_of_the_warrior_passive": {"target": "consecutive_hit_damage_bonus", "kind": "meta_percent", "value": 0.01},
    "support_main_steady_hands_passive": {"target": "healing_cooldown_reduction", "kind": "meta_percent", "value": 0.03},
    "support_cleric_healing_aura_passive": {"target": "healing_aura_regen", "kind": "meta_flat", "value": 0.4},
    "support_bard_inspiring_presence_passive": {"target": "ally_damage_aura_bonus", "kind": "meta_percent", "value": 0.02},
    "support_alchemist_transmutation_passive": {"target": "consumable_effectiveness_bonus", "kind": "meta_percent", "value": 0.10},
    "support_necromancer_soul_harvest_passive": {"target": "kill_heal_bonus", "kind": "meta_flat", "value": 2.0},
    "hybrid_main_versatility_passive": {"target": "mana_cost_reduction", "kind": "meta_percent", "value": 0.04},
    "hybrid_spellblade_arcane_strike_passive": {"target": "fourth_hit_magic_bonus", "kind": "meta_percent", "value": 0.06},
    "hybrid_shadow_knight_vampiric_embrace_passive": {"target": "lifesteal_effectiveness_bonus", "kind": "meta_percent", "value": 0.10},
    "hybrid_monk_flow_state_passive": {"target": "dodge_trigger_attack_speed_bonus", "kind": "meta_percent", "value": 0.04},
    "controller_main_tempo_lock_passive": {"target": "control_zone_enemy_damage_reduction", "kind": "meta_percent", "value": 0.03},
    "controller_chronomancer_borrowed_seconds_passive": {"target": "control_burst_cdr_bonus", "kind": "meta_percent", "value": 0.06},
    "controller_warden_line_holder_passive": {"target": "zone_enemy_damage_reduction", "kind": "meta_percent", "value": 0.04},
    "controller_hexbinder_malice_chain_passive": {"target": "curse_spread_chance", "kind": "meta_percent", "value": 0.10},
    "controller_stormcaller_static_build_passive": {"target": "controlled_target_lightning_bonus", "kind": "meta_percent", "value": 0.01},
}


def slugify(value: str) -> str:
    cleaned = value.lower().replace("&", "and").replace("'", "")
    cleaned = re.sub(r"[^a-z0-9]+", "_", cleaned)
    return cleaned.strip("_")


def parse_reference() -> list[SkillRow]:
    text = REFERENCE_PATH.read_text(encoding="utf-8")
    current_main = ""
    current_tree = ""
    current_tree_kind = ""
    pending_special_name = ""
    rows: list[SkillRow] = []

    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line:
            continue

        main_match = re.match(r"^## ([A-Za-z /-]+)$", line)
        if main_match and main_match.group(1) in {"Tank", "DPS", "Support", "Hybrid", "Controller"}:
            current_main = slugify(main_match.group(1))
            current_tree = "main"
            current_tree_kind = "main"
            pending_special_name = ""
            continue

        subclass_match = re.match(r"^### Subclass: ([A-Za-z /-]+?)(?: \(|$)", line)
        if subclass_match:
            current_tree = slugify(subclass_match.group(1))
            current_tree_kind = "subclass"
            pending_special_name = ""
            continue

        special_match = re.match(r"^\*\*Special Ability .*? ([^(]+?) \(", line)
        if special_match:
            pending_special_name = special_match.group(1).strip()
            continue

        if not line.startswith("|") or "Skill Name" in line or "---" in line:
            continue

        parts = [part.strip() for part in line.strip("|").split("|")]
        if len(parts) != 6:
            continue

        name, skill_type, description, initial, per_level, max_value = parts
        display_name = name.replace("**", "").strip()
        normalized_type = skill_type.replace("**", "").strip()
        if normalized_type == "Special" and pending_special_name:
            display_name = pending_special_name

        if normalized_type not in SKILL_TYPE_ENUM:
            continue

        rows.append(
            SkillRow(
                main_class=current_main,
                tree_key=current_tree,
                name=display_name,
                skill_type=normalized_type,
                description=description.replace("**", "").strip(),
                initial=initial.replace("**", "").strip(),
                per_level=per_level.replace("**", "").strip(),
                max_value=max_value.replace("**", "").strip(),
            )
        )

    return rows


def write_skill_resources(rows: list[SkillRow]) -> None:
    for row in rows:
        row.resource_dir.mkdir(parents=True, exist_ok=True)
        resource_path = row.resource_dir / row.resource_name
        resource_path.write_text(build_resource_text(row), encoding="utf-8")


def build_resource_text(row: SkillRow) -> str:
    desc = escape_godot_string(
        f"{row.description}\nInitial: {row.initial}\nPer level: {row.per_level}\nMax: {row.max_value}"
    )
    value = escape_godot_string(row.per_level)
    return (
        '[gd_resource type="Resource" script_class="SkillDefinition" load_steps=2 format=3]\n\n'
        '[ext_resource type="Script" path="res://scripts/resources/skill_definition.gd" id="1_skilldef"]\n\n'
        "[resource]\n"
        'script = ExtResource("1_skilldef")\n'
        f'skill_id = "{row.skill_id}"\n'
        f'display_name = "{escape_godot_string(row.name)}"\n'
        f"skill_type = {SKILL_TYPE_ENUM[row.skill_type]}\n"
        "max_level = 5\n"
        "sp_cost_per_level = 1\n"
        f'description_template = "{desc}"\n'
        f'value_per_level = "{value}"\n'
    )


def build_runtime_data(rows: list[SkillRow]) -> str:
    cooldowns: dict[str, float] = {}
    for row in rows:
        if row.skill_type not in {"Ability", "Special"}:
            continue
        cooldown = extract_cooldown(row.description)
        if cooldown is not None:
            cooldowns[row.skill_id] = cooldown

    lines = [
        "extends RefCounted",
        "class_name SkillTreeRuntimeData",
        "",
        "const STAT_RULES := {",
    ]
    for key in sorted(STAT_RULES):
        lines.append(f'\t"{key}": {to_gd_value(STAT_RULES[key])},')
    lines.append("}")
    lines.append("")
    lines.append("const PASSIVE_RULES := {")
    for key in sorted(PASSIVE_RULES):
        lines.append(f'\t"{key}": {to_gd_value(PASSIVE_RULES[key])},')
    lines.append("}")
    lines.append("")
    lines.append("const ABILITY_COOLDOWNS := {")
    for key in sorted(cooldowns):
        lines.append(f'\t"{key}": {cooldowns[key]},')
    lines.append("}")
    lines.append("")
    return "\n".join(lines)


def extract_cooldown(description: str) -> float | None:
    match = re.search(r"(\d+(?:\.\d+)?)s\s*CD", description, re.IGNORECASE)
    if match:
        return float(match.group(1))
    match = re.search(r"(\d+(?:\.\d+)?)s\s*cooldown", description, re.IGNORECASE)
    if match:
        return float(match.group(1))
    return None


def to_gd_value(value):
    if isinstance(value, str):
        return f'"{escape_godot_string(value)}"'
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, list):
        inner = ", ".join(to_gd_value(item) for item in value)
        return f"[{inner}]"
    if isinstance(value, dict):
        if not value:
            return "{}"
        parts = []
        for key, item in value.items():
            parts.append(f'"{escape_godot_string(str(key))}": {to_gd_value(item)}')
        return "{%s}" % ", ".join(parts)
    raise TypeError(f"Unsupported value: {value!r}")


def escape_godot_string(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")


def main() -> None:
    rows = parse_reference()
    write_skill_resources(rows)
    RUNTIME_DATA_PATH.parent.mkdir(parents=True, exist_ok=True)
    RUNTIME_DATA_PATH.write_text(build_runtime_data(rows), encoding="utf-8")
    print(f"Generated {len(rows)} skill resources.")


if __name__ == "__main__":
    main()
