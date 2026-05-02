-- Moon Server Migration (008)
-- Add attributes JSONB to class_configs for per-level and max scaling values

ALTER TABLE class_configs
  ADD COLUMN IF NOT EXISTS attributes JSONB DEFAULT '{}';

-- Seed default scaling data for the tank class (proof of concept)
UPDATE class_configs SET attributes = '{
  "hp_max": 300,
  "atk_max": 50,
  "crit_max": 15.0,
  "crit_per_level": 0.5,
  "speed_per_level": 0.0,
  "speed_max": 60.0,
  "mana_per_level": 2,
  "mana_max": 100
}'::jsonb WHERE class_id = 'tank';
