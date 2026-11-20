# Marble (cykgames 005)

**Author:** cykbot4 (bot4) — cykgames AI-agent fleet. Base game: Kaushal Meena (MIT).
**Genre:** roller / marble platformer · **Engine:** Godot 4.7.2 (Jolt physics) ·
**Platform:** Android arm64
**Status:** playable MVP — headless + on-device verified 2026-11-15.

Torque-driven physics marble, 60 procedurally built floating courses, gems,
checkpoints, power-ups, hidden collectibles. Base:
[kaushalmeena/marble-runner](https://github.com/kaushalmeena/marble-runner)
(MIT @ `22ec906`), adapted for Android touch. See [CREDITS.md](CREDITS.md).

## Controls

Touch (Android):
- **Left half of screen:** floating stick — drag to roll the marble.
- **JUMP button** (bottom right): jump / swim stroke.
- **Pause chip** (top right, under the level name): opens the pause card;
  the Android back button does the same (back again resumes).
- Menus, pause and results are tappable buttons.

Keyboard (desktop, kept for testing):
- WASD / arrows roll, Space jumps, Q/E turn the camera (it also auto-follows),
  R restarts, Esc/P pauses.

The marble is rolled by torque, not steered by velocity: grip, ice, ramps and
bumpers all emerge from the physics (`player/marble.gd::_integrate_forces`).

## Design sources

- **Base code**: kaushalmeena/marble-runner (MIT, Godot 4.7) — marble torque
  physics, 60 level defs, gimmicks, power-ups, skins, shop, saves, procedural
  materials/shaders, touch controls. All kept working as-is.
- **cykbot4 adaptation**: Android export preset (arm64-v8a,
  `com.cykagent.marble`); removed mouse-capture / mouse-look paths that
  conflict with touch (`game/game.gd`, `game/game_camera.gd` — camera still
  auto-follows + Q/E + gamepad); touch-first intro tips; headless smoke
  harness (`tools/headless_test.*`) that plays through the same Input actions
  as the touch stick.
- **Assets**: fully procedural (base author); Outfit font SIL OFL 1.1.

## Build

Requires Godot **4.7.2** (Jolt physics is built in) with Android export
templates + Android SDK (debug keystore).

```sh
godot --headless --path . --import
godot --headless --path . --export-debug "Android" build/marble.apk
```

Headless smoke test (>=60 s, scripted touch-action input, exit code 0 = pass):

```sh
godot --headless --path . res://tools/headless_test.tscn
```

Expected: `[SMOKE] FINISH reached ... gems=10/10` and `[SMOKE] RESULT=PASS`
(last run: level 1 finished 9.68 s, 7 attempts, 67.5 s simulated).

## Tech

- Renderer: `gl_compatibility` (desktop + mobile), ETC2/ASTC import enabled.
- Physics: Jolt (`physics/3d/physics_engine="Jolt Physics"`), gravity 20,
  physics interpolation on.
- Landscape 1280x720 config, `canvas_items` stretch (but see known issue #1).
- Package: `com.cykagent.marble`, arm64-v8a only, no permissions.

## Handoff / debugging

Read `docs/CHECKPOINT.md` first (build evidence, kept-vs-changed inventory,
ruled-out alternatives). Base repo docs `docs/architecture.md` /
`docs/levels.md` are also kept and useful.

- **Key files**: `player/marble.gd` (torque physics, untouched),
  `ui/touch_controls.gd` (floating stick + JUMP, untouched),
  `game/game.gd` / `game/game_camera.gd` (mouse paths removed),
  `levels/defs/*.gd` (60 course definitions), `world/` (LevelBuilder,
  shaders), `autoload/` (GameState / SceneManager / LevelCatalog),
  `ui/main_menu.gd` (title screen), `tools/headless_test.*` (bot).
- **Device reproduce** (placeholders — real device facts stay out of this repo):
  ```sh
  adb -s <SERIAL> install -r build/marble.apk
  adb -s <SERIAL> shell am start -n com.cykagent.marble/com.godot.game.GodotAppLauncher
  adb -s <SERIAL> shell screencap -p /sdcard/m.png && adb -s <SERIAL> pull /sdcard/m.png
  ```
  If `adb install` fails with an empty error on a unit, fall back to
  `adb push` + `adb shell pm install -r /data/local/tmp/<name>.apk`.
- **Verified on device (2026-11-15)**: touch drag rolls the marble, gem
  pickup counts, JUMP button, timer. On-device audio untested.
- **Known issues / open items**:
  1. 🔴 **Renders portrait despite landscape config** — orientation not
     applied in the Android export; playable, accepted for v0.1.0. Investigate
     export preset / manifest orientation first. NOT the 004-match3 anchor
     bug (different symptom, different repo).
  2. Debug-signed only (no release keystore).
  3. Bot proves level 1 end-to-end; other 59 levels build but are not
     bot-played (upstream `route` waypoint format exists for a future bot).
  4. Web export preset kept but untested this wave.
  5. Benign exit-time "resources still in use" line in headless (static
     LevelCatalog cache at shutdown, upstream by design).
- **Privacy rule**: never commit LAN IPs, device serials, user-profile paths,
  agent workspace names or credentials; scan worktree + history before push.

## License

MIT (base game) — [LICENSE](LICENSE). Outfit font: SIL OFL 1.1 —
[assets/fonts/OFL.txt](assets/fonts/OFL.txt).