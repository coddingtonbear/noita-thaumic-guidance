# Thaumic Guidance

Gamepad-friendly aim assist mod for Noita — a fork of the original Aim Assist mod, fixed and improved.

When you fire a projectile, Thaumic Guidance automatically steers it toward the nearest valid enemy within a targeting cone. It checks line of sight, probes multiple points on each enemy's body, and picks the best available aim point so your shots land even on a controller.

## Features

- **Aim assist** — redirects projectiles toward enemies within a targeting cone, prioritizing by distance and angular alignment
- **Arcane Identification** — optionally prints the locked-on enemy's name to the game log ("Thaumic sigil bound to [enemy]!")

## Installation

1. Clone this repository into Noita's mods directory, naming the folder `thaumic_guidance`:
   - **Linux (Steam):** `~/.steam/steam/steamapps/common/Noita/mods/thaumic_guidance`
   - **Windows (Steam):** `C:\Program Files (x86)\Steam\steamapps\common\Noita\mods\thaumic_guidance`
2. Launch Noita and enable **Thaumic Guidance** in the Mods menu.

The mod activates automatically when a player spawns. You will see a message reading "Thaumic sigils awakened" in the lower-left corner game log if this is enabled, and "Thaumic sigils dormant" if disabled.

## Settings

Both settings can be changed at runtime from the mod settings panel without restarting.

| Setting | Default | Description |
|---|---|---|
| Enabled | On | Toggle aim assist on or off |
| Arcane Identification | On | Show targeted enemy names in the game log |

## Project Structure

```
init.lua                          # Mod lifecycle — player spawn, world updates, enabled/disabled state
settings.lua                      # Runtime settings definitions
mod.xml                           # Mod name and description
files/scripts/
  magic/autoaim_shot.lua          # Core targeting algorithm and projectile redirection
  lib/tactic.lua                  # Player entity abstraction and LuaComponent setup
  lib/utilities.lua               # Entity/Component helpers, math utilities, Lua extensions
```

## Credits

Based on the original [Aim Assist](https://steamcommunity.com/sharedfiles/filedetails/?id=3613890248) mod for Noita.
