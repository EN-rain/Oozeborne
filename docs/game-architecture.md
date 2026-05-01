# Game Architecture

## Project Bootstrap

The Godot project is defined in `game/project.godot`.

Important runtime settings:

- project name: `NewGame`
- main scene: `res://scenes/ui/auth_menu.tscn`
- rendering feature set: `Forward Plus`
- physics tick rate: `120`
- physics interpolation: enabled

---

## Autoload Singletons

Defined in `game/project.godot`.

| Singleton | Responsibility |
|---|---|
| `MultiplayerManager` | JWT auth, session restore, WebSocket lifecycle, room state, selected class |
| `MultiplayerUtils` | Op codes, interpolation buffers, reconciliation, ping, input send loop |
| `NetworkMessaging` | Helper wrapper around match-state message sending |
| `ClassManager` | Loads and caches all 5 main classes and 18 subclasses |
| `SkillRegistry` | Loads all skill `.tres` resources from `resources/skills/` |
| `StatusEffectManager` | Tracks active status effects per entity |
| `LevelSystem` | Player XP, levels, and stat scaling |
| `DamageNumbers` | Floating combat text manager |
| `CoinManager` | Coin total and coin drop events |
| `ShopManager` | Item purchase state and shop data (loaded from `shop_items.json`) |
| `AdminManager` | Handles admin commands from Moon Control Center |

These are the real backbone of the client — most scene scripts rely on them directly.

---

## Scene Flow

### Auth

`auth_menu.gd` is the first user-facing scene.

It:
- attempts to restore a stored JWT from `user://auth_session.json`
- allows email login via `POST /auth/login`
- allows email registration via `POST /auth/register`
- routes to the main menu on success

### Main Menu

`main_menu.gd` provides three practical paths:

- **Local/offline** — direct jump into gameplay (no network)
- **Host multiplayer room** — calls `POST /rooms/create`, then `room_lobby.tscn`
- **Join multiplayer room** — resolves room code via `POST /rooms/join`, then `room_lobby.tscn`

Also supports logout and quit.

### Room Lobby

`room_lobby.gd` is the heaviest UI scene in the project.

It manages:
- player list and host controls
- lobby title editing
- class carousel (5 main classes)
- subclass/party/stats panels via `RoomLobbyView`
- chat UI widgets
- class selection broadcast to all lobby members
- slime preview assignment per class (palette shader)
- start-game transition (host-gated)

`room_lobby_view.gd` owns:
- party-card rendering
- class-order display data
- panel formatting for stats and subclass descriptions

### Main Match

`main.gd` orchestrates in-match gameplay.

It is responsible for:
- replacing the placeholder local player with the selected class scene
- setting initial local spawn position
- opening WebSocket to `game-server` and wiring match signals
- spawning remote players from `OP_PLAYER_JOIN` messages
- starting the input send loop
- applying authoritative snapshots from `OP_STATE`
- initialising mob spawning (client-side visuals driven by `OP_MOB_SPAWN`)
- showing FPS/ping/interpolation debug text

---

## Player Model

The player controller is `game/scripts/entities/player/player.gd`.

It contains:
- local-only movement and attack input
- dash logic and cooldown
- damage, hit stun, and knockback
- slash spawn for basic attack
- sprite animation switching
- class modifier application on spawn

Notable runtime behaviour:
- local players use `move_and_slide()`
- remote players are updated by `MultiplayerUtils` interpolation — no local physics
- the same script is reused for local and remote player instances

---

## Class and Progression Data

### Main Classes and Subclasses

`ClassManager` loads all 5 main classes and 18 subclasses at startup.

| Main Class | Subclasses |
|---|---|
| Tank | Guardian, Berserker, Paladin |
| DPS | Assassin, Ranger, Mage, Samurai |
| Support | Cleric, Bard, Alchemist, Necromancer |
| Hybrid | Spellblade, Shadow Knight, Monk |
| Controller | Chronomancer, Warden, Hexbinder, Stormcaller |

Class scripts live in `game/scripts/resources/classes/{role}/`.

`player_class.gd` is the base resource. A `PlayerClass` contains:
- display metadata (name, description, icon)
- stat multipliers
- active/passive ability descriptors
- passive bonus values
- `player_scene` — the scene to instantiate for this class

### Skills

`SkillRegistry` walks `game/resources/skills/` at startup and loads all `.tres` skill definitions.

Skills are organised by `main_class/subclass/` folder. Each skill has:
- `skill_id`, `display_name`, `description_template`
- `skill_type`: `PASSIVE`, `SPECIAL`, or `ACTIVE`
- `icon`: Texture2D

### Levels and Stats

`player_stats.gd` defines:
- base health, speed, dash speed, dash cooldown, attack damage, crit chance, mana, regen
- per-level scaling for every stat
- XP curve (base × scaling^(level−1))
- min/max caps

`level_system.gd` applies those stats at runtime:
- registers players by instance ID
- tracks XP and next-level thresholds
- handles multi-level-up loops
- writes scaled stats back to player nodes and health components

---

## Enemies / Mobs

Five mob types exist in `game/scenes/entities/enemies/`:

| Scene | Type | Role |
|---|---|---|
| `blue_slime.tscn` | `slime` | Common — basic melee |
| `blue_slime.tscn` | `common` | Common — basic melee variant |
| `plagued_lancer.tscn` | `lancer` | Elite — charge attack |
| `archer.tscn` | `archer` | Elite — ranged |
| `void_warden.tscn` | `warden` | Elite — area denial |
| *(boss scene)* | `boss` | Boss — high HP, wave boss |

`mob_spawner.gd` handles:
- spawning common and elite enemies at off-screen positions
- enforcing min distance from player
- tracking active mob counts per category
- `spawn_mob_by_name()` for admin remote-spawn

`mob_scene_registry.gd` maps mob type strings to `PackedScene` references.

Mob stats (HP, speed, damage, XP reward) are **live-tunable** from the Admin Portal via `admin/mobs/:mob_type`.

---

## Status Effects

`status_effect_manager.gd` stores effects by entity ID and effect name.

Status effect components:
- `components/status_effect.gd` — base
- `components/buffs/*.gd`
- `components/debuffs/*.gd`

The manager:
- ticks all effects every frame
- refreshes duplicates instead of stacking same-name effects
- removes expired effects and frees their nodes

---

## Economy and Shop

Items are defined in `game/resources/data/shop_items.json` with four categories:

| Category | Examples |
|---|---|
| Consumables | Health Potion (small/large), Shield Potion, Speed Potion, Iron Skin Potion |
| Permanent Upgrades | Max HP +10/+25, Attack +5, Speed +5%, Crit +5%, Lifesteal +3% |
| Equipment | Iron Sword, Swift Boots, Warrior's Ring, Assassin's Dagger |
| Special | Revive Stone, XP Tome, Gold Booster, Magnet Ring |

`ShopManager` loads items from JSON at startup. `CoinManager` tracks coin totals.

The shop UI is driven by `ShopManager` and `CoinManager` and is presented during the Upgrade Phase between waves.

---

## Slime Player Presentation

Player visuals use slime scenes:
- `game/assets/shaders/slime_color.gdshader`
- `game/assets/sprites/Player/Slime/`
- `game/scenes/entities/player/slime_*.tscn`

One scene per colour variant, sharing:
- generated base frames for `idle`, `walk`, and `dash`
- shader parameters for body colours, outline, iris, and eye highlight
- lobby previews use the same shader path for visual consistency
