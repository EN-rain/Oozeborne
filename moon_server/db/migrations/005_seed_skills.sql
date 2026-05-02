-- Moon Server Migration (005)
-- Seeds correct, code-accurate skills for all mobs and classes.
-- Data sourced directly from:
--   - Mob skills: game/scripts/entities/enemies/**/*.gd + boss_behavior_tree actions
--   - Class skills: game/resources/skills/**/*.tres (display_name + description_template)
-- Safe to re-run: uses UPDATE (mobs) and ON CONFLICT DO UPDATE (classes).

-- ── MOB SKILLS & ATTRIBUTES (sourced from GDScript code) ─────────────────────

-- Blue Slime (blue_slime.gd): contact damage, idle roaming. No special abilities.
UPDATE mob_configs SET
    category   = 'common',
    speed      = 60.0,
    attributes = '{}',
    skills     = '[
        {"name": "Contact Damage", "desc": "Deals damage on contact with a player. Has a 1-second cooldown between hits and applies knockback."}
    ]'
WHERE mob_type = 'slime';

-- Plagued Lancer (plagued_lancer.gd):
--   - @export var blink_cooldown: float = 3.0
--   - @export var teleport_distance: float = 10.0
--   - Initial teleport on player detection, then blink every 3s
--   - After blink: takes 30% more damage (vulnerability_duration = 3.0s)
UPDATE mob_configs SET
    category   = 'elite',
    speed      = 60.0,
    attributes = '{
        "blink_cooldown": 3.0,
        "teleport_distance": 10.0,
        "vulnerability_duration": 3.0,
        "idle_move_interval": 3.0
    }',
    skills     = '[
        {"name": "Blink Strike", "desc": "On detecting a player, the Lancer instantly teleports behind them. During chase, it blinks to the player every 3 seconds to deliver a melee strike."},
        {"name": "Post-Blink Vulnerability", "desc": "After each blink, the Lancer takes 30% increased damage for 3 seconds, shown by a particle effect. Time your attacks wisely."}
    ]'
WHERE mob_type = 'lancer';

-- Archer (archer.gd):
--   - @export var arrow_speed: float = 200.0
--   - @export var attack_distance: float = 150.0  (keeps range)
--   - @export var stop_distance: float = 120.0    (kites player)
--   - @export var attack_cooldown: float = 2.0
--   - Predictive shot: _predict_player_position() using velocity samples
UPDATE mob_configs SET
    category   = 'elite',
    speed      = 120.0,
    attributes = '{
        "arrow_speed": 200.0,
        "attack_distance": 150.0,
        "stop_distance": 120.0,
        "attack_cooldown": 2.0,
        "prediction_lookback": 3,
        "max_prediction_distance": 300.0
    }',
    skills     = '[
        {"name": "Predictive Shot", "desc": "Fires an arrow that leads the target, calculating the player s movement velocity over the last 3 frames to predict their future position. Harder to dodge at range."},
        {"name": "Kite Behavior", "desc": "Actively maintains distance: approaches if the player is too far, retreats if too close. Attacks on a 2-second cooldown from up to 150 units away."}
    ]'
WHERE mob_type = 'archer';

-- Void Warden (void_warden.gd + bt_action_*.gd boss actions):
--   Phase 1 (100%-60%): Shadow Strike (5s CD, 80 dmg), Void Pulse (8s CD, 40 dmg AoE 200r)
--   Phase 2 (60%-30%): + Dark Chains (12s CD, 3s root)
--   Phase 3 (<30%):    + Soul Drain  (15s CD, 60 dmg + 50% lifesteal)
--   base_health = 2000, speed: P1=35, P2=45, P3=55, enrage_time=300s
UPDATE mob_configs SET
    category   = 'boss',
    health     = 2000,
    speed      = 35.0,
    attributes = '{
        "phase_2_threshold": 0.6,
        "phase_3_threshold": 0.3,
        "enrage_time": 300.0,
        "shadow_strike_damage": 80,
        "shadow_strike_cooldown": 5.0,
        "void_pulse_damage": 40,
        "void_pulse_radius": 200.0,
        "void_pulse_cooldown": 8.0,
        "dark_chains_duration": 3.0,
        "dark_chains_cooldown": 12.0,
        "soul_drain_damage": 60,
        "soul_drain_heal_percent": 0.5,
        "soul_drain_cooldown": 15.0
    }',
    skills     = '[
        {"name": "Shadow Strike", "desc": "[Phase 1+] Teleports directly behind the player and strikes for 80 damage with 400 knockback. 5 second cooldown."},
        {"name": "Void Pulse", "desc": "[Phase 1+] Releases an AoE burst of void energy dealing 40 damage to all players within 200 units with knockback. 8 second cooldown."},
        {"name": "Dark Chains", "desc": "[Phase 2: <60% HP] Roots the player in place for 3 seconds, preventing all movement. 12 second cooldown. Unlocks when Warden enters Phase 2."},
        {"name": "Soul Drain", "desc": "[Phase 3: <30% HP] Drains life from the player for 60 damage while healing the Warden for 30 HP (50% of damage). 15 second cooldown. Speed also increases each phase."}
    ]'
WHERE mob_type = 'warden';

-- ── CLASS SKILLS (sourced from resources/skills/**/*.tres) ────────────────────

-- Main classes: only seeding their *special* and *passive* here as representative skills.
-- The full skill tree is in the .tres files. This gives the portal readable info.

UPDATE class_configs SET skills = '[
    {"name": "Fortify", "desc": "Gain 20% damage reduction and taunt enemies in 4m. 14s CD, 3s duration. Scales to 40%/8m/4s."},
    {"name": "Unbreakable", "desc": "Passive: While above 50% HP, reduce all incoming damage by 2-10%."},
    {"name": "Shield Wall", "desc": "Raise shield for -30% damage taken for 2s, taunting all in 5m radius. Scales to -70%/4s."},
    {"name": "Leap Smash", "desc": "Leap to target location. Deal 50-150 damage on landing based on missing HP (1% HP = 1 dmg)."},
    {"name": "Bulwark Cry", "desc": "War cry forces enemies in 6m to target you for 1.5-3s."},
    {"name": "Allied Ward", "desc": "Passive: Each ally within 8m grants 1-5% damage reduction (max 5 allies)."}
]' WHERE class_id = 'tank';

UPDATE class_configs SET skills = '[
    {"name": "Shadow Step", "desc": "[Assassin] Teleport behind target enemy and deal bonus damage. 12s CD."},
    {"name": "Eagle Eye", "desc": "[Ranger] Passive: +40% attack range. Arrows pierce the first player hit."},
    {"name": "Meteor Shower", "desc": "[Mage] Rain meteors on an area dealing massive AoE damage."},
    {"name": "Iaido", "desc": "[Samurai] First attack from idle or after a roll deals 300% damage."},
    {"name": "Falcon Mark", "desc": "Critical hits mark enemies to take bonus team damage."},
    {"name": "Volley Step", "desc": "Attacking after a dodge fires an extra piercing arrow."}
]' WHERE class_id = 'dps';

UPDATE class_configs SET skills = '[
    {"name": "Field Aid", "desc": "Special: Restore HP to nearby allies in a pulse. 30s CD."},
    {"name": "Healing Aura", "desc": "Passive: Continuously radiates a weak healing aura to all nearby allies."},
    {"name": "Inspiring Presence", "desc": "Passive: Allies near you deal slightly more damage."},
    {"name": "Rallying Tune", "desc": "[Bard] Play a tune that boosts ally attack speed and movement speed."},
    {"name": "Grave Swarm", "desc": "[Necromancer] Release a swarm of undead spirits that deal AoE damage."},
    {"name": "Resurrection Pulse", "desc": "Revive all downed allies in an area at 50% HP. Long cooldown."}
]' WHERE class_id = 'support';

UPDATE class_configs SET skills = '[
    {"name": "Arcane Edge", "desc": "Melee attacks are infused with magic, dealing bonus arcane damage on hit."},
    {"name": "Spell Parry", "desc": "Passive: Timing a dodge against a ranged attack reduces its damage."},
    {"name": "Inner Fire", "desc": "[Monk] Channel ki to boost attack speed and movement speed by 25% for 6s."},
    {"name": "Life Drain", "desc": "[Shadow Knight] Passive: Melee attacks steal 10% of damage dealt as HP."},
    {"name": "Adaptive Combo", "desc": "Alternating mobility and offense grants stacking bonus damage output."},
    {"name": "Stance Echo", "desc": "Skill use alternates between defensive and offensive bonus aftereffects."}
]' WHERE class_id = 'hybrid';

UPDATE class_configs SET skills = '[
    {"name": "Control Field", "desc": "6m zone: 10% slow, -5% enemy dmg, 3s. 14s CD. Scales to 30%/-15%/6s."},
    {"name": "Tempo Lock", "desc": "Enemies within your control zones deal 3-15% less damage."},
    {"name": "Slow Field", "desc": "Create a 6m zone slowing enemies by 20-40% for 3-5s. 20s cooldown."},
    {"name": "Rewind", "desc": "[Chronomancer] Rewind your position to 1-3 seconds ago, resetting damage taken. 35s CD."},
    {"name": "Ring of Thorns", "desc": "[Warden] Summon ring (5m radius) lasting 3-5s. Roots crossing enemies, deals 15-40 dmg/s."},
    {"name": "Thunder Clap", "desc": "[Stormcaller] Slam ground sending shockwave in 6m radius, stunning for 0.3-1.5s. 18s CD."}
]' WHERE class_id = 'controller';

-- Subclasses
INSERT INTO class_configs (class_id, base_max_health, base_speed, base_attack_damage, base_crit_chance, base_max_mana, health_per_level, damage_per_level, skills) VALUES
    ('guardian', 160, 48.0, 13, 4.0, 40, 22, 2, '[
        {"name": "Shield Wall", "desc": "-50% damage taken, taunt 3m radius. 15s CD, 2s duration. Scales to -70%/5m/3s."},
        {"name": "Allied Ward", "desc": "Passive: Each ally within 8m grants 1-5% damage reduction."},
        {"name": "Aegis Slam", "desc": "Slam shield into ground dealing 40-80 damage with knockback in 3m radius."},
        {"name": "Bulwark Cry", "desc": "Force enemies in 6m to target you for 1.5-3s."},
        {"name": "Ironclad", "desc": "Passive: Increase armor penetration resistance by 5-25%."},
        {"name": "Stalwart", "desc": "Passive: Increase block chance by 2-10%."}
    ]'),
    ('berserker', 80, 75.0, 26, 12.0, 45, 6, 7, '[
        {"name": "Blood Rage", "desc": "+30% attack speed, +15% damage, take 20% more damage. 20s CD, 4s duration."},
        {"name": "Adrenaline", "desc": "Passive: Deal +10-50% more damage based on missing HP (max bonus at <20% HP). 5% lifesteal."},
        {"name": "Frenzy", "desc": "+30% attack speed, +15% damage for 4s. Take 20% more damage during effect."},
        {"name": "Leap Smash", "desc": "Leap to target location. Deal 50-150 damage on landing based on missing HP."},
        {"name": "War Cry", "desc": "Roar reduces enemy defense by 10-20% for 2-4s in 8m radius."},
        {"name": "Rage", "desc": "Passive: Increase base attack damage by 4-20%."}
    ]'),
    ('paladin', 140, 52.0, 14, 6.0, 65, 18, 3, '[
        {"name": "Divine Shield", "desc": "Become invulnerable for 2s, heal 10% max HP. 25s CD. Scales to 3s/20%."},
        {"name": "Holy Strike", "desc": "Smite enemy for 30-60 holy damage + 20% slow for 1-2s. Single target, 8m range."},
        {"name": "Consecrate", "desc": "Sanctify 4m radius ground for 3-5s, dealing 20-40 holy damage/s to enemies."},
        {"name": "Holy Light", "desc": "Passive: Heal for 1-5% of damage dealt. Killing enemies grants +2-10 HP."},
        {"name": "Holy Might", "desc": "Passive: Increase holy damage output by 5-25%."},
        {"name": "Grace", "desc": "Passive: Increase healing received by 4-20%."}
    ]'),
    ('assassin', 75, 80.0, 28, 18.0, 55, 5, 8, '[
        {"name": "Shadow Step", "desc": "Teleport behind nearest enemy within 10m and strike for 200% damage. 12s CD."},
        {"name": "Hemorrhage", "desc": "Critical hits apply a bleed dealing damage over 4s. Stacks up to 3 times."},
        {"name": "Vanish", "desc": "Enter stealth for 2-4s. First attack from stealth guarantees a critical hit."},
        {"name": "Marked Target", "desc": "Passive: Your first attack on any target deals 20-60% bonus damage."},
        {"name": "Precision", "desc": "Passive: Increase critical hit chance by 5-25%."},
        {"name": "Death Mark", "desc": "Special: Mark a target, causing all your attacks to deal +30% damage to them for 6s."}
    ]'),
    ('ranger', 85, 73.0, 19, 11.0, 60, 7, 5, '[
        {"name": "Trap Master", "desc": "Place a trap that roots enemies in 2m for 1.5-3s when triggered. 15s CD."},
        {"name": "Eagle Eye", "desc": "Passive: Attack range increased by 40%. Attacks pierce the first target hit."},
        {"name": "Rain of Arrows", "desc": "Special: Fire a barrage of arrows in target area dealing 20-60 dmg to all enemies hit."},
        {"name": "Wind Shot", "desc": "Passive: After a dodge, your next attack deals +20-60% bonus damage."},
        {"name": "Hunter Mark", "desc": "Mark a target taking +10-30% damage from all your attacks for 5s."},
        {"name": "Evasion", "desc": "Passive: Reduce cooldown of dodge by 0.5-2.5s."}
    ]'),
    ('mage', 70, 65.0, 32, 8.0, 120, 5, 9, '[
        {"name": "Meteor Shower", "desc": "Special: Rain meteors on a 5m area dealing 50-150 AoE damage. 20s CD."},
        {"name": "Arcane Burst", "desc": "Release arcane explosion at cursor dealing 40-80 damage in 4m radius. 10s CD."},
        {"name": "Mana Shield", "desc": "Passive: Convert 50% of incoming damage to mana cost instead of HP loss."},
        {"name": "Overload", "desc": "Passive: Every 5th spell deals +30-70% bonus damage."},
        {"name": "Arcane Mastery", "desc": "Passive: Increase all spell damage by 5-25%."},
        {"name": "Blink", "desc": "Instantly teleport 5m in movement direction. 8s CD."}
    ]'),
    ('samurai', 95, 72.0, 22, 15.0, 50, 8, 6, '[
        {"name": "Iaido", "desc": "Special: First attack from idle stance deals 300% damage. 15s CD."},
        {"name": "Seven-Point Strike", "desc": "5 rapid strikes dealing 15 dmg each, final hit crits + stuns for 0.5s. 15s CD."},
        {"name": "Wind Step", "desc": "Dash through an enemy within 6m dealing 20-60 damage and reset dodge cooldown. 8s CD."},
        {"name": "Pressure Point", "desc": "Strike vital spot stunning target for 0.5-1.5s and dealing 30-70 damage. 12s CD."},
        {"name": "Flurry", "desc": "Rapid 3-5 hit combo over 1.5s, final hit stuns for 0.5-1s. 10s CD."},
        {"name": "Precision Cut", "desc": "Passive: Every 5th attack is guaranteed to critically hit and ignore armor."}
    ]'),
    ('cleric', 110, 58.0, 9, 5.0, 110, 12, 1, '[
        {"name": "Field Aid", "desc": "Special: Restore HP to all allies in 6m radius. 30s CD."},
        {"name": "Healing Word", "desc": "Restore 30-80 HP to the lowest health ally. 8s CD."},
        {"name": "Shield of Faith", "desc": "Grant target ally a barrier absorbing 20-60 damage for 5s. 12s CD."},
        {"name": "Holy Ground", "desc": "Consecrate area healing allies for 10-25 HP/s for 4s. 16s CD."},
        {"name": "Steady Hands", "desc": "Passive: Increase all healing done by 5-25%."},
        {"name": "Devotion", "desc": "Passive: Increase ally defense by 3-15% while nearby."}
    ]'),
    ('bard', 100, 63.0, 11, 7.0, 90, 10, 2, '[
        {"name": "Battle Hymn", "desc": "Special: Play an anthem granting allies +15% attack speed and +10% movement for 10s. 25s CD."},
        {"name": "Dissonance", "desc": "Play a jarring note that silences enemies in 5m for 1-2.5s. 15s CD."},
        {"name": "Rallying Tune", "desc": "Boost ally morale: +8-20% damage for 5s in 8m radius. 12s CD."},
        {"name": "Healing Brew", "desc": "Toss a flask healing allies in 3m for 25-50 HP. 10s CD."},
        {"name": "Inspiration", "desc": "Passive: Allies near you have -5-25% reduced ability cooldowns."},
        {"name": "Rhythm", "desc": "Passive: Every 4th attack grants nearby allies +5-15% attack speed for 2s."}
    ]'),
    ('alchemist', 105, 61.0, 12, 6.0, 85, 10, 2, '[
        {"name": "Acid Splash", "desc": "Throw acid flask that deals 20-50 dmg/s for 3s in 3m area. 10s CD."},
        {"name": "Healing Flask", "desc": "Special: Throw healing potion restoring 50-100 HP to allies in 3m. 20s CD."},
        {"name": "Explosive Brew", "desc": "Lob bomb dealing 40-80 damage in 4m radius with knockback. 12s CD."},
        {"name": "Toxicology", "desc": "Passive: Your damage-over-time effects deal 5-25% more damage."},
        {"name": "Transmutation", "desc": "Passive: 10-30% chance to convert unused mana into HP at end of each wave."},
        {"name": "Preparation", "desc": "Passive: Start each wave with one random consumable effect active."}
    ]'),
    ('necromancer', 80, 60.0, 25, 7.0, 100, 6, 6, '[
        {"name": "Grave Swarm", "desc": "Special: Unleash swarm of undead spirits dealing 60-120 AoE damage. 20s CD."},
        {"name": "Summon Undead", "desc": "Raise fallen enemy as a skeleton ally lasting 15s. 10s CD."},
        {"name": "Death Shroud", "desc": "Wrap target in death energy dealing 15-40 dmg/s for 4s + applies slow. 12s CD."},
        {"name": "Bone Spike", "desc": "Launch bone spike dealing 30-70 damage and slowing target 20% for 2s. 8s CD."},
        {"name": "Soul Harvest", "desc": "Passive: Gain 5-20 mana on enemy kill. Killing while at full mana deals bonus AoE damage."},
        {"name": "Undead Mastery", "desc": "Passive: Skeletons you raise deal 10-50% more damage and last 5-20s longer."}
    ]'),
    ('spellblade', 105, 68.0, 20, 10.0, 75, 9, 5, '[
        {"name": "Arcane Edge", "desc": "Imbue weapon with magic for 6s. Attacks deal bonus arcane damage. 12s CD."},
        {"name": "Spell Parry", "desc": "Passive: Successfully dodging a projectile reflects 30-60% of its damage back."},
        {"name": "Magic Slash", "desc": "Melee attack that releases a wave of arcane energy, hitting through enemies. 8s CD."},
        {"name": "Runic Shield", "desc": "Barrier absorbing 40-100 damage. Shatters on break dealing 20-50 AoE damage. 18s CD."},
        {"name": "Mana Surge", "desc": "Passive: Every 5th melee attack releases an arcane burst dealing 20-50 bonus damage."},
        {"name": "Arcane Flow", "desc": "Passive: Melee kills restore 10-30 mana."}
    ]'),
    ('shadow_knight', 130, 58.0, 18, 8.0, 60, 16, 4, '[
        {"name": "Soul Rend", "desc": "Special: Drain life from all enemies in 4m for 40-80 damage, healing yourself for 50%. 20s CD."},
        {"name": "Unholy Strike", "desc": "Strike dealing 25-60 damage, applying a curse reducing target healing by 50% for 4s. 10s CD."},
        {"name": "Shroud of Darkness", "desc": "Surround area in darkness for 6s: allies gain +15% crit chance, enemies have -20% accuracy. 18s CD."},
        {"name": "Life Drain", "desc": "Passive: Melee attacks steal 10% of damage dealt as HP."},
        {"name": "Dark Pact", "desc": "Passive: Below 30% HP, gain 20-40% damage but take 10% more damage."},
        {"name": "Undying", "desc": "Passive: Once per wave, survive a killing blow with 1 HP."}
    ]'),
    ('monk', 105, 75.0, 16, 9.0, 70, 11, 3, '[
        {"name": "Inner Fire", "desc": "Channel ki: +25% attack speed and movement speed for 6s. 15s CD."},
        {"name": "Iron Body", "desc": "Become immune to crowd control effects for 4s. 20s CD."},
        {"name": "Flurry", "desc": "Rapid 3-5 hit combo over 1.5s, final hit stuns for 0.5-1s. 10s CD."},
        {"name": "Wind Step", "desc": "Dash through an enemy within 6m dealing 20-60 damage and resetting dodge. 8s CD."},
        {"name": "Pressure Point", "desc": "Strike vital spot stunning target for 0.5-1.5s and dealing 30-70 damage. 12s CD."},
        {"name": "Seven-Point Strike", "desc": "5 rapid strikes, 15 dmg each, final hit crits + stuns 0.5s. 15s CD."}
    ]'),
    ('chronomancer', 85, 62.0, 22, 9.0, 105, 7, 5, '[
        {"name": "Time Fracture", "desc": "Special: 20% slow enemies in area, +10% haste on exit, 2.5s. 16s CD. Scales to 40%/+30%/4.5s."},
        {"name": "Slow Field", "desc": "Create 6m zone slowing enemies by 20-40% for 3-5s. 20s CD."},
        {"name": "Time Freeze", "desc": "Freeze single target completely for 0.5-2s. 25s CD."},
        {"name": "Rewind", "desc": "Rewind your position to 1-3 seconds ago, resetting damage taken in that window. 35s CD."},
        {"name": "Borrowed Seconds", "desc": "Passive: Control effects apply 6-30% cooldown reduction burst."},
        {"name": "Decay", "desc": "Passive: Enemies in your slow fields take 5-25 damage/s."}
    ]'),
    ('warden', 120, 55.0, 14, 6.0, 60, 14, 3, '[
        {"name": "Bastion Ring", "desc": "Special: Summon ring for 3s: 10% slow, roots first target to cross. 18s CD."},
        {"name": "Ring of Thorns", "desc": "Summon ring (5m radius) lasting 3-5s. Roots crossing enemies, deals 15-40 dmg/s."},
        {"name": "Bramble Wall", "desc": "Erect thorn wall (6m wide, 2s duration) blocking movement, dealing 20-50 damage. 14s CD."},
        {"name": "Vine Snare", "desc": "Summon vines rooting all enemies in 4m radius for 0.5-2s. 15s CD."},
        {"name": "Entrapment", "desc": "Passive: Increase root/slow duration by 0.4-2s."},
        {"name": "Fortification", "desc": "Passive: Increase ring/barrier HP and duration by 10-50%."}
    ]'),
    ('hexbinder', 80, 60.0, 20, 8.0, 95, 6, 5, '[
        {"name": "Severing Hex", "desc": "Special: Cone curse: -5-20% enemy damage, +3-15% ability damage taken. 13s CD, 3-6s."},
        {"name": "Hex Bolt", "desc": "Fire projectile marking single target. Mark lasts 2-6s. 12s CD."},
        {"name": "Cursed Ground", "desc": "Corrupt 5m ground for 3-5s. Enemies have -10-30% all stats while standing in it."},
        {"name": "Hex Cone", "desc": "45-degree cone curse: enemies deal 5-20% less damage, take 5-15% more ability damage."},
        {"name": "Affliction", "desc": "Passive: Increase curse debuff strength by 3-15%."},
        {"name": "Malice Chain", "desc": "Passive: Defeated cursed enemies spread weaker curse within 4m (10-50% chance)."}
    ]'),
    ('stormcaller', 90, 66.0, 24, 10.0, 88, 7, 6, '[
        {"name": "Tempest Pulse", "desc": "Special: 30-80 dmg, knockback 2m, 1s slow to all in 5m radius. 12s CD."},
        {"name": "Thunder Clap", "desc": "Slam ground sending shockwave in 6m radius, stunning for 0.3-1.5s. 18s CD."},
        {"name": "Shockwave", "desc": "Chain of 2 shockwaves (8m range) dealing 20-60 damage + 10-30% slow for 1s. 16s CD."},
        {"name": "Static Field", "desc": "Charge self for 4-8s. Enemies within 4m take 5-20 damage when they hit you."},
        {"name": "Voltage", "desc": "Passive: Increase lightning damage dealt by 5-25%."},
        {"name": "Static Build", "desc": "Passive: Each consecutive hit on a controlled target adds +1-5% lightning damage, up to +25%."}
    ]')
ON CONFLICT (class_id) DO UPDATE SET
    skills = EXCLUDED.skills;
