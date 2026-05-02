-- Migration 009: Fix class data
-- 1) Zero mana for non-mana classes (they had DEFAULT 50)
-- 2) Re-seed class skills with full numeric triplet data (cooldown, value, extra per_lvl/max)
-- Source: docs/SkillTreeReference.md

-- ── Step 1: Zero mana for non-mana classes ───────────────────────────────────
UPDATE class_configs SET base_max_mana = 0 WHERE class_id IN (
  'tank','guardian','berserker',
  'dps','assassin','ranger','samurai',
  'support','bard','alchemist',
  'shadow_knight',
  'controller','warden'
);

-- ── Step 2: Re-seed skills with numeric data ─────────────────────────────────
-- Format: cooldown=init CD, value=init primary value
-- extra keys: value_per_lvl, value_max, <field>, <field>_per_lvl, <field>_max

-- TANK (main)
UPDATE class_configs SET skills = '[
  {"name":"Fortify","desc":"Gain 20% damage reduction, taunt 4m. 14s CD, 3s duration.",
   "cooldown":14,"value":0.20,"extra":{"value_per_lvl":0.05,"value_max":0.40,"radius":4,"radius_per_lvl":1,"radius_max":8,"duration":3,"duration_per_lvl":0.25,"duration_max":4}},
  {"name":"Fortification","desc":"Passive: Increase max HP by % per level.",
   "value":0.05,"extra":{"value_per_lvl":0.05,"value_max":0.25}},
  {"name":"Iron Skin","desc":"Passive: Increase armor rating by flat amount per level.",
   "value":3,"extra":{"value_per_lvl":3,"value_max":15}},
  {"name":"Taunt","desc":"Ability: Gain 50% damage reduction, taunt all enemies in 8m.",
   "cooldown":12,"value":0.50,"extra":{"duration":2,"duration_per_lvl":0.5,"duration_max":4,"radius":8,"radius_per_lvl":0,"radius_max":8}},
  {"name":"Unbreakable","desc":"Passive: While above 50% HP, reduce all incoming damage.",
   "value":0.02,"extra":{"value_per_lvl":0.02,"value_max":0.10}}
]' WHERE class_id = 'tank';

-- GUARDIAN
UPDATE class_configs SET skills = '[
  {"name":"Shield Wall","desc":"Special: -50% damage, taunt 3m. 15s CD, 2s duration.",
   "cooldown":15,"value":0.50,"extra":{"value_per_lvl":0.05,"value_max":0.70,"radius":3,"radius_per_lvl":0.5,"radius_max":5,"duration":2,"duration_per_lvl":0.5,"duration_max":4}},
  {"name":"Aegis Slam","desc":"Slam shield dealing 40-80 damage + knockback 3m.",
   "cooldown":12,"value":40,"extra":{"value_per_lvl":10,"value_max":80,"radius":3,"radius_per_lvl":0,"radius_max":3}},
  {"name":"Bulwark Cry","desc":"Force enemies in 6m to target you for 1.5-3s.",
   "cooldown":18,"value":1.5,"extra":{"value_per_lvl":0.4,"value_max":3,"radius":6,"radius_per_lvl":0,"radius_max":6}},
  {"name":"Stalwart","desc":"Passive: Increase block chance.",
   "value":0.02,"extra":{"value_per_lvl":0.02,"value_max":0.10}},
  {"name":"Ironclad","desc":"Passive: Increase armor penetration resistance.",
   "value":0.05,"extra":{"value_per_lvl":0.05,"value_max":0.25}},
  {"name":"Allied Ward","desc":"Passive: Each ally within 8m grants 1-5% damage reduction.",
   "value":0.01,"extra":{"value_per_lvl":0.01,"value_max":0.05,"radius":8,"radius_per_lvl":0,"radius_max":8}}
]' WHERE class_id = 'guardian';

-- BERSERKER
UPDATE class_configs SET skills = '[
  {"name":"Blood Rage","desc":"Special: +30% atk spd, +15% dmg, take 20% more dmg. 20s CD, 4s.",
   "cooldown":20,"value":0.30,"extra":{"value_per_lvl":0.05,"value_max":0.50,"dmg_bonus":0.15,"dmg_per_lvl":0.0375,"dmg_max":0.30,"duration":4,"duration_per_lvl":0.5,"duration_max":6}},
  {"name":"Frenzy","desc":"Ability: +30% atk spd, +15% dmg for 4s. Take 20% more damage.",
   "cooldown":20,"value":4,"extra":{"value_per_lvl":0.5,"value_max":6}},
  {"name":"Leap Smash","desc":"Ability: Leap to target. Deal 50-150 damage based on missing HP.",
   "cooldown":14,"value":50,"extra":{"value_per_lvl":25,"value_max":150}},
  {"name":"War Cry","desc":"Ability: Reduce enemy defense 10% in 8m for 2-4s.",
   "cooldown":18,"value":0.10,"extra":{"value_per_lvl":0.025,"value_max":0.20,"duration":2,"duration_per_lvl":0.5,"duration_max":4}},
  {"name":"Rage","desc":"Passive: Increase base attack damage.",
   "value":0.04,"extra":{"value_per_lvl":0.04,"value_max":0.20}},
  {"name":"Endurance","desc":"Passive: Increase HP regen per second.",
   "value":1,"extra":{"value_per_lvl":1,"value_max":5}}
]' WHERE class_id = 'berserker';

-- PALADIN
UPDATE class_configs SET skills = '[
  {"name":"Divine Shield","desc":"Special: Invulnerable 2s, heal 10% max HP. 25s CD, 40 MP.",
   "cooldown":25,"value":2,"extra":{"value_per_lvl":0.25,"value_max":3,"heal":0.10,"heal_per_lvl":0.025,"heal_max":0.20}},
  {"name":"Holy Strike","desc":"Ability: 30-60 holy damage + 20% slow for 1-2s. 8m range. 20 MP.",
   "cooldown":10,"value":30,"extra":{"value_per_lvl":7.5,"value_max":60,"slow_duration":1,"slow_duration_per_lvl":0.25,"slow_duration_max":2}},
  {"name":"Consecrate","desc":"Ability: Sanctify 4m ground 3-5s, 20-40 holy dmg/s. 30 MP.",
   "cooldown":16,"value":20,"extra":{"value_per_lvl":5,"value_max":40,"duration":3,"duration_per_lvl":0.5,"duration_max":5}},
  {"name":"Holy Might","desc":"Passive: Increase holy damage output.",
   "value":0.05,"extra":{"value_per_lvl":0.05,"value_max":0.25}},
  {"name":"Grace","desc":"Passive: Increase healing received.",
   "value":0.04,"extra":{"value_per_lvl":0.04,"value_max":0.20}},
  {"name":"Holy Light","desc":"Passive: Heal 1-5% of damage dealt. Kills grant +2-10 HP.",
   "value":0.01,"extra":{"value_per_lvl":0.01,"value_max":0.05,"kill_heal":2,"kill_heal_per_lvl":2,"kill_heal_max":10}}
]' WHERE class_id = 'paladin';

-- DPS (main)
UPDATE class_configs SET skills = '[
  {"name":"Burst Window","desc":"Special: +10% attack, +5% crit for 2s. 12s CD.",
   "cooldown":12,"value":0.10,"extra":{"value_per_lvl":0.05,"value_max":0.30,"crit_bonus":0.05,"crit_per_lvl":0.0375,"crit_max":0.20,"duration":2,"duration_per_lvl":0.5,"duration_max":4}},
  {"name":"Sharpen","desc":"Passive: Increase base attack damage.",
   "value":0.03,"extra":{"value_per_lvl":0.03,"value_max":0.15}},
  {"name":"Precision","desc":"Passive: Increase critical hit chance.",
   "value":0.02,"extra":{"value_per_lvl":0.02,"value_max":0.10}},
  {"name":"Surge","desc":"Ability: +10% atk spd, +5% crit for 4-8s. 30s CD.",
   "cooldown":30,"value":4,"extra":{"value_per_lvl":1,"value_max":8}},
  {"name":"Executioner","desc":"Passive: Deal +10-50% bonus damage to enemies below 50% HP.",
   "value":0.10,"extra":{"value_per_lvl":0.10,"value_max":0.50}}
]' WHERE class_id = 'dps';

-- SUPPORT (main)
UPDATE class_configs SET skills = '[
  {"name":"Field Aid","desc":"Special: Restore 20 HP over 3s, +10% defense. 16s CD.",
   "cooldown":16,"value":20,"extra":{"value_per_lvl":5,"value_max":40,"duration":3,"duration_per_lvl":0.5,"duration_max":5,"def_bonus":0.10,"def_per_lvl":0.025,"def_max":0.20}},
  {"name":"Mending","desc":"Passive: Increase heal power.",
   "value":0.04,"extra":{"value_per_lvl":0.04,"value_max":0.20}},
  {"name":"Resilience","desc":"Passive: Increase ally defense aura in 8m.",
   "value":0.03,"extra":{"value_per_lvl":0.03,"value_max":0.15,"radius":8,"radius_per_lvl":0,"radius_max":8}},
  {"name":"Revitalize","desc":"Ability: Restore 20-40 HP over 4s, +10-20% defense for 3s. 20s CD.",
   "cooldown":20,"value":20,"extra":{"value_per_lvl":5,"value_max":40,"duration":4,"duration_per_lvl":0,"duration_max":4}},
  {"name":"Steady Hands","desc":"Passive: Reduce healing CD 3-15%, improve regen 5-25%.",
   "value":0.03,"extra":{"value_per_lvl":0.03,"value_max":0.15}}
]' WHERE class_id = 'support';

-- HYBRID (main)
UPDATE class_configs SET skills = '[
  {"name":"Adaptive Stance","desc":"Special: +5% all stats for 3s. 13s CD, 20 MP.",
   "cooldown":13,"value":0.05,"extra":{"value_per_lvl":0.025,"value_max":0.15,"duration":3,"duration_per_lvl":0.5,"duration_max":5}},
  {"name":"Arcane Blade","desc":"Passive: Increase magic-infused melee damage.",
   "value":0.04,"extra":{"value_per_lvl":0.04,"value_max":0.20}},
  {"name":"Mystic Armor","desc":"Passive: +3 defense and spell resistance per level.",
   "value":3,"extra":{"value_per_lvl":3,"value_max":15}},
  {"name":"Elemental Strike","desc":"Ability: +10-50 elemental damage on melee. 12s CD, 15 MP.",
   "cooldown":12,"value":10,"extra":{"value_per_lvl":10,"value_max":50}},
  {"name":"Versatility","desc":"Passive: Spells 4-20% cheaper, melee restores 2-10 mana on hit.",
   "value":0.04,"extra":{"value_per_lvl":0.04,"value_max":0.20}}
]' WHERE class_id = 'hybrid';

-- CONTROLLER (main)
UPDATE class_configs SET skills = '[
  {"name":"Control Field","desc":"Special: 6m zone 10% slow, -5% enemy dmg, 3s. 14s CD.",
   "cooldown":14,"value":0.10,"extra":{"value_per_lvl":0.05,"value_max":0.30,"dmg_reduce":0.05,"dmg_reduce_per_lvl":0.025,"dmg_reduce_max":0.15,"duration":3,"duration_per_lvl":0.75,"duration_max":6,"radius":6,"radius_per_lvl":0,"radius_max":6}},
  {"name":"Command","desc":"Passive: Increase control effect duration.",
   "value":0.4,"extra":{"value_per_lvl":0.4,"value_max":2}},
  {"name":"Tactical Mind","desc":"Passive: Reduce control ability cooldowns.",
   "value":0.03,"extra":{"value_per_lvl":0.03,"value_max":0.15}},
  {"name":"Displace","desc":"Ability: Push or pull enemy 4-8m. 10m range. 12s CD.",
   "cooldown":12,"value":4,"extra":{"value_per_lvl":1,"value_max":8}},
  {"name":"Tempo Lock","desc":"Passive: Enemies in control zones deal 3-15% less damage.",
   "value":0.03,"extra":{"value_per_lvl":0.03,"value_max":0.15}}
]' WHERE class_id = 'controller';

-- ── SUBCLASSES ───────────────────────────────────────────────────────────────

-- GUARDIAN
UPDATE class_configs SET skills = '[
  {"name":"Shield Wall","desc":"Special: -50% damage, taunt 3m. 15s CD, 2s duration.",
   "cooldown":15,"value":0.50,"extra":{"value_per_lvl":0.05,"value_max":0.70,"radius":3,"radius_per_lvl":0.5,"radius_max":5,"duration":2,"duration_per_lvl":0.5,"duration_max":4}},
  {"name":"Aegis Slam","desc":"Ability: Slam shield: 40 damage + knockback 3m. Scales to 80 dmg.",
   "cooldown":12,"value":40,"extra":{"value_per_lvl":10,"value_max":80,"radius":3,"radius_per_lvl":0,"radius_max":3}},
  {"name":"Bulwark Cry","desc":"Ability: War cry forces enemies in 6m to target you for 1.5-3s.",
   "cooldown":18,"value":1.5,"extra":{"value_per_lvl":0.4,"value_max":3,"radius":6,"radius_per_lvl":0,"radius_max":6}},
  {"name":"Stalwart","desc":"Stat: Increase block chance percentage.",
   "value":0.02,"extra":{"value_per_lvl":0.02,"value_max":0.10}},
  {"name":"Ironclad","desc":"Stat: Increase armor penetration resistance percentage.",
   "value":0.05,"extra":{"value_per_lvl":0.05,"value_max":0.25}},
  {"name":"Allied Ward","desc":"Passive: Each ally within 8m grants 1-5% damage reduction.",
   "value":0.01,"extra":{"value_per_lvl":0.01,"value_max":0.05,"radius":8,"radius_per_lvl":0,"radius_max":8}}
]' WHERE class_id = 'guardian';

-- BERSERKER
UPDATE class_configs SET skills = '[
  {"name":"Blood Rage","desc":"Special: +30% atk spd, +15% dmg, take 20% more dmg. 20s CD, 4s.",
   "cooldown":20,"value":0.30,"extra":{"value_per_lvl":0.05,"value_max":0.50,"dmg_bonus":0.15,"dmg_per_lvl":0.0375,"dmg_max":0.30,"duration":4,"duration_per_lvl":0.5,"duration_max":6}},
  {"name":"Frenzy","desc":"Ability: +30% attack speed, +15% damage for 4s.",
   "cooldown":20,"value":4,"extra":{"value_per_lvl":0.5,"value_max":6}},
  {"name":"Leap Smash","desc":"Ability: Leap to target. Deal 50-150 damage based on missing HP.",
   "cooldown":14,"value":50,"extra":{"value_per_lvl":25,"value_max":150}},
  {"name":"War Cry","desc":"Ability: Roar reduces enemy defense by 10% for 2s in 8m.",
   "cooldown":18,"value":0.10,"extra":{"value_per_lvl":0.025,"value_max":0.20,"duration":2,"duration_per_lvl":0.5,"duration_max":4}},
  {"name":"Rage","desc":"Stat: Increase base attack damage percentage.",
   "value":0.04,"extra":{"value_per_lvl":0.04,"value_max":0.20}},
  {"name":"Endurance","desc":"Stat: Increase HP regeneration per second.",
   "value":1,"extra":{"value_per_lvl":1,"value_max":5}}
]' WHERE class_id = 'berserker';

-- ASSASSIN
UPDATE class_configs SET skills = '[
  {"name":"Shadow Step","desc":"Special: Teleport, +60% crit next hit. 8s CD.",
   "cooldown":8,"value":0.60,"extra":{"value_per_lvl":0.10,"value_max":1.0,"duration":1,"duration_per_lvl":0.25,"duration_max":2}},
  {"name":"Shadow Teleport","desc":"Ability: Teleport behind enemy within 10m. Next attack 60-100% crit.",
   "cooldown":12,"value":0.60,"extra":{"value_per_lvl":0.10,"value_max":1.0,"range":10,"range_per_lvl":0,"range_max":10}},
  {"name":"Smoke Bomb","desc":"Ability: Blind enemies in 5m for 1-3s, invisibility for same duration.",
   "cooldown":20,"value":1,"extra":{"value_per_lvl":0.5,"value_max":3,"radius":5,"radius_per_lvl":0,"radius_max":5}},
  {"name":"Blade Storm","desc":"Ability: Spin for 2s, striking all enemies within 4m for 40-120 damage.",
   "cooldown":15,"value":40,"extra":{"value_per_lvl":20,"value_max":120,"radius":4,"radius_per_lvl":0,"radius_max":4}},
  {"name":"Lethal Edge","desc":"Stat: Increase critical damage multiplier percentage.",
   "value":0.10,"extra":{"value_per_lvl":0.10,"value_max":0.50}},
  {"name":"Evasion","desc":"Stat: Increase dodge chance percentage.",
   "value":0.02,"extra":{"value_per_lvl":0.02,"value_max":0.10}}
]' WHERE class_id = 'assassin';

-- RANGER
UPDATE class_configs SET skills = '[
  {"name":"Trap Network","desc":"Special: Place 1 trap: 30 dmg + 1s slow. 12s CD.",
   "cooldown":12,"value":1,"extra":{"value_per_lvl":0.5,"value_max":3,"damage":30,"damage_per_lvl":5,"damage_max":50,"slow":1,"slow_per_lvl":0.5,"slow_max":3}},
  {"name":"Trap Master","desc":"Ability: Place 1-3 traps: 30-50 damage + 1-3s slow. 15s CD.",
   "cooldown":15,"value":1,"extra":{"value_per_lvl":0.5,"value_max":3,"damage":30,"damage_per_lvl":5,"damage_max":50}},
  {"name":"Volley","desc":"Ability: Fire 3-7 arrows in 60 cone, each 15-25 damage. 8s CD.",
   "cooldown":8,"value":3,"extra":{"value_per_lvl":1,"value_max":7,"damage":15,"damage_per_lvl":2.5,"damage_max":25}},
  {"name":"Hawk Strike","desc":"Ability: Summon hawk within 15m. 60-100 dmg + 0.5-1.5s stun.",
   "cooldown":14,"value":60,"extra":{"value_per_lvl":10,"value_max":100,"stun":0.5,"stun_per_lvl":0.25,"stun_max":1.5}},
  {"name":"Hawk Eye","desc":"Stat: Increase attack range percentage.",
   "value":0.05,"extra":{"value_per_lvl":0.05,"value_max":0.25}},
  {"name":"Swift Shot","desc":"Stat: Increase attack speed percentage.",
   "value":0.03,"extra":{"value_per_lvl":0.03,"value_max":0.15}}
]' WHERE class_id = 'ranger';

-- MAGE
UPDATE class_configs SET skills = '[
  {"name":"Meteor Storm","desc":"Special: 100 dmg over 2s in area. 20s CD, 50 MP.",
   "cooldown":20,"value":100,"extra":{"value_per_lvl":25,"value_max":200,"duration":2,"duration_per_lvl":0.25,"duration_max":3}},
  {"name":"Meteor Shower","desc":"Ability: Rain meteors in 8m area for 2-3s. 100-200 dmg. 25s CD, 60 MP.",
   "cooldown":25,"value":100,"extra":{"value_per_lvl":25,"value_max":200,"radius":8,"radius_per_lvl":0,"radius_max":8,"duration":2,"duration_per_lvl":0.25,"duration_max":3}},
  {"name":"Frost Nova","desc":"Ability: Freeze enemies in 5m for 1-2s. 40-80 ice dmg. 35 MP.",
   "cooldown":18,"value":40,"extra":{"value_per_lvl":10,"value_max":80,"radius":5,"radius_per_lvl":0,"radius_max":5,"freeze":1,"freeze_per_lvl":0.25,"freeze_max":2}},
  {"name":"Chain Lightning","desc":"Ability: Bolt chains to 2-4 enemies, 30-60 dmg each. 25 MP.",
   "cooldown":15,"value":2,"extra":{"value_per_lvl":0.5,"value_max":4,"damage":30,"damage_per_lvl":7.5,"damage_max":60}},
  {"name":"Arcane Surge","desc":"Stat: Increase spell damage percentage.",
   "value":0.05,"extra":{"value_per_lvl":0.05,"value_max":0.25}},
  {"name":"Focus","desc":"Stat: Increase mana pool by flat amount.",
   "value":10,"extra":{"value_per_lvl":10,"value_max":50}}
]' WHERE class_id = 'mage';

-- SAMURAI
UPDATE class_configs SET skills = '[
  {"name":"Iaijutsu","desc":"Special: Sheathe 1s, 1.5x dmg. 10s CD, 0.5s charge.",
   "cooldown":10,"value":1.5,"extra":{"value_per_lvl":0.375,"value_max":3.0,"charge":0.5,"charge_per_lvl":0.375,"charge_max":2.0}},
  {"name":"Quick-Draw Strike","desc":"Ability: Charge up to 2s. Piercing slash 1.5-3x damage.",
   "cooldown":12,"value":1.5,"extra":{"value_per_lvl":0.375,"value_max":3.0,"charge_max":2.0}},
  {"name":"Whirlwind Slash","desc":"Ability: Spin for 2s, hitting all in 4m for 50-90 dmg.",
   "cooldown":14,"value":50,"extra":{"value_per_lvl":10,"value_max":90,"radius":4,"radius_per_lvl":0,"radius_max":4}},
  {"name":"Death Mark","desc":"Ability: Mark enemy for 3-7s. Next hit 1.2-2x dmg, ignore defense.",
   "cooldown":20,"value":1.2,"extra":{"value_per_lvl":0.2,"value_max":2.0,"ignore":0.10,"ignore_per_lvl":0.10,"ignore_max":0.50,"duration":3,"duration_per_lvl":1,"duration_max":7}},
  {"name":"Blade Mastery","desc":"Stat: Increase physical damage percentage.",
   "value":0.04,"extra":{"value_per_lvl":0.04,"value_max":0.20}},
  {"name":"Composure","desc":"Stat: Increase critical hit resistance percentage.",
   "value":0.03,"extra":{"value_per_lvl":0.03,"value_max":0.15}}
]' WHERE class_id = 'samurai';

-- CLERIC
UPDATE class_configs SET skills = '[
  {"name":"Divine Blessing","desc":"Special: Holy zone: 25 HP/s, +10% defense, 3s. 18s CD, 45 MP.",
   "cooldown":18,"value":25,"extra":{"value_per_lvl":6.25,"value_max":50,"def_bonus":0.10,"def_per_lvl":0.025,"def_max":0.20,"duration":3,"duration_per_lvl":0.5,"duration_max":5}},
  {"name":"Holy Ground","desc":"Ability: 5m zone for 3-5s. Allies 30-50 HP/s + 10-20% defense. 45 MP.",
   "cooldown":25,"value":30,"extra":{"value_per_lvl":5,"value_max":50,"def_bonus":0.10,"def_per_lvl":0.025,"def_max":0.20,"duration":3,"duration_per_lvl":0.5,"duration_max":5,"radius":5}},
  {"name":"Resurrection Pulse","desc":"Ability: Restore 10-30 HP instantly to allies in 10m. 30s CD, 50 MP.",
   "cooldown":30,"value":10,"extra":{"value_per_lvl":5,"value_max":30,"radius":10}},
  {"name":"Shield of Faith","desc":"Ability: Absorbing next 1-2 hits. Lasts 5-15s. 20s CD, 30 MP.",
   "cooldown":20,"value":1,"extra":{"value_per_lvl":0.25,"value_max":2,"duration":5,"duration_per_lvl":2.5,"duration_max":15}},
  {"name":"Sanctify","desc":"Stat: Increase holy healing output percentage.",
   "value":0.05,"extra":{"value_per_lvl":0.05,"value_max":0.25}},
  {"name":"Devotion","desc":"Stat: Increase buff duration by seconds.",
   "value":1,"extra":{"value_per_lvl":1,"value_max":5}}
]' WHERE class_id = 'cleric';

-- CHRONOMANCER
UPDATE class_configs SET skills = '[
  {"name":"Time Fracture","desc":"Special: 20% slow, +10% haste exit, 2.5s. 16s CD, 35 MP.",
   "cooldown":16,"value":0.20,"extra":{"value_per_lvl":0.05,"value_max":0.40,"haste":0.10,"haste_per_lvl":0.05,"haste_max":0.30,"duration":2.5,"duration_per_lvl":0.5,"duration_max":4.5}},
  {"name":"Slow Field","desc":"Ability: 6m zone slowing enemies by 20-40% for 3-5s. 20s CD, 30 MP.",
   "cooldown":20,"value":0.20,"extra":{"value_per_lvl":0.05,"value_max":0.40,"duration":3,"duration_per_lvl":0.5,"duration_max":5,"radius":6}},
  {"name":"Time Freeze","desc":"Ability: Freeze single target for 0.5-2s. 25s CD, 40 MP.",
   "cooldown":25,"value":0.5,"extra":{"value_per_lvl":0.375,"value_max":2.0}},
  {"name":"Rewind","desc":"Ability: Rewind position to 1-3s ago, reset damage. 35s CD, 50 MP.",
   "cooldown":35,"value":1,"extra":{"value_per_lvl":0.5,"value_max":3}},
  {"name":"Time Warp","desc":"Stat: Increase speed by % after control abilities.",
   "value":0.03,"extra":{"value_per_lvl":0.03,"value_max":0.15}},
  {"name":"Decay","desc":"Stat: Enemies in slow fields take 5-25 DOT.",
   "value":5,"extra":{"value_per_lvl":5,"value_max":25}}
]' WHERE class_id = 'chronomancer';
