-- Moon Server Migration (007)
-- Add numeric values (cooldown, value) to existing JSONB skills array for classes.

UPDATE class_configs SET skills = '[
    {"name": "Fortify", "desc": "Gain 20% damage reduction and taunt enemies in 4m. 14s CD, 3s duration.", "cooldown": 14.0, "value": 0.2, "extra": {"radius": 4.0, "duration": 3.0}},
    {"name": "Unbreakable", "desc": "Passive: While above 50% HP, reduce all incoming damage by 10%.", "value": 0.1, "extra": {"hp_threshold": 0.5}},
    {"name": "Shield Wall", "desc": "Raise shield for -30% damage taken for 2s, taunting all in 5m radius.", "cooldown": 15.0, "value": 0.3, "extra": {"radius": 5.0, "duration": 2.0}},
    {"name": "Leap Smash", "desc": "Leap to target location. Deal 50 damage on landing.", "cooldown": 10.0, "value": 50.0, "extra": {"radius": 3.0}},
    {"name": "Bulwark Cry", "desc": "War cry forces enemies in 6m to target you for 1.5s.", "cooldown": 12.0, "value": 1.5, "extra": {"radius": 6.0}},
    {"name": "Allied Ward", "desc": "Passive: Each ally within 8m grants 5% damage reduction.", "value": 0.05, "extra": {"radius": 8.0, "max_allies": 5}}
]' WHERE class_id = 'tank';

-- Just update tank as a proof of concept. The admin portal now supports full JSON editing.
