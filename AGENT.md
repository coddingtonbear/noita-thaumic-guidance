# Thaumic Guidance — Agent Context

## What This Is

A Noita mod (Steam Workshop ID: 3694371849). Noita is a physics-based roguelite; mods are written in Lua using Noita's own scripting API. This mod is a gamepad-friendly aim assist, forked from ImmortalDamned's original "Aim Assist" mod.

## Features

- **Thaumic Guidance** — redirects projectiles toward the nearest in-cone enemy with line of sight
- **Arcane Identification** — logs the locked-on enemy's name when aim assist fires
- **Warding Glyphs** — draws directional edge indicators pointing at off-screen enemies

All three are runtime-toggleable via mod settings (no restart needed).

## Project Structure

```
init.lua                                  # Mod entry: OnPlayerSpawned, OnWorldPostUpdate
settings.lua                              # Mod settings definitions (standard Noita pattern)
mod.xml                                   # Mod metadata
files/scripts/
  lib/tactic.lua                          # Player entity definition using the Entity/ComponentField system
  lib/utilities.lua                       # Core abstractions + Noita API helpers + math utils
  magic/autoaim_shot.lua                  # Shot callback: targeting algorithm, projectile redirection
  magic/warding_glyphs.lua               # Source callback: off-screen enemy indicator rendering
  magic/warding_glyph.png               # Arrow/indicator sprite
```

## Key Abstractions (utilities.lua + tactic.lua)

The codebase has a lightweight OOP layer on top of the Noita component API:

### `Entity` / `ComponentField`

`Entity` creates a table-metatable-based wrapper so entity components are accessible as named fields:

```lua
Player = Entity{
    controls = ComponentField("ControlsComponent"),
    autoaim  = ComponentField{"LuaComponent", "thaumic_guidance.autoaim", _tags=..., script_shot=...},
}
-- Usage:
local player = Player(entity_id)
player.controls.mAimingVectorNormalized()   -- reads a vector field
player.autoaim._enabled = true              -- sets _enabled on the component
```

- `ComponentField(type)` — gets first component of that type (creates it if a table spec is provided)
- `_` suffix on field access is the "conditional/null-safe" pattern — returns `null` sentinel instead of erroring if component missing
- `_enabled`, `_tags`, `_entity`, etc. are special meta-getters/setters backed by Noita API calls

### `VariableField`, `FileField`, `SerializedField`, `CombinedField`, `NumericField`

Additional field types for `VariableStorageComponent`-backed values, mod text files, serialized tables, etc.

### `widget_list_begin` / `widget_list_insert` / `widget_list_end`

A deferred GUI rendering system. Collects `(fn, args...)` tuples, then renders them in z-order. Used by warding glyphs to ensure correct draw order.

### `window_new` / `widget_list_id`

Stable GUI widget IDs derived from source line number + call count (using LuaJIT's `jit.util.funcinfo`).

### Math / utility helpers

- `get_direction(x1,y1,x2,y2)` — angle in radians (from Noita's `data/scripts/lib/utilities.lua`)
- `get_direction_difference(a,b)` — signed angular difference
- `get_distance(x1,y1,x2,y2)` — Euclidean distance
- `get_pos_on_screen(x,y,gui)` — world → GUI screen space conversion
- `get_pos_in_world(x,y,gui)` — GUI screen → world space conversion
- `lerp`, `lerp_angle`, `lerp_angle_vec`, `warp`, `clamp` — standard math
- `table.find`, `table.filter`, `table.iterate` — functional list helpers
- `serialize` / `deserialize` — round-trip Lua values through strings

## How the Mod Works

### Aim Assist (`autoaim_shot.lua`)

- Attached to the player as a `LuaComponent` with `script_shot` — fires on every shot
- Filters enemies by: not the shooter, hostile herd relation, within aiming cone, has line of sight
- Cone angle is proportional to gamepad aim vector magnitude (`mAimingVectorNormalized`): full analog → π/4, digital/keyboard → 0 (disabled)
- Picks best enemy by minimizing `distance × angular_offset`
- Probes 5 body points per enemy (center, head, feet, left, right) for LOS via `RaytraceSurfaces`
- Redirects via `GameShootProjectile`; forces `lob_min/lob_max ≥ 1` to enable arc redirection
- Skips projectiles that have both `PhysicsBodyComponent` and `ItemComponent` (thrown items)

### Warding Glyphs (`warding_glyphs.lua`)

- Attached to the player as a `LuaComponent` with `script_source_file` — runs each frame
- Recalculates enemy positions every 15 frames (cached in `cached_indicators`)
- Filters: visible (fog of war < 200), not invisible, hostile, off-screen
- Edge placement: ray-intersection of the player→enemy direction vector with the screen boundary rectangle (with `EDGE_MARGIN` and sprite half-size padding)
- Renders up to 16 indicators sorted by distance; LOS enemies are bright orange-red, occluded are dim blue-gray

### Settings

Setting IDs: `thaumic_guidance.enabled`, `thaumic_guidance.arcane_identification`, `thaumic_guidance.warding_glyphs`. All `MOD_SETTING_SCOPE_RUNTIME`.

`OnWorldPostUpdate` in `init.lua` polls settings each frame and propagates changes to the LuaComponents' `_enabled` field.

## Noita API Notes

- `dofile_once(path)` — load a file exactly once per game session; paths are relative to the Noita data root, not the mod folder. Mod files use `mods/thaumic_guidance/...`; engine files use `data/...`
- `EntityGetWithTag("enemy")` — all active enemies
- `EntityGetHerdRelationSafe(a, b)` — `< 100` means hostile
- `GetUpdatedComponentID()` — in a `script_shot` callback, returns the LuaComponent ID
- `GetUpdatedEntityID()` — in a `script_source_file` callback, returns the entity ID
- `GameGetFogOfWar(x, y)` — 0 = fully visible, higher = more obscured
- `IsInvisible(entity)` — true if entity has invisibility effect
- `RaytraceSurfaces(x1,y1,x2,y2)` — returns true if terrain blocks the ray

## Project Descriptions

The mod's user-facing description lives in two places that must be kept in sync when features or behavior change:

### `README.md`
Markdown. Audience: developers and technically-minded users browsing GitHub/the repo. Includes:
- Feature descriptions
- Installation instructions (Steam Workshop and manual clone)
- Settings table
- Project structure overview
- Credits

### `workshop.xml` — `description` attribute
Steam Workshop markup (BBCode-like: `[h2]`, `[list]`, `[*]`, `[b]`, `[i]`, `[url=...]`, `&quot;` for quotes inside the XML attribute). Audience: players browsing the Steam Workshop page. Includes only:
- Short intro paragraph
- Feature list
- Brief note that features are on by default and toggleable in Settings
- Credits with a link to the original mod

**What to omit from `workshop.xml`**: installation instructions (Steam handles that), project structure, anything developer-facing.

**Format note**: the `description` is an XML attribute value, so double-quotes inside it must be escaped as `&quot;`.

## Deployment

The mod folder must be named `thaumic_guidance`:
- Linux: `~/.steam/steam/steamapps/common/Noita/mods/thaumic_guidance`
- Windows: `C:\Program Files (x86)\Steam\steamapps\common\Noita\mods\thaumic_guidance`

Live iteration: edit files in the repo, then reload the mod in Noita (or restart the run). Noita re-executes Lua on each world load.
