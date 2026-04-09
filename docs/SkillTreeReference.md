# Skill Tree System

> Game Design Reference Document  
> Version 1.0

---

## Table of Contents

- [System Overview](#system-overview)
- [Skill Point Economy](#skill-point-economy)
- [Skill Types](#skill-types)
- [Classes](#classes)
  - [Tank](#tank)
  - [DPS](#dps)
  - [Support](#support)
  - [Hybrid](#hybrid)
  - [Controller](#controller)
- [Quick Reference](#quick-reference)

---

## System Overview

Players earn Skill Points (SP) through leveling. SP is the primary resource for upgrading all skills across main class and subclass trees.

### Critical Strike Scaling

Critical stats use a shared baseline plus class bonuses so every build has some crit value without flattening role identity.

- **Level baseline crit rate:** 5% at Lv 1, +0.05% per level, 10% by Lv 100
- **Level baseline crit damage:** 110% at Lv 1, +0.1% per level, 120% by Lv 100
- **Main class crit modifiers:** apply their full bonus
- **Active subclass crit modifiers:** apply at 50% value

### Crit Formula

- **Final Crit Rate** = level baseline crit rate + main class crit rate bonus + 50% of active subclass crit rate bonus
- **Final Crit Damage** = level baseline crit damage + main class crit damage bonus + 50% of active subclass crit damage bonus

Balance target:

- Tank: low crit
- Support: light crit
- Hybrid / Controller: moderate crit
- DPS: strong crit
- Assassin / Samurai: highest burst crit payoff

### Progression Flow

1. **Pick a main class** (Tank, DPS, Support, Hybrid, or Controller)
2. **Invest SP into 4 main class skills** (stats, ability, passive) - each skill has 5 levels at 1 SP each
3. **After spending all 20 SP in the main class**, subclass trees unlock
4. **Subclasses can be freely invested into** - each caps at 30 SP (6 skills x 5 levels)
5. **Choose one active subclass** - you inherit that subclass's stat modifiers
6. **Skills from non-active subclasses can still be leveled and used** - you can slot skills from any subclass you've invested in
7. **Stat bonuses scale with SP investment** - the more SP in a skill, the stronger its effect
8. **Excess SP can be invested across multiple subclasses** - enabling hybrid builds with diverse skill options

---

## Skill Point Economy

| Rule | Details |
|------|---------|
| Max level | 100 |
| SP per level | 2 SP per level |
| Bonus SP | +5 SP at every 10th level (10, 20, 30 ... 100) |
| **Total SP at Lv 100** | **200 base + 50 bonus = 250 SP total** |
| Main class SP needed | 20 SP to fully max (4 skills x 5 levels x 1 SP) |
| Subclass SP cap | 30 SP per subclass (6 skills x 5 levels) |
| Subclass unlock condition | Main class must be fully maxed (all 20 SP spent) |
| SP cost per skill level | 1 SP for stats, abilities, and passives |
| Skills per class | 4 main + 6 per subclass |
| Skill max level | 5 levels each |
| **SP Distribution** | 250 SP allows full main class (20) + one subclass (30) + partial investment in other subclasses for hybrid builds |

---

## Skill Types

| Type | Description | Indicator |
|------|-------------|-----------|
| **Stat** | Passive numerical upgrades (HP, armor, damage, etc.) - auto-activated, no slot needed | Green |
| **Ability** | Active skill that must be slotted into the 4-skill action bar | Blue |
| **Passive** | Always-on effect once learned - auto-activated, no slot needed | Purple |

### Skill Slotting Rules

- **Basic Attack** - Always available, does not consume a slot
- **Stats** - Auto-activate when learned, no slot required
- **Passives** - Auto-activate when learned, no slot required
- **Abilities** - Must be slotted into the 4-slot action bar to use
- **Cross-Subclass Skills** - You can slot abilities from any subclass you've invested SP into, not just your active subclass
- **Special Abilities** - Treated as Abilities; consume one slot if slotted

---

# Classes

## Tank

### Overview

The Tank is one of five main classes. Players begin by investing Skill Points (SP) into the main class tree. All 20 SP must be spent before subclass trees unlock.

**Base Stats:** HP +25%, Speed -5%, Damage -5%, Defense +25%, Attack Speed -5%, Crit Chance +2%, Crit Damage +5%

**Stat Modifiers:**
| Stat | Modifier |
|------|----------|
| HP | +25% |
| Speed | -5% |
| Damage | -5% |
| Defense | +25% |
| Attack Speed | -5% |
| Crit Chance | +2% |
| Crit Damage | +5% |

**Special Ability — Fortify (14s CD):** Gain damage reduction and taunt nearby enemies briefly.

### Main Class Skills (20 SP Total)

| Skill Name | Type | Description | Initial | Per Level | Max |
|------------|------|-------------|---------|-----------|-----|
| **Fortify** | **Special** | **Gain 20% damage reduction, taunt 4m. 14s CD, 3s duration** | **20% / 4m / 3s** | **+5% / +1m / +0.25s** | **40% / 8m / 4s** |
| Fortification | Stat | Increase max HP by percentage per level | +5% HP | +5% HP | +25% HP |
| Iron Skin | Stat | Increase armor rating by flat amount per level | +3 Armor | +3 Armor | +15 Armor |
| Taunt | Ability | Gain 50% damage reduction for 2-6s, taunt all enemies in 8m radius | 2s duration | +0.5s | 4s duration |
| Unbreakable | Passive | While above 50% HP, reduce all incoming damage by 2-10% | 2% reduction | +2% | 10% reduction |

### Subclass: Guardian (30 SP Cap)

**Subclass Stats:** HP +35%, Speed -15%, Damage -10%, Defense +30%, Attack Speed -10%, 5 Thorns damage

**Stat Modifiers:**
| Stat | Modifier |
|------|----------|
| HP | +35% |
| Speed | -15% |
| Damage | -10% |
| Defense | +30% |
| Attack Speed | -10% |
| Thorns | 5 |

| Skill Name | Type | Description | Initial | Per Level | Max |
|------------|------|-------------|---------|-----------|-----|
| **Shield Wall** | **Special** | **-50% damage, taunt 3m. 15s CD, 2s duration** | **-50% / 3m / 2s** | **-5% / +0.5m / +0.5s** | **-70% / 5m / 4s** |
| Shield Wall | Ability | Raise shield: -30% damage for 2s, taunt 5m radius. Scales to -70%/4s | 30% / 2s | +10% / +0.5s | 70% / 4s |
| Aegis Slam | Ability | Slam shield into ground: 40 damage + knockback 3m radius. Scales to 80 damage | 40 damage | +10 damage | 80 damage |
| Bulwark Cry | Ability | War cry forces enemies in 6m to target you for 1.5-3s | 1.5s taunt | +0.4s | 3s taunt |
| Stalwart | Stat | Increase block chance percentage | +2% Block | +2% Block | +10% Block |
| Ironclad | Stat | Increase armor penetration resistance percentage | +5% Resistance | +5% Resistance | +25% Resistance |
| Allied Ward | Passive | Each ally within 8m grants 1-5% damage reduction (max 5 allies) | 1% per ally | +1% | 5% per ally (25% max) |

### Subclass: Berserker (30 SP Cap)

**Subclass Stats:** HP +18%, Speed -8%, Damage +26%, Defense -22%, Attack Speed +14%, 5% Lifesteal

**Stat Modifiers:**
| Stat | Modifier |
|------|----------|
| HP | +18% |
| Speed | -8% |
| Damage | +26% |
| Defense | -22% |
| Attack Speed | +14% |
| Lifesteal | 5% |

| Skill Name | Type | Description | Initial | Per Level | Max |
|------------|------|-------------|---------|-----------|-----|
| **Blood Rage** | **Special** | **+30% atk spd, +15% dmg, take 20% more dmg. 20s CD, 4s** | **+30% / +15% / 4s** | **+5% / +3.75% / +0.5s** | **+50% / +30% / 6s** |
| Frenzy | Ability | +30% attack speed, +15% damage for 4s. Take 20% more damage. Scales to +50%/+30%/6s | 4s duration | +0.5s | 6s duration |
| Leap Smash | Ability | Leap to target location. Deal 50-150 damage on landing based on missing HP (1% HP = 1 dmg) | 50 damage | +25 damage | 150 damage |
| War Cry | Ability | Roar reduces enemy defense by 10% for 2s in 8m radius. Scales to 20%/4s | 10% / 2s | +2.5% / +0.5s | 20% / 4s |
| Rage | Stat | Increase base attack damage percentage | +4% Damage | +4% Damage | +20% Damage |
| Endurance | Stat | Increase HP regeneration per second | +1 HP/s | +1 HP/s | +5 HP/s |
| Adrenaline | Passive | Deal +10-50% more damage based on missing HP (max bonus at <20% HP). 5% lifesteal. | +10% at 100% HP | +10% per 20% missing | +50% at <20% HP |

### Subclass: Paladin (30 SP Cap)

**Subclass Stats:** HP +22%, Speed -10%, Damage +5%, Defense +18%, Attack Speed -10%, 5% Lifesteal

**Stat Modifiers:**
| Stat | Modifier |
|------|----------|
| HP | +22% |
| Speed | -10% |
| Damage | +5% |
| Defense | +18% |
| Attack Speed | -10% |
| Lifesteal | 5% |

| Skill Name | Type | Description | Initial | Per Level | Max |
|------------|------|-------------|---------|-----------|-----|
| **Divine Shield** | **Special** | **Invulnerable 2s, heal 10% max HP. 25s CD** | **2s / 10% heal** | **+0.25s / +2.5%** | **3s / 20% heal** |
| Divine Aegis | Ability | Become invulnerable for 1.5s, heal 10% max HP. Scales to 3s/20% | 1.5s / 10% | +0.4s / +2.5% | 3s / 20% |
| Holy Strike | Ability | Smite enemy for 30-60 holy damage + 20% slow for 1-2s. Single target, 8m range | 30 dmg / 1s | +7.5 dmg / +0.25s | 60 dmg / 2s |
| Consecrate | Ability | Sanctify 4m radius ground for 3-5s, dealing 20-40 holy damage/s to enemies | 20 dmg/s / 3s | +5 dmg/s / +0.5s | 40 dmg/s / 5s |
| Holy Might | Stat | Increase holy damage output percentage | +5% Holy | +5% Holy | +25% Holy |
| Grace | Stat | Increase healing received percentage | +4% Healing | +4% Healing | +20% Healing |
| Holy Light | Passive | Heal for 1-5% of damage dealt. Killing enemies grants +2-10 HP. 5% lifesteal. | 1% / +2 HP | +1% / +2 HP | 5% / +10 HP |

---

## DPS

### Overview

The DPS is one of five main classes. Players begin by investing Skill Points (SP) into the main class tree. All 20 SP must be spent before subclass trees unlock.

**Base Stats:** HP -5%, Speed +8%, Damage +20%, Defense -10%, Attack Speed +10%, Crit Chance +8%, Crit Damage +10%

**Stat Modifiers:**
| Stat | Modifier |
|------|----------|
| HP | -5% |
| Speed | +8% |
| Damage | +20% |
| Defense | -10% |
| Attack Speed | +10% |
| Crit Chance | +8% |
| Crit Damage | +10% |

**Special Ability — Burst Window (12s CD):** Temporarily increase attack and crit output.

### Main Class Skills (20 SP Total)

| Skill Name | Type | Description | Initial | Per Level | Max |
|------------|------|-------------|---------|-----------|-----|
| **Burst Window** | **Special** | **+10% attack, +5% crit for 2s. 12s CD** | **+10% / +5% / 2s** | **+5% / +3.75% / +0.5s** | **+30% / +20% / 4s** |
| Sharpen | Stat | Increase base attack damage percentage | +3% Damage | +3% Damage | +15% Damage |
| Precision | Stat | Increase critical hit chance percentage | +2% Crit | +2% Crit | +10% Crit |
| Surge | Ability | Temporarily boost attack speed +10% and crit chance +5% for 4-8s. 30s cooldown | 4s duration | +1s | 8s duration |
| Executioner | Passive | Deal +10-50% bonus damage to enemies below 50% HP | +10% damage | +10% damage | +50% damage |

### Subclass: Assassin (30 SP Cap)

**Subclass Stats:** HP -18%, Speed +22%, Damage +28%, Defense -20%, Attack Speed +18%, Crit Chance +28%, Crit Damage +55%, 10% Dodge

**Stat Modifiers:**
| Stat | Modifier |
|------|----------|
| HP | -18% |
| Speed | +22% |
| Damage | +28% |
| Defense | -20% |
| Attack Speed | +18% |
| Crit Chance | +28% |
| Crit Damage | +55% |
| Dodge | 10% |

| Skill Name | Type | Description | Initial | Per Level | Max |
|------------|------|-------------|---------|-----------|-----|
| **Shadow Step** | **Special** | **Teleport, +60% crit next hit. 8s CD, 1s** | **TP / +60% crit / 1s** | **— / +10% crit / +0.25s** | **TP / 100% crit / 2s** |
| Shadow Teleport | Ability | Teleport behind nearest enemy within 10m. Next attack has 60-100% crit chance | 60% crit | +10% crit | 100% crit |
| Smoke Bomb | Ability | Throw bomb that blinds enemies in 5m for 1-3s, grants you invisibility for same duration | 1s blind/invis | +0.5s | 3s blind/invis |
| Blade Storm | Ability | Spin rapidly for 2s, striking all enemies within 4m for 40-120 damage total | 40 damage | +20 damage | 120 damage |
| Lethal Edge | Stat | Increase critical damage multiplier percentage | +10% Crit DMG | +10% Crit DMG | +50% Crit DMG |
| Evasion | Stat | Increase dodge chance percentage | +2% Dodge | +2% Dodge | +10% Dodge |
| Backstab | Passive | Attacks from behind deal +10-50% bonus damage and always critically strike. 10% dodge. | +10% / always crit | +10% damage | +50% / always crit |

### Subclass: Ranger (30 SP Cap)

**Subclass Stats:** HP -10%, Speed +20%, Damage +20%, Defense -10%, Attack Speed +15%, Crit Chance +10%, Crit Damage +15%

**Stat Modifiers:**
| Stat | Modifier |
|------|----------|
| HP | -10% |
| Speed | +20% |
| Damage | +20% |
| Defense | -10% |
| Attack Speed | +15% |
| Crit Chance | +10% |
| Crit Damage | +15% |

| Skill Name | Type | Description | Initial | Per Level | Max |
|------------|------|-------------|---------|-----------|-----|
| **Trap Network** | **Special** | **Place 1 trap: 30 dmg + 1s slow. 12s CD, 15s trap** | **1 trap / 30 dmg / 1s** | **+0.5 trap / +5 dmg / +0.5s** | **3 traps / 50 dmg / 3s** |
| Trap Master | Ability | Place 1-3 traps that deal 30-50 damage + 1-3s slow when triggered. 15s cooldown | 1 trap / 30 dmg | +0.5 trap / +5 dmg | 3 traps / 50 dmg |
| Volley | Ability | Fire 3-7 arrows in 60° cone, each dealing 15-25 damage. 8s cooldown | 3 arrows / 15 dmg | +1 arrow / +2.5 dmg | 7 arrows / 25 dmg |
| Hawk Strike | Ability | Summon hawk to dive at target within 15m. Deal 60-100 damage + 0.5-1.5s stun | 60 dmg / 0.5s | +10 dmg / +0.25s | 100 dmg / 1.5s |
| Hawk Eye | Stat | Increase attack range percentage | +5% Range | +5% Range | +25% Range |
| Swift Shot | Stat | Increase attack speed percentage | +3% Speed | +3% Speed | +15% Speed |
| Hunter's Mark | Passive | Mark enemies you hit for 3-7s. Marked enemies take +3-15% more damage. +15% XP. | 3s / +3% | +1s / +3% | 7s / +15% |

### Subclass: Mage (30 SP Cap)

**Subclass Stats:** HP -22%, Speed +10%, Damage +35%, Defense -18%, Attack Speed -5%, Crit Chance +6%, Crit Damage +20%

**Stat Modifiers:**
| Stat | Modifier |
|------|----------|
| HP | -22% |
| Speed | +10% |
| Damage | +35% |
| Defense | -18% |
| Attack Speed | -5% |
| Crit Chance | +6% |
| Crit Damage | +20% |

| Skill Name | Type | Description | Initial | Per Level | Max |
|------------|------|-------------|---------|-----------|-----|
| **Meteor Storm** | **Special** | **100 dmg over 2s in large area. 20s CD** | **100 dmg / 2s** | **+25 dmg / +0.25s** | **200 dmg / 3s** |
| Meteor Shower | Ability | Rain meteors in 8m radius for 2-3s. Total 100-200 damage split among targets. 25s CD | 100 dmg / 2s | +25 dmg / +0.25s | 200 dmg / 3s |
| Frost Nova | Ability | Explode freezing all enemies within 5m for 1-2s. Deal 40-80 ice damage | 40 dmg / 1s | +10 dmg / +0.25s | 80 dmg / 2s |
| Chain Lightning | Ability | Lightning bolt chains to 2-4 nearby enemies within 8m, dealing 30-60 damage each | 2 targets / 30 dmg | +0.5 target / +7.5 dmg | 4 targets / 60 dmg |
| Arcane Surge | Stat | Increase spell damage percentage | +5% Spell | +5% Spell | +25% Spell |
| Focus | Stat | Increase mana pool by flat amount | +10 MP | +10 MP | +50 MP |
| Mana Shield | Passive | Convert 2-10% of damage taken into mana shield that absorbs damage. 10 magic thorns. | 2% conversion | +2% conversion | 10% conversion |

### Subclass: Samurai (30 SP Cap)

**Subclass Stats:** HP -15%, Speed +15%, Damage +24%, Defense -15%, Attack Speed +20%, Crit Chance +8%, Crit Damage +40%

**Stat Modifiers:**
| Stat | Modifier |
|------|----------|
| HP | -15% |
| Speed | +15% |
| Damage | +24% |
| Defense | -15% |
| Attack Speed | +20% |
| Crit Chance | +8% |
| Crit Damage | +40% |

| Skill Name | Type | Description | Initial | Per Level | Max |
|------------|------|-------------|---------|-----------|-----|
| **Iaijutsu** | **Special** | **Sheathe 1s, 1.5x dmg. 10s CD, 0.5s charge** | **1.5x / 0.5s** | **+0.375x / +0.375s** | **3x / 2s** |
| Quick-Draw Strike | Ability | Charge up to 2s. Release piercing slash dealing 1.5-3x damage through all enemies in line | 1.5x damage | +0.375x | 3x damage |
| Whirlwind Slash | Ability | Spin for 2s with blade extended, hitting all enemies within 4m for 50-90 damage total | 50 damage | +10 damage | 90 damage |
| Death Mark | Ability | Mark enemy for 3-7s. Your next hit deals 1.2-2x damage and ignores 10-50% defense | 1.2x / 10% | +0.2x / +10% | 2x / 50% |
| Blade Mastery | Stat | Increase physical damage percentage | +4% Physical | +4% Physical | +20% Physical |
| Composure | Stat | Increase critical hit resistance percentage | +3% Resist | +3% Resist | +15% Resist |
| Way of the Warrior | Passive | Consecutive hits on same target add +1-5% damage per hit, stacking up to +5-25%. 5% dodge. | +1% per hit / +5% max | +1% per hit / +5% max | +5% per hit / +25% max |

---

## Support

### Overview

The Support is one of five main classes. Players begin by investing Skill Points (SP) into the main class tree. All 20 SP must be spent before subclass trees unlock.

**Base Stats:** HP +5%, Speed —, Damage -10%, Defense +5%, Attack Speed —

**Stat Modifiers:**
| Stat | Modifier |
|------|----------|
| HP | +5% |
| Speed | — |
| Damage | -10% |
| Defense | +5% |
| Attack Speed | — |

**Special Ability — Field Aid (16s CD):** Restore health over time and apply a brief defensive buff.

### Main Class Skills (20 SP Total)

| Skill Name | Type | Description | Initial | Per Level | Max |
|------------|------|-------------|---------|-----------|-----|
| **Field Aid** | **Special** | **Restore 20 HP over 3s, +10% defense. 16s CD** | **20 HP / 3s / +10%** | **+5 HP / +0.5s / +2.5%** | **40 HP / 5s / +20%** |
| Mending | Stat | Increase heal power percentage | +4% Healing | +4% Healing | +20% Healing |
| Resilience | Stat | Increase ally defense aura percentage within 8m | +3% Defense | +3% Defense | +15% Defense |
| Revitalize | Ability | Restore 20-40 HP over 4s and apply +10-20% defense buff for 3s. 20s cooldown | 20 HP / 10% / 3s | +5 HP / +2.5% / +0s | 40 HP / 20% / 3s |
| Steady Hands | Passive | Reduce all healing ability cooldowns by 3-15% and improve regen by 5-25% | -3% CD / +5% regen | -3% CD / +5% regen | -15% CD / +25% regen |

### Subclass: Cleric (30 SP Cap)

**Subclass Stats:** HP +10%, Speed -10%, Damage -20%, Defense +20%, Attack Speed -15%

**Stat Modifiers:**
| Stat | Modifier |
|------|----------|
| HP | +10% |
| Speed | -10% |
| Damage | -20% |
| Defense | +20% |
| Attack Speed | -15% |

| Skill Name | Type | Description | Initial | Per Level | Max |
|------------|------|-------------|---------|-----------|-----|
| **Divine Blessing** | **Special** | **Holy zone: 25 HP/s, +10% defense, 3s. 18s CD** | **25 HP/s / 3s / +10%** | **+6.25 HP/s / +0.5s / +2.5%** | **50 HP/s / 5s / +20%** |
| Holy Ground | Ability | Create 5m zone for 3-5s. Allies gain 30-50 HP/s + 10-20% defense. 25s CD | 30 HP/s / 10% / 3s | +5 HP/s / +2.5% / +0.5s | 50 HP/s / 20% / 5s |
| Resurrection Pulse | Ability | Send wave restoring 10-30 HP instantly to all allies within 10m. 30s cooldown | 10 HP | +5 HP | 30 HP |
| Shield of Faith | Ability | Wrap ally in barrier absorbing next 1-2 hits. Lasts 5-15s. 20s CD | 1 hit / 5s | +0.25 hit / +2.5s | 2 hits / 15s |
| Sanctify | Stat | Increase holy healing output percentage | +5% Holy | +5% Holy | +25% Holy |
| Devotion | Stat | Increase buff duration by seconds for all buffs you apply | +1s Duration | +1s Duration | +5s Duration |
| Healing Aura | Passive | Allies within 8m regen 0.4-2 HP/s. Self-healing 10-50% more effective. 10% lifesteal. | 0.4 HP/s / +10% | +0.4 HP/s / +10% | 2 HP/s / +50% |

### Subclass: Bard (30 SP Cap)

**Subclass Stats:** HP +5%, Speed +15%, Damage -10%, Defense +5%, Attack Speed +10%

**Stat Modifiers:**
| Stat | Modifier |
|------|----------|
| HP | +5% |
| Speed | +15% |
| Damage | -10% |
| Defense | +5% |
| Attack Speed | +10% |

| Skill Name | Type | Description | Initial | Per Level | Max |
|------------|------|-------------|---------|-----------|-----|
| **Symphony of War** | **Special** | **Allies +12% dmg, +10% atk spd for 4s. 20s CD** | **+12% / +10% / 4s** | **+3.25% / +3.75% / +1s** | **+25% / +25% / 8s** |
| Battle Hymn | Ability | Buff zone 6m radius for 4-8s. Allies gain +10-25% damage and +8-20% attack speed | 4s / +10% dmg / +8% | +1s / +3.75% / +3% | 8s / +25% / +20% |
| Dissonance | Ability | Play chord stunning enemies within 5m for 0.5-1.5s. 18s cooldown | 0.5s stun | +0.25s | 1.5s stun |
| Rallying Tune | Ability | Remove 1 debuff from each ally within 8m and grant 10-30% resistance for 2s | 1 debuff / 10% / 2s | +0 debuff / +5% / +0s | 1 debuff / 30% / 2s |
| Inspiration | Stat | Increase strength of all buffs you apply by percentage | +3% Buff | +3% Buff | +15% Buff |
| Rhythm | Stat | Increase movement speed percentage for you and nearby allies | +4% Speed | +4% Speed | +20% Speed |
| Inspiring Presence | Passive | Allies near you gain +2-10% damage. Enemies near you deal -2-10% damage. +20% gold. | +2% / -2% | +2% / -2% | +10% / -10% |

### Subclass: Alchemist (30 SP Cap)

**Subclass Stats:** HP -5%, Speed +5%, Damage +5%, Defense +5%, Attack Speed —

**Stat Modifiers:**
| Stat | Modifier |
|------|----------|
| HP | -5% |
| Speed | +5% |
| Damage | +5% |
| Defense | +5% |
| Attack Speed | — |

| Skill Name | Type | Description | Initial | Per Level | Max |
|------------|------|-------------|---------|-----------|-----|
| **Plague Flask** | **Special** | **Poison cloud: 40 dmg over 3s. 15s CD, 3s** | **40 dmg / 3s** | **+10 dmg / +0.75s** | **80 dmg / 6s** |
| Healing Flask | Ability | Throw flask at ally within 12m restoring 20-50 HP instantly. 12s cooldown | 20 HP | +7.5 HP | 50 HP |
| Acid Splash | Ability | Throw vial dealing 20-40 damage and reducing armor by 10-30% for 3-5s. 15s CD | 20 dmg / -10% / 3s | +5 dmg / -5% / +0.5s | 40 dmg / -30% / 5s |
| Healing Brew | Ability | Toss potion restoring 15-40 HP to ally within 10m. 10s cooldown | 15 HP | +6.25 HP | 40 HP |
| Toxicology | Stat | Increase poison/potion damage dealt by percentage | +5% Poison | +5% Poison | +25% Poison |
| Preparation | Stat | Increase potion/ability item slots (rounds down until max) | +0.2 Slots | +0.2 Slots | +1 Slot |
| Transmutation | Passive | Potions/consumables 10-50% more effective. 2-10% poison chance on hit. +10% gold/xp. | +10% / 2% | +10% / 2% | +50% / 10% |

### Subclass: Necromancer (30 SP Cap)

**Subclass Stats:** HP -15%, Speed -5%, Damage +22%, Defense -20%, Crit Chance +10%, 14% Lifesteal

**Stat Modifiers:**
| Stat | Modifier |
|------|----------|
| HP | -15% |
| Speed | -5% |
| Damage | +22% |
| Defense | -20% |
| Attack Speed | — |
| Crit Chance | +10% |
| Lifesteal | 14% |

| Skill Name | Type | Description | Initial | Per Level | Max |
|------------|------|-------------|---------|-----------|-----|
| **Grave Swarm** | **Special** | **Swarm deals 30 dmg/s, seeks enemies, 3s. 16s CD** | **30 dmg/s / 3s** | **+7.5 dmg/s / +0.75s** | **60 dmg/s / 6s** |
| Summon Undead | Ability | Summon 1 skeleton warrior (20 HP, 6 damage/attack). Scales to 2 skeletons (40 HP, 10 dmg) | 1 skel / 20 HP / 6 dmg | +0.2 skel / +5 HP / +1 dmg | 2 skel / 40 HP / 10 dmg |
| Bone Spike | Ability | Erupt spike beneath target within 10m dealing 30-70 damage. 8s cooldown | 30 damage | +10 damage | 70 damage |
| Death Shroud | Ability | Cloak self for 4-8s. Enemies who hit you take 10-25 damage. 20s cooldown | 4s / 10 dmg return | +1s / +3.75 dmg | 8s / 25 dmg return |
| Undead Mastery | Stat | Increase minion damage and HP by percentage | +10% Minion | +10% Minion | +50% Minion |
| Soul Reaping | Stat | Increase max summon count by partial amount | +0.2 Summons | +0.2 Summons | +1 Summon |
| Soul Harvest | Passive | Defeated enemies restore 2-10 HP and briefly amplify spell damage. 14% lifesteal. | +2 HP / amp | +2 HP / amp | +10 HP / amp |

---

## Hybrid

### Overview

The Hybrid blends melee and magic. Players begin by investing Skill Points (SP) into the main class tree. All 20 SP must be spent before subclass trees unlock.

**Base Stats:** HP +5%, Speed +5%, Damage +5%, Defense —, Attack Speed +5%

**Stat Modifiers:**
| Stat | Modifier |
|------|----------|
| HP | +5% |
| Speed | +5% |
| Damage | +5% |
| Defense | — |
| Attack Speed | +5% |

**Special Ability — Adaptive Stance (13s CD):** Shift stance to gain situational bonuses in combat.

### Main Class Skills (20 SP Total)

| Skill Name | Type | Description | Initial | Per Level | Max |
|------------|------|-------------|---------|-----------|-----|
| **Adaptive Stance** | **Special** | **+5% all stats for 3s. 13s CD** | **+5% / 3s** | **+2.5% / +0.5s** | **+15% / 5s** |
| Arcane Blade | Stat | Increase magic-infused melee damage percentage | +4% Magic | +4% Magic | +20% Magic |
| Mystic Armor | Stat | Increase defense by +3 and spell resistance by +3 per level | +3 Armor/Resist | +3 Armor/Resist | +15 Armor/Resist |
| Elemental Strike | Ability | Melee attack adds 10-50 elemental damage based on weapon type. 12s cooldown | +10 elemental | +10 elemental | +50 elemental |
| Versatility | Passive | Spells cost 4-20% less mana, melee attacks restore 2-10 mana on hit | -4% cost / +2 mana | -4% cost / +2 mana | -20% cost / +10 mana |

### Subclass: Spellblade (30 SP Cap)

**Subclass Stats:** HP +5%, Speed +8%, Damage +18%, Defense -6%, Attack Speed +8%, 3% Lifesteal

**Stat Modifiers:**
| Stat | Modifier |
|------|----------|
| HP | +5% |
| Speed | +8% |
| Damage | +18% |
| Defense | -6% |
| Attack Speed | +8% |
| Lifesteal | 3% |

| Skill Name | Type | Description | Initial | Per Level | Max |
|------------|------|-------------|---------|-----------|-----|
| **Elemental Infusion** | **Special** | **+10% elemental dmg, effect 5s. 12s CD** | **+10% / 5s** | **+5% / +1.25s** | **+30% / 10s** |
| Blade Burst | Ability | Unleash magic in weapon for 4m radius explosion. Deal 20-100 damage. 15s CD | 20 damage | +20 damage | 100 damage |
| Arcane Dash | Ability | Dash 6m forward leaving 3s magic trail. Enemies crossing take 10-50 damage/s | 10 dmg/s / 3s | +10 dmg/s / +0s | 50 dmg/s / 3s |
| Spell Parry | Ability | Parry next attack within 2s, converting it to 20-80 magic damage burst. 10s CD | 20 damage / 2s | +15 damage / +0s | 80 damage / 2s |
| Mana Blade | Stat | Increase magic damage on melee attacks by percentage | +5% Magic | +5% Magic | +25% Magic |
| Resonance | Stat | Reduce spell cooldown when landing melee attacks by percentage | -2% CD | -2% CD | -10% CD |
| Arcane Strike | Passive | Every 4th attack deals 6-30% bonus magic damage. 3% lifesteal. | 6% | +6% | 30% |

### Subclass: Shadow Knight (30 SP Cap)

**Subclass Stats:** HP +15%, Speed +5%, Damage +10%, Defense -2%, Attack Speed —, 15% Lifesteal

**Stat Modifiers:**
| Stat | Modifier |
|------|----------|
| HP | +15% |
| Speed | +5% |
| Damage | +10% |
| Defense | -2% |
| Attack Speed | — |
| Lifesteal | 15% |

| Skill Name | Type | Description | Initial | Per Level | Max |
|------------|------|-------------|---------|-----------|-----|
| **Dark Pact** | **Special** | **Sacrifice 10% HP, deal 75 dmg, heal 25%. 10s CD** | **10% / 75 dmg / 25%** | **+2.5% / +18.75 dmg / +6.25%** | **20% / 150 dmg / 50%** |
| Void Strike | Ability | Teleport to enemy within 8m, dealing 20-80 dark damage + heal 25% of damage. 12s CD | 20 damage / 25% heal | +15 damage / +0% | 80 damage / 50% heal |
| Shadow Burst | Ability | Explode in 5m radius dealing 30-70 damage + 10-30% slow for 2s. 18s cooldown | 30 dmg / 10% / 2s | +10 dmg / +5% / +0s | 70 dmg / 30% / 2s |
| Soul Rend | Ability | Drain target within 8m for 20-60 damage, healing yourself for 10-30 HP. 15s CD | 20 dmg / 10 heal | +10 dmg / +5 heal | 60 dmg / 30 heal |
| Shadow Power | Stat | Increase dark/void damage dealt by percentage | +5% Dark | +5% Dark | +25% Dark |
| Eclipse | Stat | Increase damage by percentage when health is below 50% | +4% Low HP | +4% Low HP | +20% Low HP |
| Vampiric Embrace | Passive | Lifesteal is 10-50% more effective. Healing from abilities 5-25% stronger. 15% base lifesteal. | +10% / +5% | +10% / +5% | +50% / +25% |

### Subclass: Monk (30 SP Cap)

**Subclass Stats:** HP +5%, Speed +18%, Damage +14%, Defense —, Attack Speed +20%, Crit Chance +15%, 15% Dodge

**Stat Modifiers:**
| Stat | Modifier |
|------|----------|
| HP | +5% |
| Speed | +18% |
| Damage | +14% |
| Defense | — |
| Attack Speed | +20% |
| Crit Chance | +15% |
| Dodge | 15% |

| Skill Name | Type | Description | Initial | Per Level | Max |
|------------|------|-------------|---------|-----------|-----|
| **Seven-Point Strike** | **Special** | **5 strikes, 15 dmg each, final crit + stun 0.5s. 15s CD** | **5x15 dmg / 0.5s** | **+0.5 hit / +1.25 dmg / +0.125s** | **7x20 dmg / 1s** |
| Flurry | Ability | Rapid 3-5 hit combo over 1.5s, final hit stuns for 0.5-1s. 10s cooldown | 3 hits / 0.5s stun | +0.5 hit / +0.125s | 5 hits / 1s stun |
| Pressure Point | Ability | Strike vital spot stunning target for 0.5-1.5s and dealing 30-70 damage. 12s CD | 0.5s stun / 30 dmg | +0.25s / +10 dmg | 1.5s stun / 70 dmg |
| Wind Step | Ability | Dash through enemy within 6m dealing 20-60 damage and reset dodge cooldown. 8s CD | 20 damage | +10 damage | 60 damage |
| Chi Flow | Stat | Increase energy/mana regeneration per second | +2 Regen | +2 Regen | +10 Regen |
| Discipline | Stat | Increase combo damage multiplier percentage | +3% Combo | +3% Combo | +15% Combo |
| Flow State | Passive | Dodge grants +4-20% attack speed for 3s. Consecutive hits add +0.4-2% dodge (max 4-20%). 15% base. | +4% / +0.4% | +4% / +0.4% | +20% / +2% |

---

## Controller

### Overview

The Controller manipulates the battlefield and enemy movement. Players begin by investing Skill Points (SP) into the main class tree. All 20 SP must be spent before subclass trees unlock.

**Base Stats:** HP —, Speed —, Damage -5%, Defense +5%, Attack Speed —

**Stat Modifiers:**
| Stat | Modifier |
|------|----------|
| HP | — |
| Speed | — |
| Damage | -5% |
| Defense | +5% |
| Attack Speed | — |

**Special Ability — Control Field (14s CD):** Deploy a control zone that slows enemies and weakens their outgoing damage.

### Main Class Skills (20 SP Total)

| Skill Name | Type | Description | Initial | Per Level | Max |
|------------|------|-------------|---------|-----------|-----|
| **Control Field** | **Special** | **6m zone: 10% slow, -5% enemy dmg, 3s. 14s CD** | **10% / -5% / 3s** | **+5% / -2.5% / +0.75s** | **30% / -15% / 6s** |
| Command | Stat | Increase control effect duration (stun/root/slow) by seconds | +0.4s Duration | +0.4s Duration | +2s Duration |
| Tactical Mind | Stat | Reduce control ability cooldowns by percentage | -3% CD | -3% CD | -15% CD |
| Displace | Ability | Push or pull target enemy 4-8m to new position. Single target, 10m range. 12s CD | 4m displacement | +1m | 8m displacement |
| Tempo Lock | Passive | Enemies within your control zones deal 3-15% less damage | -3% damage | -3% damage | -15% damage |

### Subclass: Chronomancer (30 SP Cap)

**Subclass Stats:** HP —, Speed —, Damage —, Defense —, Attack Speed —

**Stat Modifiers:**
| Stat | Modifier |
|------|----------|
| HP | — |
| Speed | — |
| Damage | — |
| Defense | — |
| Attack Speed | — |

| Skill Name | Type | Description | Initial | Per Level | Max |
|------------|------|-------------|---------|-----------|-----|
| **Time Fracture** | **Special** | **20% slow enemies, +10% haste exit, 2.5s. 16s CD** | **20% / +10% / 2.5s** | **+5% / +5% / +0.5s** | **40% / +30% / 4.5s** |
| Slow Field | Ability | Create 6m zone slowing enemies by 20-40% for 3-5s. 20s cooldown | 20% / 3s | +5% / +0.5s | 40% / 5s |
| Time Freeze | Ability | Freeze single target completely for 0.5-2s. 25s cooldown | 0.5s freeze | +0.375s | 2s freeze |
| Rewind | Ability | Rewind position to 1-3s ago, resetting damage taken in that window. 35s CD | 1s rewind | +0.5s | 3s rewind |
| Time Warp | Stat | Increase movement speed by percentage after using control abilities | +3% Speed | +3% Speed | +15% Speed |
| Decay | Stat | Enemies in your slow fields take 5-25 damage over time per second | +5 DOT | +5 DOT | +25 DOT |
| Borrowed Seconds | Passive | Control effects apply cooldown reduction burst 6-30%. | +6% CDR | +6% CDR | +30% CDR |

### Subclass: Warden (30 SP Cap)

**Subclass Stats:** HP —, Speed —, Damage —, Defense —, Attack Speed —

**Stat Modifiers:**
| Stat | Modifier |
|------|----------|
| HP | — |
| Speed | — |
| Damage | — |
| Defense | — |
| Attack Speed | — |

| Skill Name | Type | Description | Initial | Per Level | Max |
|------------|------|-------------|---------|-----------|-----|
| **Bastion Ring** | **Special** | **Ring 3s: 10% slow, root first target. 18s CD** | **10% / 3s** | **+5% / +0.5s** | **30% / 5s** |
| Ring of Thorns | Ability | Summon ring (5m radius) lasting 3-5s. Roots crossing enemies, deals 15-40 dmg/s | 3s / 15 dmg/s | +0.5s / +6.25 dmg/s | 5s / 40 dmg/s |
| Vine Snare | Ability | Summon vines rooting all enemies in 4m radius for 0.5-2s. 15s cooldown | 0.5s root | +0.375s | 2s root |
| Bramble Wall | Ability | Erect thorn wall (6m wide, 2s duration) blocking movement, dealing 20-50 damage | 2s / 20 damage | +0s / +7.5 damage | 2s / 50 damage |
| Fortification | Stat | Increase ring/barrier HP and duration by percentage | +10% HP | +10% HP | +50% HP |
| Entrapment | Stat | Increase root/slow duration by seconds | +0.4s Root | +0.4s Root | +2s Root |
| Line Holder | Passive | Enemies near your control zones deal 4-20% less damage | -4% damage | -4% damage | -20% damage |

### Subclass: Hexbinder (30 SP Cap)

**Subclass Stats:** HP —, Speed —, Damage —, Defense —, Attack Speed —

**Stat Modifiers:**
| Stat | Modifier |
|------|----------|
| HP | — |
| Speed | — |
| Damage | — |
| Defense | — |
| Attack Speed | — |

| Skill Name | Type | Description | Initial | Per Level | Max |
|------------|------|-------------|---------|-----------|-----|
| **Severing Hex** | **Special** | **Cone: -5% enemy dmg, +3% ability dmg taken. 13s CD, 3s** | **-5% / +3% / 3s** | **-3.75% / +3% / +0.75s** | **-20% / +15% / 6s** |
| Hex Cone | Ability | 45° cone curse: enemies deal 5-20% less damage, take 5-15% more ability damage | -5% dmg / +5% taken | -3.75% / +2.5% | -20% / +15% |
| Cursed Ground | Ability | Corrupt 5m ground for 3-5s. Enemies have -10-30% stats while standing in it | 3s / -10% | +0.5s / -5% | 5s / -30% |
| Hex Bolt | Ability | Fire projectile marking single target instantly. Mark lasts 2-6s. 12s CD | 2s mark | +1s | 6s mark |
| Dark Mark | Stat | Increase curse bonus damage by percentage | +4% Curse | +4% Curse | +20% Curse |
| Affliction | Stat | Increase curse debuff strength by percentage | +3% Debuff | +3% Debuff | +15% Debuff |
| Malice Chain | Passive | Defeated cursed enemies spread weaker curse within 4m (10-50% chance) | 10% spread | +10% spread | 50% spread |

### Subclass: Stormcaller (30 SP Cap)

**Subclass Stats:** HP —, Speed —, Damage —, Defense —, Attack Speed —

**Stat Modifiers:**
| Stat | Modifier |
|------|----------|
| HP | — |
| Speed | — |
| Damage | — |
| Defense | — |
| Attack Speed | — |

| Skill Name | Type | Description | Initial | Per Level | Max |
|------------|------|-------------|---------|-----------|-----|
| **Tempest Pulse** | **Special** | **30 dmg, knockback 2m, 1s slow. 12s CD** | **30 dmg / 2m / 1s** | **+7.5 dmg / +0.5m / +0.5s** | **60 dmg / 4m / 3s** |
| Shockwave | Ability | Chain of 2 shockwaves (8m range) dealing 20-60 damage + 10-30% slow for 1s. 16s CD | 20 dmg / 10% | +10 dmg / +5% | 60 dmg / 30% |
| Thunder Clap | Ability | Slam ground sending shockwave in 6m radius, stunning for 0.3-1.5s. 18s cooldown | 0.3s stun | +0.3s | 1.5s stun |
| Static Field | Ability | Charge self for 4-8s. Enemies within 4m take 5-20 damage when they hit you | 4s / 5 dmg return | +1s / +3.75 dmg | 8s / 20 dmg return |
| Voltage | Stat | Increase lightning damage dealt by percentage | +5% Lightning | +5% Lightning | +25% Lightning |
| Surge | Stat | Increase knockback distance and stun duration by percentage | +10% Knockback | +10% Knockback | +50% Knockback |
| Static Build | Passive | Each consecutive hit on controlled target adds +1-5% lightning damage, up to +5-25% | +1% per hit / +5% max | +1% per hit / +5% max | +5% per hit / +25% max |

---

# Quick Reference

## Balanced Crit Reference

### Level-Based Crit Baseline

| Level Range | Crit Rate | Crit Damage |
|-------------|-----------|-------------|
| Lv 1 | 5.0% | 110% |
| Lv 25 | 6.2% | 112.4% |
| Lv 50 | 7.5% | 114.9% |
| Lv 75 | 8.7% | 117.4% |
| Lv 100 | 10.0% | 120% |

### Main Class Crit Modifiers

| Main Class | Crit Rate Bonus | Crit Damage Bonus | Role Target |
|------------|------------------|-------------------|-------------|
| Tank | +2% | +5% | Lowest crit, highest stability |
| Support | +3% | +5% | Light crit, utility-first |
| Hybrid | +6% | +8% | Flexible mid-crit scaling |
| Controller | +6% | +10% | Moderate crit with ability payoff |
| DPS | +8% | +10% | Strong general crit baseline |

### Notable Subclass Crit Modifiers

Active subclass bonuses apply at 50% value.

| Subclass | Crit Rate Bonus | Crit Damage Bonus | Intent |
|----------|------------------|-------------------|--------|
| Assassin | +28% | +55% | Highest burst and crit payoff |
| Samurai | +8% | +40% | Reliable crit damage spike |
| Ranger | +10% | +15% | Precision ranged crit build |
| Mage | +6% | +20% | Spell burst without assassin volatility |
| Necromancer | +8% | +15% | Sustained spell crit pressure |
| Spellblade | +8% | +15% | Mixed melee-magic crit hybrid |
| Monk | +12% | +20% | Fast combo crit scaling |

## Class Summary

| Class | Subclasses | Total Subclass SP | Notes |
|-------|------------|-------------------|-------|
| **Tank** | Guardian, Berserker, Paladin | 90 SP max | 3 subclasses. Unlock after 20 SP in Tank main tree |
| **DPS** | Assassin, Ranger, Mage, Samurai | 120 SP max | 4 subclasses. Unlock after 20 SP in DPS main tree |
| **Support** | Cleric, Bard, Alchemist, Necromancer | 120 SP max | 4 subclasses. Unlock after 20 SP in Support main tree |
| **Hybrid** | Spellblade, Shadow Knight, Monk | 90 SP max | 3 subclasses. Unlock after 20 SP in Hybrid main tree |
| **Controller** | Chronomancer, Warden, Hexbinder, Stormcaller | 120 SP max | 4 subclasses. Unlock after 20 SP in Controller main tree |
