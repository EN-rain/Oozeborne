-- Moon Server Migration (004)
-- Adding Category and Skills to Mob Configs for parity with Class Configs and Game Server structs

ALTER TABLE mob_configs 
ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'common',
ADD COLUMN IF NOT EXISTS skills JSONB DEFAULT '[]';

-- Update existing mobs with their likely categories based on the UI groups
UPDATE mob_configs SET category = 'common' WHERE mob_type = 'slime';
UPDATE mob_configs SET category = 'elite' WHERE mob_type IN ('lancer', 'archer');
UPDATE mob_configs SET category = 'boss' WHERE mob_type = 'warden';
