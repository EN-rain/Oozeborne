-- Moon Server Migration (002)
-- Adding slots to the saves table for multiple cloud save support

ALTER TABLE saves ADD COLUMN IF NOT EXISTS slot INT NOT NULL DEFAULT 1;

-- Ensure each user can only have one save per slot
ALTER TABLE saves DROP CONSTRAINT IF EXISTS unique_user_slot;
ALTER TABLE saves ADD CONSTRAINT unique_user_slot UNIQUE (user_id, slot);
