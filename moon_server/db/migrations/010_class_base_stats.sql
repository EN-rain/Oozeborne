-- Migration 010: Apply documented innate base stats and attributes to all classes
-- Source: docs/SkillTreeReference.md

-- TANK
UPDATE class_configs SET 
base_max_health = 125, base_speed = 57.0, base_attack_damage = 10, base_crit_chance = 7.0,
attributes = '{"defense": 25, "atk_speed": -5, "crit_dmg": 5}'::jsonb WHERE class_id = 'tank';

UPDATE class_configs SET 
base_max_health = 115, base_speed = 54.0, base_attack_damage = 9, base_crit_chance = 5.0,
attributes = '{"defense": 20, "atk_speed": -5}'::jsonb WHERE class_id = 'guardian';

UPDATE class_configs SET 
base_max_health = 120, base_speed = 63.0, base_attack_damage = 12, base_crit_chance = 10.0,
attributes = '{"defense": -15}'::jsonb WHERE class_id = 'berserker';

UPDATE class_configs SET 
base_max_health = 115, base_speed = 57.0, base_attack_damage = 11, base_crit_chance = 5.0,
attributes = '{"defense": 15, "heal_recv": 10}'::jsonb WHERE class_id = 'paladin';

-- DPS
UPDATE class_configs SET 
base_max_health = 90, base_speed = 66.0, base_attack_damage = 12, base_crit_chance = 10.0,
attributes = '{"defense": -10, "crit_dmg": 10}'::jsonb WHERE class_id = 'dps';

UPDATE class_configs SET 
base_max_health = 85, base_speed = 69.0, base_attack_damage = 13, base_crit_chance = 15.0,
attributes = '{"defense": -10, "crit_dmg": 15, "dodge": 10}'::jsonb WHERE class_id = 'assassin';

UPDATE class_configs SET 
base_max_health = 90, base_speed = 66.0, base_attack_damage = 12, base_crit_chance = 10.0,
attributes = '{"defense": -5, "atk_speed": 10}'::jsonb WHERE class_id = 'ranger';

UPDATE class_configs SET 
base_max_health = 95, base_speed = 66.0, base_attack_damage = 12, base_crit_chance = 10.0,
attributes = '{"defense": -5, "crit_dmg": 15}'::jsonb WHERE class_id = 'samurai';

-- MAGE
UPDATE class_configs SET 
base_max_health = 80, base_speed = 63.0, base_attack_damage = 9, base_crit_chance = 5.0, base_max_mana = 75,
attributes = '{"defense": -15, "spell_dmg": 25}'::jsonb WHERE class_id = 'mage';

UPDATE class_configs SET 
base_max_health = 90, base_speed = 60.0, base_attack_damage = 9, base_crit_chance = 5.0, base_max_mana = 65,
attributes = '{"defense": -5, "minion_stat": 20}'::jsonb WHERE class_id = 'necromancer';

-- SUPPORT
UPDATE class_configs SET 
base_max_health = 110, base_speed = 63.0, base_attack_damage = 9, base_crit_chance = 5.0, base_max_mana = 62,
attributes = '{"defense": 5, "heal_power": 10}'::jsonb WHERE class_id = 'support';

UPDATE class_configs SET 
base_max_health = 105, base_speed = 60.0, base_attack_damage = 8, base_crit_chance = 5.0, base_max_mana = 60,
attributes = '{"defense": 10, "heal_power": 20}'::jsonb WHERE class_id = 'cleric';

UPDATE class_configs SET 
base_max_health = 100, base_speed = 66.0, base_attack_damage = 9, base_crit_chance = 5.0, base_max_mana = 57,
attributes = '{"defense": 0, "aura_str": 10}'::jsonb WHERE class_id = 'bard';

UPDATE class_configs SET 
base_max_health = 105, base_speed = 63.0, base_attack_damage = 9, base_crit_chance = 5.0, base_max_mana = 55,
attributes = '{"defense": 5, "potion_eff": 15}'::jsonb WHERE class_id = 'alchemist';

-- HYBRID
UPDATE class_configs SET 
base_max_health = 105, base_speed = 63.0, base_attack_damage = 11, base_crit_chance = 7.0, base_max_mana = 55,
attributes = '{"defense": 5}'::jsonb WHERE class_id = 'hybrid';

UPDATE class_configs SET 
base_max_health = 100, base_speed = 66.0, base_attack_damage = 12, base_crit_chance = 5.0, base_max_mana = 57,
attributes = '{"defense": 0, "spell_dmg": 10}'::jsonb WHERE class_id = 'spellblade';

UPDATE class_configs SET 
base_max_health = 110, base_speed = 63.0, base_attack_damage = 11, base_crit_chance = 5.0, base_max_mana = 50,
attributes = '{"defense": 10, "lifesteal": 5}'::jsonb WHERE class_id = 'shadow_knight';

UPDATE class_configs SET 
base_max_health = 105, base_speed = 69.0, base_attack_damage = 10, base_crit_chance = 5.0, base_max_mana = 50,
attributes = '{"defense": -5, "dodge": 15, "atk_speed": 10}'::jsonb WHERE class_id = 'monk';

-- CONTROLLER
UPDATE class_configs SET 
base_max_health = 100, base_speed = 60.0, base_attack_damage = 8, base_crit_chance = 5.0, base_max_mana = 62,
attributes = '{"defense": 10, "cc_dur": 15}'::jsonb WHERE class_id = 'controller';

UPDATE class_configs SET 
base_max_health = 90, base_speed = 69.0, base_attack_damage = 9, base_crit_chance = 5.0, base_max_mana = 60,
attributes = '{"defense": -5, "cd_red": 10}'::jsonb WHERE class_id = 'chronomancer';

UPDATE class_configs SET 
base_max_health = 115, base_speed = 57.0, base_attack_damage = 9, base_crit_chance = 5.0, base_max_mana = 57,
attributes = '{"defense": 15, "pet_hp": 20}'::jsonb WHERE class_id = 'warden';

UPDATE class_configs SET 
base_max_health = 95, base_speed = 63.0, base_attack_damage = 9, base_crit_chance = 5.0, base_max_mana = 65,
attributes = '{"defense": -5, "curse_str": 15}'::jsonb WHERE class_id = 'hexbinder';

UPDATE class_configs SET 
base_max_health = 85, base_speed = 66.0, base_attack_damage = 10, base_crit_chance = 5.0, base_max_mana = 70,
attributes = '{"defense": -10, "lightning_dmg": 20}'::jsonb WHERE class_id = 'stormcaller';
