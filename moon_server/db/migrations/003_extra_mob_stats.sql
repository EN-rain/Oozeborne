-- Refactor Mob Configs to use a Hybrid Dynamic Schema (JSONB)
-- This allows for infinite expansion of mob mechanics without database migrations.

ALTER TABLE mob_configs 
ADD COLUMN IF NOT EXISTS attributes JSONB NOT NULL DEFAULT '{}';

-- Migrate any existing data (if the columns existed from my previous attempt)
-- This ensures we don't lose data if the user already ran the previous migration.
UPDATE mob_configs 
SET attributes = jsonb_build_object(
    'attack_speed', COALESCE(attack_speed, 1.0),
    'blink_cooldown', COALESCE(blink_cooldown, 3.0),
    'projectile_speed', COALESCE(projectile_speed, 200.0),
    'trailing_speed', COALESCE(trailing_speed, 0.4),
    'enrage_time', COALESCE(enrage_time, 300.0),
    'phase_2_threshold', COALESCE(phase_2_threshold, 0.6),
    'phase_3_threshold', COALESCE(phase_3_threshold, 0.3)
)
WHERE TRUE;

-- Now we can drop the rigid columns as they are now safely inside the JSONB 'attributes'
-- Note: We keep health, speed, damage, xp_reward, and gold_reward as fixed columns 
-- because they are core to EVERY mob and benefit from strict typing and indexing.
ALTER TABLE mob_configs 
DROP COLUMN IF EXISTS attack_speed,
DROP COLUMN IF EXISTS blink_cooldown,
DROP COLUMN IF EXISTS projectile_speed,
DROP COLUMN IF EXISTS trailing_speed,
DROP COLUMN IF EXISTS enrage_time,
DROP COLUMN IF EXISTS phase_2_threshold,
DROP COLUMN IF EXISTS phase_3_threshold;
