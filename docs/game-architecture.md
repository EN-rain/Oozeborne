# Game Architecture

## Project Bootstrap

The Godot project is defined in [project.godot](c:\Users\LENOVO\Desktop\proxy\game\project.godot:1).

Important runtime settings:

- project name: `NewGame`
- main scene: `res://scenes/ui/auth_menu.tscn`
- rendering feature set: `Forward Plus`
- physics tick rate: `120`
- physics interpolation: enabled

## Autoload Singletons

Defined in [project.godot](c:\Users\LENOVO\Desktop\proxy\game\project.godot:13).

- `MultiplayerManager`: Nakama auth, session, socket, room, selected class state
- `RemotePlayerManager`: remote player helper singleton
- `ClientPrediction`: prediction singleton
- `NetworkMessaging`: helper wrapper around match-state sending
- `MultiplayerUtils`: op codes, interpolation, reconciliation, ping, input loop
- `StatusEffectManager`: tracks active status effects by entity id
- `LevelSystem`: player XP, levels, stat scaling
- `DamageNumbers`: floating combat text manager
- `CoinManager`: coin total and coin events
- `ShopManager`: item purchase state and shop data

These are the real backbone of the client; most scene scripts rely on them directly.

## Scene Flow

### Auth

[auth_menu.gd](c:\Users\LENOVO\Desktop\proxy\game\src\ui\auth_menu.gd:1) is the first user-facing scene.

It:

- attempts to restore an encrypted saved Nakama session
- allows email login
- allows email registration
- routes to the main menu on success

### Main Menu

[main_menu.gd](c:\Users\LENOVO\Desktop\proxy\game\src\ui\main_menu.gd:1) provides three practical paths:

- local/offline start into gameplay
- host multiplayer room
- join multiplayer room by room code

It also supports logout and quit.

### Room Lobby

[room_lobby.gd](c:\Users\LENOVO\Desktop\proxy\game\src\ui\room_lobby.gd:1) is the heaviest UI scene in the project.

It manages:

- player list and host controls
- lobby title editing
- class carousel
- subclass/party/stats panels through `RoomLobbyView`
- chat UI widgets
- class selection broadcast
- slime preview assignment per class
- start-game transition

[room_lobby_view.gd](c:\Users\LENOVO\Desktop\proxy\game\src\ui\room_lobby_view.gd:1) is a helper object that owns:

- party-card rendering
- class-order display data
- panel formatting for stats and subclass descriptions
- hardcoded display content for class cards and talents

### Main Match

[main.gd](c:\Users\LENOVO\Desktop\proxy\game\src\systems\game\main.gd:1) orchestrates gameplay.

It is responsible for:

- replacing the placeholder local player with the selected class scene
- setting initial local spawn position
- wiring Nakama match signals
- spawning remote players
- starting input send loop
- handling authoritative snapshots
- handling legacy JSON match messages
- initializing mob spawning
- showing FPS/ping/interpolation debug text

## Player Model

The player controller is [player.gd](c:\Users\LENOVO\Desktop\proxy\game\src\entities\player\player.gd:1).

It currently contains:

- local-only movement and attack input
- dash logic and cooldown
- damage, hit stun, and knockback
- slash spawn for basic attack
- sprite animation switching
- class modifier application

Notable runtime behavior:

- local players use `move_and_slide()`
- remote players do not run local physics and are updated by multiplayer interpolation instead
- the same script is reused for local and remote player instances

## Class and Progression Data

### Classes

[player_class.gd](c:\Users\LENOVO\Desktop\proxy\game\src\resources\player_class.gd:1) is the base resource for classes.

A `PlayerClass` contains:

- display metadata
- stat multipliers
- active/passive ability descriptors
- passive bonus values
- `player_scene` to instantiate for this class
- starting-level and starting-item fields

Concrete class resources live in:

- `src/resources/classes/tank/`
- `src/resources/classes/dps/`
- `src/resources/classes/support/`
- `src/resources/classes/hybrid/`

### Levels and Stats

[player_stats.gd](c:\Users\LENOVO\Desktop\proxy\game\src\resources\player_stats.gd:1) defines:

- base health, speed, dash, and damage
- per-level scaling
- XP curve

[level_system.gd](c:\Users\LENOVO\Desktop\proxy\game\src\globals\level_system.gd:1) applies those stats at runtime.

It:

- registers players by instance id
- tracks XP and next-level thresholds
- handles multi-level-up loops
- writes scaled stats back to player nodes and health components

## Status Effects

[status_effect_manager.gd](c:\Users\LENOVO\Desktop\proxy\game\src\globals\status_effect_manager.gd:1) stores effects by entity id and effect name.

Status effect implementation is component-style:

- `src/components/status_effect.gd`
- `src/components/buffs/*.gd`
- `src/components/debuffs/*.gd`

The manager:

- ticks all effects every frame
- refreshes duplicates instead of stacking same-name effects
- removes expired effects and frees their nodes

## Economy and Shop

The shop UI is [shop_ui.gd](c:\Users\LENOVO\Desktop\proxy\game\src\ui\shop_ui.gd:1).

It consumes data from `ShopManager` and `CoinManager`, and organizes items into:

- consumables
- upgrades
- equipment
- special

The system is UI-driven and resource-based rather than inventory-heavy at this stage.

## Enemy/Mob Side

The main enemy spawn coordinator is [mob_spawner.gd](c:\Users\LENOVO\Desktop\proxy\game\src\systems\game\mob_spawner.gd:1).

It:

- spawns common and elite enemies
- enforces min distance from player
- keeps separate common/elite caps
- respawns mobs after delays until total spawn budgets are exhausted

Enemy scripts currently present:

- `blue_slime.gd`
- `archer.gd`
- `plagued_lancer.gd`
- `bt_enemy.gd`

## Slime Player Presentation

The player visuals are currently centered on slime scenes:

- [slime_color.gdshader](c:\Users\LENOVO\Desktop\proxy\game\assets\shaders\slime_color.gdshader:1)
- `game/assets/sprites/Player/Slime/`
- `game/scenes/entities/player/slime_*.tscn`

Current implementation details:

- shared generated base frames for `idle`, `walk`, and `dash`
- one scene per color variant
- shader overrides for body colors, outline, iris, and eye highlight
- lobby previews use the same shader path for visual consistency
