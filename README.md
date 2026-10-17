# WhereAmIFacing

An RS3 plugin that shows which way your character is facing, as an arrow and an 8-point compass direction (N, NE, E, SE, S, SW, W, NW). Created by **6ing**. Version **1.0.0**. Free.

Part of [6ing's RS3 plugins](https://github.com/6inq/rs3-plugins).

## How to use
1. Enable the plugin. A small **Facing** window appears; drag it wherever you like.
2. Walk a few steps in different directions the first time. The plugin calibrates itself (see below) and remembers it.
3. Open the settings (gear icon) to change the **arrow colour** to any hue, hide the direction text, or hide the compass.

Closed the window with its X? Turn **Show compass** back on in the settings.

## How it works
The client exposes the character's raw `facing` value, but Jagex hasn't documented its unit or which direction is zero. Rather than guess, WhereAmIFacing **calibrates itself**:
- Characters face the way they walk. On each straight-line step, the plugin records the raw facing value next to the true walking direction (from the tile you moved to).
- It scores every plausible convention against those samples: radians, 2048 units or 16384 units; clockwise or counter-clockwise; any of the four zero directions. It keeps the winner only when that convention explains at least 80% of samples, covers at least 3 directions, and clearly beats every alternative.
- Until then, the arrow shows your **last walking direction**, so it works from the first step.
- The learned convention is saved. **Recalibrate** in the settings clears it if it ever points the wrong way.

## Fair play
Display only. It reads your own character's position and facing and draws an arrow. Nothing is automated, and nothing is sent anywhere.

## Layout
```
plugin.json, main.lua     entry point and manifest (requires PrettyUI)
src/core/                 pure logic: compass math, self-calibration, tracker, store
src/ui/                   compass window and settings panel
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

The suite has 40 tests:
- all 8 directions and their boundaries
- calibration recovering **every one of the 24 possible facing conventions** from a short walk
- tolerance for noise (turn lag, facing an NPC mid-walk) and refusal to guess from too little data
- a full boot of `main.lua` covering arrow rotation, colour changes, saved calibration, and close/reopen

## Building
```bash
python tools/build.py
```
The output is `dist/where-am-i-facing-1.0.0.zip` (`plugin.json`, `main.lua`, `src/`, `resources/`).
