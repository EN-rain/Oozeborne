-- Moon Server Migration (006)
-- Adding display_name to class_configs for parity with game server and player profiles

ALTER TABLE class_configs 
ADD COLUMN IF NOT EXISTS display_name TEXT;

-- Seed display names from class IDs if they are null
UPDATE class_configs SET display_name = INITCAP(REPLACE(class_id, '_', ' ')) WHERE display_name IS NULL;
