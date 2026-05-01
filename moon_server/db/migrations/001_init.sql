-- ─────────────────────────────────────────────────────────────────────────────
-- Moon Server — Initial Schema Migration (001)
-- Run automatically by Postgres on first docker compose up
-- ─────────────────────────────────────────────────────────────────────────────

-- Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── Players & Identity ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS players (
    user_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username    TEXT UNIQUE NOT NULL,
    email       TEXT UNIQUE,
    password_hash TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS profiles (
    user_id         UUID PRIMARY KEY REFERENCES players(user_id) ON DELETE CASCADE,
    display_name    TEXT NOT NULL,
    slime_variant   TEXT DEFAULT 'default',
    class_id        TEXT DEFAULT 'base',
    cosmetics       JSONB DEFAULT '{}',
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS progression (
    user_id     UUID PRIMARY KEY REFERENCES players(user_id) ON DELETE CASCADE,
    level       INT NOT NULL DEFAULT 1,
    xp          BIGINT NOT NULL DEFAULT 0,
    coins       BIGINT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS saves (
    save_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES players(user_id) ON DELETE CASCADE,
    version     INT NOT NULL DEFAULT 1,
    data        JSONB NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Roles & Bans ─────────────────────────────────────────────────────────────
-- role_level: 0=Player, 1=Moderator, 2=Admin, 3=SuperAdmin
CREATE TABLE IF NOT EXISTS user_roles (
    user_id     UUID PRIMARY KEY REFERENCES players(user_id) ON DELETE CASCADE,
    role_level  INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS bans (
    ban_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES players(user_id) ON DELETE CASCADE,
    reason      TEXT,
    banned_by   UUID REFERENCES players(user_id),
    expires_at  TIMESTAMPTZ,          -- NULL = permanent
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Social: Friends & Chat ────────────────────────────────────────────────────
-- status: 'pending' | 'accepted' | 'blocked'
CREATE TABLE IF NOT EXISTS friends (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_a      UUID NOT NULL REFERENCES players(user_id) ON DELETE CASCADE,
    user_b      UUID NOT NULL REFERENCES players(user_id) ON DELETE CASCADE,
    status      TEXT NOT NULL DEFAULT 'pending',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_a, user_b)
);

-- channel_type: 'global' | 'friend' | 'room'
CREATE TABLE IF NOT EXISTS chat_messages (
    message_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id       UUID NOT NULL REFERENCES players(user_id) ON DELETE CASCADE,
    recipient_id    UUID,              -- NULL for global/room channels
    channel_type    TEXT NOT NULL DEFAULT 'global',
    channel_id      TEXT,              -- room_code for room chat
    content         TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_chat_channel ON chat_messages(channel_type, channel_id, created_at DESC);

-- ── Game Config: Mobs & Waves ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS mob_configs (
    mob_type    TEXT PRIMARY KEY,
    health      INT NOT NULL DEFAULT 100,
    speed       FLOAT NOT NULL DEFAULT 60.0,
    damage      INT NOT NULL DEFAULT 10,
    xp_reward   INT NOT NULL DEFAULT 5,
    gold_reward INT NOT NULL DEFAULT 5,
    drop_rates  JSONB DEFAULT '{}',
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- wave_configs: cached at room creation to avoid mid-tick DB reads
CREATE TABLE IF NOT EXISTS wave_configs (
    wave_num        INT PRIMARY KEY,
    mob_weights     JSONB NOT NULL DEFAULT '{}',    -- {"slime": 70, "skeleton": 30}
    mob_count_base  INT NOT NULL DEFAULT 10,
    duration_sec    INT NOT NULL DEFAULT 60
);

-- ── Game Config: Items & Classes ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS item_configs (
    item_id         TEXT PRIMARY KEY,
    display_name    TEXT NOT NULL,
    description     TEXT,
    price           INT NOT NULL DEFAULT 0,
    stat_type       TEXT,               -- 'MAX_HP', 'ATTACK', 'SPEED', etc.
    stat_value      FLOAT,
    instant_heal    INT DEFAULT 0,
    duration        INT DEFAULT 0,      -- For temporary buffs
    category        TEXT NOT NULL DEFAULT 'consumables', -- 'consumables', 'upgrades', etc.
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS class_configs (
    class_id            TEXT PRIMARY KEY,
    base_max_health     INT NOT NULL DEFAULT 100,
    base_speed          FLOAT NOT NULL DEFAULT 60.0,
    base_attack_damage  INT NOT NULL DEFAULT 10,
    base_crit_chance    FLOAT NOT NULL DEFAULT 5.0,
    base_max_mana       INT NOT NULL DEFAULT 50,
    health_per_level    INT NOT NULL DEFAULT 10,
    damage_per_level    INT NOT NULL DEFAULT 2,
    skills              JSONB DEFAULT '[]', -- Array of skill objects
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Match History & Results ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS match_sessions (
    match_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_code       TEXT NOT NULL,
    seed            BIGINT NOT NULL,
    wave_reached    INT NOT NULL DEFAULT 0,
    player_count    INT NOT NULL DEFAULT 1,
    duration_sec    INT,
    started_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ended_at        TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS match_results (
    result_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id        UUID NOT NULL REFERENCES match_sessions(match_id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES players(user_id) ON DELETE CASCADE,
    kills           INT NOT NULL DEFAULT 0,
    dmg_dealt       BIGINT NOT NULL DEFAULT 0,
    coins_earned    INT NOT NULL DEFAULT 0,
    xp_earned       INT NOT NULL DEFAULT 0
);
CREATE INDEX idx_match_results_user ON match_results(user_id);
CREATE INDEX idx_match_results_match ON match_results(match_id);

-- ── Admin Audit Log ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS staff_logs (
    log_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id    UUID NOT NULL REFERENCES players(user_id) ON DELETE CASCADE,
    action_type TEXT NOT NULL,          -- 'ban', 'kick', 'role_change', 'mob_tune', etc.
    target_id   UUID,                   -- Target player or entity
    payload     JSONB DEFAULT '{}',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_staff_logs_admin ON staff_logs(admin_id, created_at DESC);

-- ── Seed Data: Default Mob Configs ────────────────────────────────────────────
INSERT INTO mob_configs (mob_type, health, speed, damage, xp_reward, gold_reward) VALUES
    ('slime',    80,   55.0, 8,  3,  2),
    ('lancer',   150,  80.0, 20, 10, 8),
    ('archer',   90,   75.0, 15, 8,  6),
    ('warden',   400,  50.0, 25, 30, 25)
ON CONFLICT DO NOTHING;

-- ── Seed Data: Default Wave Configs ───────────────────────────────────────────
INSERT INTO wave_configs (wave_num, mob_weights, mob_count_base, duration_sec) VALUES
    (1,  '{"slime": 100}',              8,  50),
    (2,  '{"slime": 100}',             12,  55),
    (3,  '{"slime": 70, "archer": 30}', 16,  60),
    (5,  '{"slime": 40, "lancer": 40, "warden": 20}', 20, 90),
    (10, '{"archer": 30, "lancer": 40, "warden": 30}', 25, 120)
ON CONFLICT DO NOTHING;

-- ── Seed Data: Default Item Configs ──────────────────────────────────────────
INSERT INTO item_configs (item_id, display_name, description, price, stat_type, stat_value, instant_heal, duration, category) VALUES
    ('health_potion_small', 'Health Potion', 'Restores health.', 8, NULL, NULL, 50, 0, 'consumables'),
    ('health_potion_large', 'Large Health Potion', 'Restores significant health.', 20, NULL, NULL, 100, 0, 'consumables'),
    ('shield_potion', 'Shield Potion', 'Temporary defense boost.', 25, 'DEFENSE', 50, 0, 30, 'consumables'),
    ('speed_potion', 'Speed Potion', 'Temporary speed boost.', 15, 'SPEED', 30, 0, 60, 'consumables'),
    ('max_hp_10', 'Max HP +10', 'Permanent HP increase.', 40, 'MAX_HP', 10, 0, 0, 'upgrades'),
    ('max_hp_25', 'Max HP +25', 'Permanent HP increase.', 85, 'MAX_HP', 25, 0, 0, 'upgrades'),
    ('attack_5', 'Attack +5', 'Permanent damage increase.', 50, 'ATTACK', 5, 0, 0, 'upgrades'),
    ('iron_sword', 'Iron Sword', 'Increases damage.', 65, 'ATTACK', 10, 0, 0, 'equipment'),
    ('swift_boots', 'Swift Boots', 'Increases speed.', 50, 'SPEED', 15, 0, 0, 'equipment'),
    ('revive_stone', 'Revive Stone', 'Auto-revive on death.', 180, NULL, NULL, 0, 0, 'special'),
    ('xp_tome', 'XP Tome', 'Instantly gain 50 XP.', 25, NULL, NULL, 0, 0, 'special')
ON CONFLICT DO NOTHING;

-- ── Seed Data: Default Class Configs ──────────────────────────────────────────
INSERT INTO class_configs (class_id, base_max_health, base_speed, base_attack_damage, base_crit_chance, base_max_mana, health_per_level, damage_per_level, skills) VALUES
    ('tank', 150, 50.0, 12, 5.0, 40, 20, 3, '[{"name": "Passive", "desc": "Reduced damage taken."}]'),
    ('dps',  90, 70.0, 20, 10.0, 60, 8, 5, '[{"name": "Passive", "desc": "Increased attack speed."}]'),
    ('support', 100, 60.0, 10, 5.0, 100, 10, 2, '[{"name": "Passive", "desc": "Aura of healing."}]'),
    ('base', 100, 60.0, 10, 5.0, 50, 10, 2, '[]')
ON CONFLICT DO NOTHING;
