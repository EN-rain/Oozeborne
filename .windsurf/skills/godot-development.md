---
description: Godot 4 game development with GDScript - patterns, conventions, and best practices for this project
---

# Godot Development Skill

Expert assistant for Godot 4.6 game development with GDScript, tailored to this project's architecture and conventions.

## When to Use

- Writing or modifying GDScript files
- Creating Godot scenes and resources
- Implementing game mechanics, entities, or systems
- Working with signals, nodes, and the scene tree
- Debugging Godot-specific issues

## Project Architecture Overview

### Autoload Singletons

These managers are available globally:

- `MultiplayerManager` - Nakama auth, session, socket, room state
- `RemotePlayerManager` - Remote player helper
- `ClientPrediction` - Client-side prediction
- `NetworkMessaging` - Match-state sending wrapper
- `MultiplayerUtils` - Op codes, interpolation, reconciliation
- `StatusEffectManager` - Active status effects by entity id
- `LevelSystem` - XP, levels, stat scaling
- `DamageNumbers` - Floating combat text
- `CoinManager` - Coin total and events
- `ShopManager` - Item purchase state

### Directory Structure

```
game/
├── src/
│   ├── globals/      # Autoload singletons
│   ├── systems/      # Game orchestration, mob spawning
│   ├── entities/     # Player, enemies, projectiles, items
│   ├── components/   # Health, status effects
│   ├── resources/    # Class, stats, shop data models
│   ├── ui/           # Auth, menu, lobby, shop
│   └── effects/      # Visual effects
├── scenes/           # .tscn scene files
├── assets/           # Art, shaders, sprites
└── resources/        # Engine resources
```

## GDScript Conventions

### Type Declarations

Always use typed variables and functions:

```gdscript
var _radius := 26.0
var _start_angle := 0.0
var _colors: Array[Color] = []

func _build_arc_points(from_angle: float, to_angle: float, radius: float) -> PackedVector2Array:
    var pts := PackedVector2Array()
    return pts
```

### Export Properties

Use `@export` for inspector-exposed properties with typed getters/setters:

```gdscript
var _anim_t := 0.0
@export var anim_t: float:
    get:
        return _anim_t
    set(value):
        var v := clampf(value, 0.0, 1.0)
        if is_equal_approx(v, _anim_t):
            return
        _anim_t = v
        _draw_frame(_anim_t)
```

### Onready References

Use `@onready` for node references:

```gdscript
@onready var arc_glow: Line2D = $ArcGlow
@onready var animation_player: AnimationPlayer = $AnimationPlayer
```

### Signal Connections

Check before connecting to avoid duplicates:

```gdscript
if not animation_player.animation_finished.is_connected(_on_animation_finished):
    animation_player.animation_finished.connect(_on_animation_finished)
```

### Constants

Define constants at class level for magic numbers:

```gdscript
const FRAME_STEPS := 9
```

## Common Patterns

### Visual Effects

Effects should:
1. Accept configuration via `play_*` function
2. Use AnimationPlayer for timing
3. Clean up with `queue_free()` on completion

```gdscript
func play_wave_slash(
    center: Vector2,
    radius: float,
    start_deg: float,
    arc_deg: float,
    thickness: float,
    duration: float,
    clockwise: bool,
    colors: Array[Color]
) -> void:
    global_position = center
    _radius = radius
    # ... configure effect
    if animation_player.has_animation("slash_play"):
        animation_player.play("slash_play")
    else:
        queue_free()

func _on_animation_finished(_anim_name: StringName) -> void:
    queue_free()
```

### Entity Scripts

Player and enemy scripts follow this pattern:
- `extends CharacterBody2D` for physics entities
- Local players use `move_and_slide()`
- Remote players updated by multiplayer interpolation
- Same script reused for local and remote instances

### Resource Classes

Custom resources extend `Resource`:

```gdscript
class_name PlayerClass extends Resource

@export var display_name: String
@export var stat_multipliers: Dictionary
@export var player_scene: PackedScene
```

### Status Effects

Component-style implementation:
- Base: `src/components/status_effect.gd`
- Buffs: `src/components/buffs/*.gd`
- Debuffs: `src/components/debuffs/*.gd`

Manager ticks effects every frame, refreshes duplicates, removes expired.

## Math and Geometry

### Angle Conversions

```gdscript
var angle_rad := deg_to_rad(angle_deg)
var angle_deg := rad_to_deg(angle_rad)
```

### Vector Operations

```gdscript
var direction := (target_position - position).normalized()
var distance := position.distance_to(target_position)
var point_on_circle := Vector2(cos(angle), sin(angle)) * radius
```

### Clamping and Interpolation

```gdscript
var clamped := clampf(value, min_val, max_val)
var lerped := lerpf(from, to, t)
var vector_lerped := lerp(vec_a, vec_b, t)
```

## Performance Tips

1. Use `@onready` for node references instead of `get_node()` in `_process()`
2. Check `is_equal_approx()` for float comparisons
3. Use `PackedVector2Array` for point collections
4. Pre-calculate values in `_ready()` when possible
5. Use `maxf()` / `minf()` instead of `max()` / `min()` for floats

## Multiplayer Considerations

- Local players: full physics, input handling
- Remote players: no local physics, updated via interpolation
- Use `MultiplayerManager` for network state
- Use `NetworkMessaging` for sending match state
- Authoritative server handles game state

## Scene Organization

- Scenes in `scenes/` directory
- Scripts in `src/` directory (matching subdirectory structure)
- Scene references use `res://` protocol
- Main scene: `res://scenes/ui/auth_menu.tscn`

## Shader Integration

The slime player visuals use:
- `slime_color.gdshader` for color customization
- Shader uniforms for body, outline, iris, eye highlight colors
- Same shader used for lobby previews

## Error Handling

Always validate before operations:

```gdscript
if arc_core.points.size() >= 2:
    # Safe to access [size-2] and [size-1]

if mat != null:
    # Safe to use mat
```

## Naming Conventions

- Private variables: `_snake_case`
- Public/exported: `snake_case`
- Constants: `UPPER_SNAKE_CASE`
- Type suffixes: `PlayerClass`, `PlayerStats`
- Scene files: `snake_case.tscn`
- Script files: `snake_case.gd`

## MCP Integration & Validation

When making edits, always use the Godot MCP server to validate changes:

1. **Avoid hardcoded node paths**: Use `@onready` with proper node references or `unique_name_in_owner` with `%NodeName` syntax instead of hardcoded `$Node/Path` strings
2. **Run the project after every edit**: Use MCP to run the main scene or the specific scene that was edited to catch compilation errors and runtime warnings immediately
3. **Fix errors before proceeding**: Address all compilation errors and warnings reported by the Godot editor before making additional changes
4. **Test interactions**: When editing UI or gameplay systems, use MCP to simulate interactions (hover, click, key presses) and verify behavior
