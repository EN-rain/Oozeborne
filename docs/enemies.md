# Enemy Behavior Tree Reference

## How Behavior Trees Work

The `BTPlayer` node runs the behavior tree every frame. Each BT node returns a `Status`:
- `SUCCESS` - Action completed, move to next node
- `FAILURE` - Action failed, try alternative (selector) or fail (sequence)
- `RUNNING` - Action in progress, come back next frame

### Node Types
- **Selector**: Runs children left-to-right, returns SUCCESS on first success
- **Sequence**: Runs children left-to-right, fails if any child fails
- **Action**: Performs an action (chase, attack, idle)
- **Condition**: Checks a condition (has player, has LOS, phase check)

### Example: Slime Behavior Tree
```
Selector (try combat, else idle)
|-- Sequence (combat chain)
|   |-- DetectPlayer (find player in DetectionArea)
|   |-- HasLOS (check line-of-sight via SightRay)
|   |-- Chase (move toward player)
|   `-- MeleeAttack (attack when in range)
`-- Idle (wander randomly when no player)
```

**Execution flow:**
1. DetectPlayer finds player -> SUCCESS
2. HasLOS checks SightRay -> SUCCESS (if visible)
3. Chase moves toward player -> RUNNING (while moving)
4. MeleeAttack triggers when in `attack_distance` -> SUCCESS
5. Sequence restarts from DetectPlayer

If any step fails, Selector falls back to Idle.

---

## Mobs (`mob_behavior_tree/`)

### BTEnemy Stats

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `max_health` | int | 50 | Maximum HP |
| `speed` | float | 60.0 | Movement speed |
| `contact_damage` | int | 10 | Damage on touch |
| `damage_cooldown` | float | 1.0 | Seconds between contact damage |
| `attack_distance` | float | 150.0 | Range for attacks |
| `attack_cooldown` | float | 2.0 | Seconds between attacks |
| `knockback_force` | float | 300.0 | Knockback applied to player |
| `xp_value` | int | 10 | XP dropped on death |

### BTEnemy State Variables

| Variable | Purpose |
|----------|---------|
| `player` | Reference to detected player (set by DetectionArea) |
| `can_damage` | Can apply contact damage |
| `can_attack` | Can perform attack (cooldown ready) |
| `is_attacking` | Currently in attack animation |
| `is_taking_damage` | In damage stun |
| `is_dying` | Death animation playing |

### BTEnemy Methods (called by BT actions)

| Method | Params | Description |
|--------|--------|-------------|
| `take_damage(amount)` | int | Receive damage, play hurt anim |
| `die()` | - | Trigger death, drop coins |
| `begin_melee_attack(target, damage, knockback)` | Node, int, float | Start melee attack |
| `begin_ranged_attack(direction, speed)` | Vector2, float | Fire projectile |
| `has_target_line_of_sight()` | - | Check SightRay to player |

### Shared Actions (`main/`)

| Script | Returns SUCCESS When |
|--------|---------------------|
| `bt_action_detect_player.gd` | Player found in DetectionArea |
| `bt_condition_has_player.gd` | `player` variable is set |
| `bt_condition_has_los.gd` | SightRay has clear path to player |
| `bt_action_chase.gd` | Within `stop_distance` of player |
| `bt_action_melee_attack.gd` | Attack executed |
| `bt_action_ranged_attack.gd` | Projectile fired |
| `bt_action_idle.gd` | Random wander completed |

### Current Mobs

| Mob | HP | Speed | Attack | Special |
|-----|----|----|--------|---------|
| Slime | 50 | 60 | Melee 10 dmg | Contact damage |
| Archer | 30 | 40 | Ranged arrow | Predicts player movement |
| Plagued Lancer | 80 | 70 | Melee 15 dmg | Higher knockback |

---

## Bosses (`boss_behavior_tree/`)

### BTBoss Properties (extends BTEnemy)

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `boss_display_name` | String | "Boss" | UI display name |
| `base_health` | int | 2000 | Max HP |
| `enrage_time` | float | 300.0 | Seconds until enrage |
| `phase_2_hp_percent` | float | 0.6 | HP% for phase 2 |
| `phase_3_hp_percent` | float | 0.3 | HP% for phase 3 |
| `current_phase` | int | 1 | Current phase (1-3) |
| `is_enraged` | bool | false | Enrage state |

### BTBoss Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `set_skill_cooldown(name, duration)` | void | Start skill cooldown |
| `is_skill_ready(name)` | bool | Check if skill off cooldown |
| `get_current_phase()` | int | Get current phase |
| `get_health_percent()` | float | Get HP as 0.0-1.0 |

### BTBoss Signals

| Signal | Params | When emitted |
|--------|--------|--------------|
| `phase_changed` | phase: int | Phase transition |
| `boss_died` | - | Boss death |

### Void Warden (`void_warden/`)

**Stats:** 2000 HP, 300s enrage

| Skill | Damage | Cooldown | Phase | Effect |
|-------|--------|----------|-------|--------|
| Shadow Strike | 80 | 5s | All | Teleport behind + strike |
| Void Pulse | 40 | 8s | All | 200 radius AoE |
| Dark Chains | - | 12s | 2+ | Root 3 seconds |
| Soul Drain | 60 | 15s | 3+ | Damage + heal 50% |

**Phase Bonuses:**
- Phase 2: Speed 35->45, Dark Chains unlocked
- Phase 3: Speed 45->55, Soul Drain unlocked

---

## Behavior Tree Patterns

### Mob
```
Selector -> [Detect, HasPlayer, Chase, Attack] | Idle
```

### Boss
```
Selector -> [Detect, HasPlayer, Chase, RandomSelector(skills)] | Idle
```

Skills gated by `BTConditionPhase` for phase-locked abilities.
