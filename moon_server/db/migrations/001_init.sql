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
INSERT INTO mob_configs (mob_type, health, speed, damage, xp_reward) VALUES
    ('slime',    80,   55.0, 8,  3),
    ('skeleton', 120,  70.0, 15, 7),
    ('boss',     2000, 40.0, 40, 100)
ON CONFLICT DO NOTHING;

-- ── Seed Data: Default Wave Configs ───────────────────────────────────────────
INSERT INTO wave_configs (wave_num, mob_weights, mob_count_base, duration_sec) VALUES
    (1,  '{"slime": 100}',              8,  50),
    (2,  '{"slime": 80, "skeleton": 20}', 12, 55),
    (3,  '{"slime": 60, "skeleton": 40}', 16, 60),
    (5,  '{"slime": 40, "skeleton": 55, "boss": 5}', 20, 90),
    (10, '{"skeleton": 50, "boss": 50}', 25, 120)
ON CONFLICT DO NOTHING;
