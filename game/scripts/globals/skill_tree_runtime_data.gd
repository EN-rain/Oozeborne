extends RefCounted
class_name SkillTreeRuntimeData

var STAT_RULES := {
	"controller_chronomancer_decay_stat": {"kind": "meta_multi", "entries": [{"kind": "meta_flat", "target": "control_dot_bonus", "value": 5.0}, {"kind": "meta_flat", "target": "mana_regen", "value": 0.5}]},
	"controller_chronomancer_time_warp_stat": {"kind": "property_percent", "target": "speed", "value": 0.03},
	"controller_hexbinder_affliction_stat": {"kind": "meta_percent", "target": "curse_debuff_strength_bonus", "value": 0.03},
	"controller_hexbinder_dark_mark_stat": {"kind": "meta_multi", "entries": [{"kind": "meta_percent", "target": "curse_damage_bonus", "value": 0.04}, {"kind": "meta_flat", "target": "mana_regen", "value": 0.3}]},
	"controller_main_command_stat": {"kind": "meta_flat", "target": "control_duration_bonus", "value": 0.4},
	"controller_main_tactical_mind_stat": {"kind": "meta_percent", "target": "control_cooldown_reduction_bonus", "value": 0.03},
	"controller_stormcaller_surge_stat": {"kind": "meta_percent", "target": "knockback_and_stun_bonus", "value": 0.1},
	"controller_stormcaller_voltage_stat": {"kind": "meta_multi", "entries": [{"kind": "meta_percent", "target": "lightning_damage_bonus", "value": 0.05}, {"kind": "meta_flat", "target": "mana_regen", "value": 0.3}]},
	"controller_warden_entrapment_stat": {"kind": "meta_flat", "target": "root_duration_bonus", "value": 0.4},
	"controller_warden_fortification_stat": {"kind": "meta_percent", "target": "barrier_hp_bonus", "value": 0.1},
	"dps_assassin_evasion_stat": {"kind": "meta_percent", "target": "dodge_chance_bonus", "value": 0.02},
	"dps_assassin_lethal_edge_stat": {"kind": "meta_percent", "target": "crit_damage_bonus", "value": 0.1},
	"dps_mage_arcane_surge_stat": {"kind": "meta_percent", "target": "spell_damage_bonus", "value": 0.05},
	"dps_mage_focus_stat": {"kind": "meta_multi", "entries": [{"kind": "meta_flat", "target": "mana_bonus", "value": 10.0}, {"kind": "meta_flat", "target": "mana_regen", "value": 0.5}]},
	"dps_main_precision_stat": {"kind": "meta_percent", "target": "crit_chance_bonus", "value": 0.02},
	"dps_main_sharpen_stat": {"kind": "property_percent", "target": "attack_damage", "value": 0.03},
	"dps_ranger_hawk_eye_stat": {"kind": "meta_percent", "target": "attack_range_bonus", "value": 0.05},
	"dps_ranger_swift_shot_stat": {"kind": "meta_percent", "target": "attack_speed_bonus", "value": 0.03},
	"dps_samurai_blade_mastery_stat": {"kind": "meta_percent", "target": "physical_damage_bonus", "value": 0.04},
	"dps_samurai_composure_stat": {"kind": "meta_percent", "target": "crit_resistance_bonus", "value": 0.03},
	"hybrid_main_arcane_blade_stat": {"kind": "meta_multi", "entries": [{"kind": "meta_percent", "target": "magic_melee_damage_bonus", "value": 0.04}, {"kind": "meta_flat", "target": "mana_regen", "value": 0.3}]},
	"hybrid_main_mystic_armor_stat": {"kind": "meta_multi", "entries": [{"kind": "meta_flat", "target": "armor_flat_bonus", "value": 3.0}, {"kind": "meta_flat", "target": "spell_resistance_flat_bonus", "value": 3.0}]},
	"hybrid_monk_chi_flow_stat": {"kind": "meta_flat", "target": "mana_regen", "value": 2.0},
	"hybrid_monk_discipline_stat": {"kind": "meta_percent", "target": "combo_damage_bonus", "value": 0.03},
	"hybrid_shadow_knight_eclipse_stat": {"kind": "meta_percent", "target": "low_health_damage_bonus", "value": 0.04},
	"hybrid_shadow_knight_shadow_power_stat": {"kind": "meta_percent", "target": "dark_damage_bonus", "value": 0.05},
	"hybrid_spellblade_mana_blade_stat": {"kind": "meta_percent", "target": "magic_melee_damage_bonus", "value": 0.05},
	"hybrid_spellblade_resonance_stat": {"kind": "meta_multi", "entries": [{"kind": "meta_percent", "target": "spell_cooldown_reduction_bonus", "value": 0.02}, {"kind": "meta_flat", "target": "mana_regen", "value": 0.3}]},
	"support_alchemist_preparation_stat": {"kind": "meta_flat", "target": "ability_item_slots_bonus", "value": 0.2},
	"support_alchemist_toxicology_stat": {"kind": "meta_percent", "target": "poison_damage_bonus", "value": 0.05},
	"support_bard_inspiration_stat": {"kind": "meta_percent", "target": "buff_strength_bonus", "value": 0.03},
	"support_bard_rhythm_stat": {"kind": "property_percent", "target": "speed", "value": 0.04},
	"support_cleric_devotion_stat": {"kind": "meta_flat", "target": "buff_duration_bonus", "value": 1.0},
	"support_cleric_sanctify_stat": {"kind": "meta_multi", "entries": [{"kind": "meta_percent", "target": "holy_healing_bonus", "value": 0.05}, {"kind": "meta_flat", "target": "mana_regen", "value": 0.5}]},
	"support_main_mending_stat": {"kind": "meta_percent", "target": "healing_power_bonus", "value": 0.04},
	"support_main_resilience_stat": {"kind": "meta_multi", "entries": [{"kind": "meta_percent", "target": "ally_defense_aura_bonus", "value": 0.03}, {"kind": "property_flat", "target": "hp_regen", "value": 0.3}]},
	"support_necromancer_soul_reaping_stat": {"kind": "meta_multi", "entries": [{"kind": "meta_flat", "target": "max_summon_count_bonus", "value": 0.2}, {"kind": "meta_flat", "target": "mana_regen", "value": 0.3}]},
	"support_necromancer_undead_mastery_stat": {"kind": "meta_percent", "target": "minion_power_bonus", "value": 0.1},
	"tank_berserker_endurance_stat": {"kind": "property_flat", "target": "hp_regen", "value": 1.0},
	"tank_berserker_rage_stat": {"kind": "property_percent", "target": "attack_damage", "value": 0.04},
	"tank_guardian_ironclad_stat": {"kind": "meta_percent", "target": "armor_penetration_resistance_bonus", "value": 0.05},
	"tank_guardian_stalwart_stat": {"kind": "meta_multi", "entries": [{"kind": "meta_percent", "target": "block_chance_bonus", "value": 0.02}, {"kind": "property_flat", "target": "hp_regen", "value": 0.5}]},
	"tank_main_fortify_stat": {"kind": "property_percent", "target": "max_health", "value": 0.05},
	"tank_main_iron_skin_stat": {"kind": "meta_multi", "entries": [{"kind": "meta_flat", "target": "armor_flat_bonus", "value": 3.0}, {"kind": "property_flat", "target": "hp_regen", "value": 0.5}]},
	"tank_paladin_grace_stat": {"kind": "meta_multi", "entries": [{"kind": "meta_percent", "target": "healing_received_bonus", "value": 0.04}, {"kind": "meta_flat", "target": "mana_regen", "value": 0.3}]},
	"tank_paladin_holy_might_stat": {"kind": "meta_percent", "target": "holy_damage_bonus", "value": 0.05},
}

var PASSIVE_RULES := {
	"controller_chronomancer_borrowed_seconds_passive": {"target": "control_burst_cdr_bonus", "kind": "meta_percent", "value": 0.06},
	"controller_hexbinder_malice_chain_passive": {"target": "curse_spread_chance", "kind": "meta_percent", "value": 0.1},
	"controller_main_tempo_lock_passive": {"target": "control_zone_enemy_damage_reduction", "kind": "meta_percent", "value": 0.03},
	"controller_stormcaller_static_build_passive": {"target": "controlled_target_lightning_bonus", "kind": "meta_percent", "value": 0.01},
	"controller_warden_line_holder_passive": {"target": "zone_enemy_damage_reduction", "kind": "meta_percent", "value": 0.04},
	"dps_assassin_backstab_passive": {"target": "backstab_damage_bonus", "kind": "meta_percent", "value": 0.1},
	"dps_mage_mana_shield_passive": {"target": "mana_shield_conversion", "kind": "meta_percent", "value": 0.02},
	"dps_main_executioner_passive": {"target": "execute_damage_bonus", "kind": "meta_percent", "value": 0.1},
	"dps_ranger_hunters_mark_passive": {"target": "marked_damage_taken_bonus", "kind": "meta_percent", "value": 0.03},
	"dps_samurai_way_of_the_warrior_passive": {"target": "consecutive_hit_damage_bonus", "kind": "meta_percent", "value": 0.01},
	"hybrid_main_versatility_passive": {"target": "mana_cost_reduction", "kind": "meta_percent", "value": 0.04},
	"hybrid_monk_flow_state_passive": {"target": "dodge_trigger_attack_speed_bonus", "kind": "meta_percent", "value": 0.04},
	"hybrid_shadow_knight_vampiric_embrace_passive": {"target": "lifesteal_effectiveness_bonus", "kind": "meta_percent", "value": 0.1},
	"hybrid_spellblade_arcane_strike_passive": {"target": "fourth_hit_magic_bonus", "kind": "meta_percent", "value": 0.06},
	"support_alchemist_transmutation_passive": {"target": "consumable_effectiveness_bonus", "kind": "meta_percent", "value": 0.1},
	"support_bard_inspiring_presence_passive": {"target": "ally_damage_aura_bonus", "kind": "meta_percent", "value": 0.02},
	"support_cleric_healing_aura_passive": {"target": "healing_aura_regen", "kind": "meta_flat", "value": 0.4},
	"support_main_steady_hands_passive": {"target": "healing_cooldown_reduction", "kind": "meta_percent", "value": 0.03},
	"support_necromancer_soul_harvest_passive": {"target": "kill_heal_bonus", "kind": "meta_flat", "value": 2.0},
	"tank_berserker_adrenaline_passive": {"target": "missing_hp_damage_bonus", "kind": "meta_percent", "value": 0.1},
	"tank_guardian_allied_ward_passive": {"target": "allied_damage_reduction_per_ally", "kind": "meta_percent", "value": 0.01},
	"tank_main_unbreakable_passive": {"target": "damage_reduction_above_half_hp", "kind": "meta_percent", "value": 0.02},
	"tank_paladin_holy_light_passive": {"target": "damage_to_healing_ratio", "kind": "meta_percent", "value": 0.01},
}

var ABILITY_COOLDOWNS := {
	"controller_chronomancer_rewind_ability": 35.0,
	"controller_chronomancer_slow_field_ability": 20.0,
	"controller_chronomancer_time_fracture_special": 16.0,
	"controller_chronomancer_time_freeze_ability": 25.0,
	"controller_hexbinder_hex_bolt_ability": 12.0,
	"controller_hexbinder_severing_hex_special": 13.0,
	"controller_main_control_field_special": 14.0,
	"controller_main_displace_ability": 12.0,
	"controller_stormcaller_shockwave_ability": 16.0,
	"controller_stormcaller_tempest_pulse_special": 12.0,
	"controller_stormcaller_thunder_clap_ability": 18.0,
	"controller_warden_bastion_ring_special": 18.0,
	"controller_warden_vine_snare_ability": 15.0,
	"dps_assassin_shadow_step_special": 8.0,
	"dps_mage_meteor_shower_ability": 25.0,
	"dps_mage_meteor_storm_special": 20.0,
	"dps_main_burst_window_special": 12.0,
	"dps_main_surge_ability": 30.0,
	"dps_ranger_trap_master_ability": 15.0,
	"dps_ranger_trap_network_special": 12.0,
	"dps_ranger_volley_ability": 8.0,
	"dps_samurai_iaijutsu_special": 10.0,
	"hybrid_main_adaptive_stance_special": 13.0,
	"hybrid_main_elemental_strike_ability": 12.0,
	"hybrid_monk_flurry_ability": 10.0,
	"hybrid_monk_pressure_point_ability": 12.0,
	"hybrid_monk_seven_point_strike_special": 15.0,
	"hybrid_monk_wind_step_ability": 8.0,
	"hybrid_shadow_knight_dark_pact_special": 10.0,
	"hybrid_shadow_knight_shadow_burst_ability": 18.0,
	"hybrid_shadow_knight_soul_rend_ability": 15.0,
	"hybrid_shadow_knight_void_strike_ability": 12.0,
	"hybrid_spellblade_blade_burst_ability": 15.0,
	"hybrid_spellblade_elemental_infusion_special": 12.0,
	"hybrid_spellblade_spell_parry_ability": 10.0,
	"support_alchemist_acid_splash_ability": 15.0,
	"support_alchemist_healing_brew_ability": 10.0,
	"support_alchemist_healing_flask_ability": 12.0,
	"support_alchemist_plague_flask_special": 15.0,
	"support_bard_dissonance_ability": 18.0,
	"support_bard_symphony_of_war_special": 20.0,
	"support_cleric_divine_blessing_special": 18.0,
	"support_cleric_holy_ground_ability": 25.0,
	"support_cleric_resurrection_pulse_ability": 30.0,
	"support_cleric_shield_of_faith_ability": 20.0,
	"support_main_field_aid_special": 16.0,
	"support_main_revitalize_ability": 20.0,
	"support_necromancer_bone_spike_ability": 8.0,
	"support_necromancer_death_shroud_ability": 20.0,
	"support_necromancer_grave_swarm_special": 16.0,
	"tank_berserker_blood_rage_special": 20.0,
	"tank_guardian_shield_wall_special": 15.0,
	"tank_main_fortify_special": 14.0,
	"tank_paladin_divine_shield_special": 25.0,
}

var ABILITY_DURATIONS := {
	"tank_main_taunt_ability": 2.0,
	"tank_main_frenzy_ability": 4.0,
	"tank_main_fortify_special": 3.0,
	"tank_berserker_frenzy_ability": 4.0,
	"tank_guardian_shield_wall_special": 2.0,
	"dps_main_smoke_bomb_ability": 1.0,
	"dps_main_surge_ability": 4.0,
	"dps_assassin_smoke_bomb_ability": 1.0,
	"controller_main_bramble_wall_ability": 2.0,
	"controller_warden_bramble_wall_ability": 2.0,
}

static func update_from_server(classes_data: Array) -> void:
	for cls in classes_data:
		var class_id = cls.get("class_id", "")
		var skills = cls.get("skills", [])
		for skill in skills:
			var skill_name = skill.get("name", "").to_lower().replace(" ", "_")
			var internal_id = class_id + "_" + skill_name # basic mapping logic
			
			if skill.has("cooldown") and skill.cooldown > 0:
				# Just update any matching string loosely if exact ID is unknown
				for key in ABILITY_COOLDOWNS.keys():
					if skill_name in key:
						ABILITY_COOLDOWNS[key] = float(skill.cooldown)
						
			if skill.has("extra") and skill.extra != null:
				if skill.extra.has("duration"):
					for key in ABILITY_DURATIONS.keys():
						if skill_name in key:
							ABILITY_DURATIONS[key] = float(skill.extra.duration)
							
			if skill.has("value") and skill.value > 0:
				for key in STAT_RULES.keys():
					if skill_name in key and STAT_RULES[key].has("value"):
						STAT_RULES[key]["value"] = float(skill.value)
				for key in PASSIVE_RULES.keys():
					if skill_name in key and PASSIVE_RULES[key].has("value"):
						PASSIVE_RULES[key]["value"] = float(skill.value)

