# WhereAmIFacing

An RS3 plugin that draws an arrow on the ground at your character's feet, pointing the way you're facing, snapped to the 8 compass directions (N, NE, E, SE, S, SW, W, NW). Created by **6ing**. Version **1.1.1**.

Part of [6ing's RS3 plugins](https://github.com/6inq/rs3-plugins).

## How to use
1. Enable the plugin. Walk a step and an arrow appears on the ground at your feet.
2. Walk a few steps in different directions the first time. The plugin calibrates itself (see below) and remembers it. After that the arrow follows you even when you turn without moving.
3. Open the settings (gear icon) to change the **arrow colour** to any hue, or hide the ground arrow.
4. Optional: turn on **Show compass window** for a small window with the arrow and the direction as text (N, NE...).

## How it works
The client exposes the character's raw `facing` value, but Jagex hasn't documented its unit or which direction is zero. Rather than guess, WhereAmIFacing **calibrates itself**:
- Characters face the way they walk. On each straight-line step, the plugin records the raw facing value next to the true walking direction (from the tile you moved to).
- It scores every plausible convention against those samples: radians, 2048 units or 16384 units; clockwise or counter-clockwise; any of the four zero directions. It keeps the winner only when that convention explains at least 80% of samples, covers at least 3 directions, and clearly beats every alternative.
- Until then, the arrow shows your **last walking direction**, so it works from the first step.
- The learned convention is saved. **Recalibrate** in the settings clears it if it ever points the wrong way.

## The ground arrow
- It is a real 3D shape in the game world, drawn the same way Tilemarkers draws tiles: a filled arrow in your colour with a dark outline.
- It starts just in front of your feet and reaches about 1.5 tiles out.
- It follows the terrain height, so it lies flat on slopes and stairs instead of floating.
- It is rebuilt only when your tile, direction or colour changes.
- If a client can't draw in the world, the compass window appears instead, so the plugin always shows something.

## Fair play
Display only. It reads your own character's position and facing and draws an arrow. Nothing is automated, and nothing is sent anywhere.

## Layout
```
plugin.json, main.lua     entry point and manifest (requires PrettyUI)
src/core/                 pure logic: compass math, arrow geometry, self-calibration, tracker, store
src/game/world_arrow.lua  ground arrow drawn in the game world (ShapeList)
src/ui/                   optional compass window and settings panel
src/app.lua               reads the player each tick and redraws only when something changes
resources/arrow.png       white north-pointing arrow, tinted to the chosen colour in game
tests/                    Lua tests: every facing convention, noisy samples, the full UI flow
tools/                    build script + arrow image generator
```

## Tests
Install the test dependency:
```bash
python -m pip install lupa
```

Then run the suite:
```bash
python tests/run.py
```

The suite has 51 tests:
- all 8 directions and their boundaries
- calibration recovering **every one of the 24 possible facing conventions** from a short walk
- tolerance for noise (turn lag, facing an NPC mid-walk) and refusal to guess from too little data
- the ground arrow's geometry for every direction
- a full boot of `main.lua` covering the ground arrow (placement, slopes, recolouring, redraw only on change), the optional window, saved calibration and the fallback without world drawing

## Building
```bash
python tools/build.py
```
The output is `dist/where-am-i-facing-1.1.1.zip` (`plugin.json`, `main.lua`, `src/`, `resources/`).

See [CHANGELOG.md](CHANGELOG.md) for what changed in each version.
