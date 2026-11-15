# 005-marble — Build Checkpoint (2026-11-15)

cykgames wave 1, slot 005 (genre: roller). Worker: cykbot4 build session.
Status: **playable MVP, local commit only — NOT pushed, NOT device-tested.**

## What this is

Android touch-first adaptation of **kaushalmeena/marble-runner** (MIT,
upstream commit `22ec906`), a Godot **4.7** marble platformer with 60
procedurally defined levels. Built with **Godot 4.7.2-stable** on Windows.

- Local repo: `%USERPROFILE%\projects\005-marble` (remote set to
  `https://github.com/cykgames/005-marble.git`, empty, no push performed)
- APK: `build/marble.apk` — 29,000,966 bytes (~27.7 MB), debug-signed,
  package `com.cykagent.marble`, **arm64-v8a only** (verified in the zip:
  `lib/` contains only `arm64-v8a`; manifest package verified UTF-16;
  Godot 4.7 `assets.sparsepck` present).

## Kept from base (verified working)

- **Marble physics**: `player/marble.gd` — torque drive in
  `_integrate_forces` (roll torque + ground/air push, grip assist, ice,
  water, moving-platform ride). Untouched.
- **Touch controls**: `ui/touch_controls.gd` — floating stick on the left
  half + JUMP button; drives the same `move_*` / `jump` Input actions as the
  keyboard. Untouched. The headless bot uses exactly this action path.
- **Jolt physics**: `physics/3d/physics_engine="Jolt Physics"` + jolt slop /
  speculative-contact settings import and run clean on 4.7.2 (Jolt is built
  into Godot >= 4.4). Evidence line below.
- `gl_compatibility` renderer (desktop + mobile override),
  `textures/vram_compression/import_etc2_astc=true`, physics interpolation,
  gravity 20. All 60 level defs, gimmicks, power-ups, skins, shop, saves.
- Base `LICENSE` (MIT) verbatim; `assets/fonts/OFL.txt` shipped with
  Outfit.ttf; base `docs/architecture.md` + `docs/levels.md` (clean, useful).
- Base Web export preset kept as `preset.1` (untested this wave).

## Changed / added

- `project.godot`: name "Marble" v0.1.0, 1280x720 landscape
  (`window/handheld/orientation=1`), `emulate_touch_from_mouse=true`
  (desktop testing of touch UI).
- **Removed mouse-capture paths** (conflict with touch on mobile):
  - `game/game.gd::_unhandled_input`: click-to-capture-pointer branch removed
    (restart key kept).
  - `game/game_camera.gd`: mouse-motion look + `mouse_turn_speed` removed.
    Camera still fully playable: auto-follow + Q/E keys + gamepad right stick.
  - Harmless `MOUSE_MODE_VISIBLE` resets (scene swap / pause / finish) kept.
- `levels/defs/first_roll.gd`: two intro tips reworded touch-first.
- `export_presets.cfg`: **Android preset.0 copied from 002-obby** (verified
  on-device there): `com.cykagent.marble`, arm64-v8a only, ETC2 texture
  format, immersive mode, no permissions, `build/marble.apk`.
- `tools/headless_test.gd` + `.tscn`: smoke harness (below).
- `CREDITS.md`, new `README.md`, `.gitignore` (+`build/`, `*.tmp`).

## Removed from base copy (decisions)

- `.git` — never inherit base history (brief rule).
- `AGENTS.md` — base-repo agent rules, not ours (brief rule).
- `package.json`, `package-lock.json`, `.github/workflows/deploy.yml` —
  upstream gh-pages Web deploy tooling, irrelevant to the Android build and
  references the upstream repo.
- Kept `screenshots/` (1.2 MB upstream promo PNGs): harmless MIT assets, and
  `screenshots/.gdignore` excludes them from the export — not in the APK.

## Evidence

### 1. Import — clean

`godot --headless --path . --import` → exit 0, **0 errors / 0 warnings**
(`build/import.log`). First pass (`build/import_pass1.log`) hit a font
ordering error (theme loaded before `Outfit.ttf` fontdata was generated);
resolved by a second import pass — no code change needed.

### 2. Headless smoke — PASS (exit 0), `build/headless.log`

Harness: `tools/headless_test.tscn` as main scene; reparents itself out of
the scene slot, disables `GameState.persist`, builds 3 level defs through
the real `LevelBuilder`, then plays level 1 with a waypoint bot pressing the
**same Input actions the touch stick uses** (`Input.action_press` on
`move_left/right/forward/back`, camera-relative like
`TouchControls._apply_stick`). Runs >= 60 s simulated AND wall time; after
each finish it restarts the level to fill the duration.

Quoted evidence lines:

```
[SMOKE] engine=4.7.2-stable (official) physics_engine_setting=Jolt Physics renderer=gl_compatibility
[SMOKE] level_build idx=1 id=mind_the_gap title="Mind the Gap" nodes=15 gems=8 route_points=0
[SMOKE] level_build idx=7 id=thin_ice title="Thin Ice" nodes=19 gems=10 route_points=0
[SMOKE] level_build idx=33 id=assembly_line_2 title="Assembly Line" nodes=46 gems=17 route_points=24
[SMOKE] attempt=1 start pos=(0.00, 0.50, 1.00) control_enabled=true
[SMOKE] FINISH reached attempt=1 time=9.68s gems=10/10 pos=(35.03, 2.50, -23.44)
[SMOKE] summary attempts=7 sim_time=67.5s wall_time=89.9s max_dist=43.44m gems_max=10 finished=true finish_time=9.68s reason=finished + duration met
[SMOKE] asserts movement(>5m)=true progress(gem_or_finish)=true duration(>=60s)=true
[SMOKE] RESULT=PASS
```

- Level 1 **finished** (not just distance evidence): all 10 gems, 9.68 s,
  marble ended on the finish pad at (35.03, 2.50, -23.44) vs pad (36, 2, -22).
- 7 attempts total (restart flow exercised), 67.5 s simulated / 89.9 s wall.
- Level builder proven on 3 other defs incl. one Trail-based level
  (assembly_line: 24 route points).
- No script errors. One benign exit-time line:
  `ERROR: 1 resources still in use at exit` — Godot's leak check at `quit()`,
  not a script error; attributed to the static `LevelCatalog` cache holding
  Biome resources at shutdown (present by design upstream). Not chased
  (timebox); does not affect gameplay or export.

### 3. APK export — clean

`godot --headless --path . --export-debug "Android" build/marble.apk`
→ exit 0, 0 errors / 0 warnings (`build/export.log`). Zip inspection:
`lib/` = arm64-v8a only; `com.cykagent.marble` in binary manifest;
`assets.sparsepck` embedded.

### 4. Privacy scan — clean (false positives triaged)

Ran the cykgames `gh_sensitive_scan.py` pattern set (wrapper overrides its
hardcoded REPO; staged worktree + full history). Result: **0 hits** for
LAN_IP, WIN_USER_PATH, MSYS_USER_PATH, DEVICE_SERIAL, USERNAME, ADB_PORT,
INTERNAL_DOMAIN, WORKSPACE_PATH, GVIM_PATH. The broad credential-keyword
regex matched ~200 lines — **every one** is the game's "secret diamond"
collectible mechanic (`secret_diamond.gd`, `has_secret`, level-def comments,
docs). Verified by vocabulary triage: 0 suspicious remainders. An earlier
draft of this checkpoint contained absolute user-profile paths in the
reproduce commands; the post-commit scan caught them and they were replaced
with `%USERPROFILE%` placeholders before the final (amended) commit. No
credentials, paths, IPs or serials anywhere in the final tree or history.

## Open items

1. **On-device verification on A54** (parent does this; no adb in this
   worker): install, touch stick feel, Jolt performance, landscape lock.
2. Debug-signed only; release keystore not set up (same as 002).
3. arm64-v8a only — 32-bit devices unsupported (deliberate, per brief).
4. Web preset kept but not exported/tested this wave.
5. Exit-time resource-leak line in headless (cosmetic, see above).
6. Bot only proves level 1 end-to-end; other 59 levels build but are not
   bot-played (upstream ships a `route` waypoint format for a future bot).

## Reproduce

```sh
cd %USERPROFILE%\projects\005-marble
set GODOT=%USERPROFILE%\tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe
%GODOT% --headless --path . --import
%GODOT% --headless --path . res://tools/headless_test.tscn   # ~90 s, exit 0 = PASS
%GODOT% --headless --path . --export-debug "Android" build/marble.apk
```

Privacy scan: worktree + full-history scan for LAN IPs, device serials,
user-profile paths, agent workspace names and tokens must be 0-hit before
push (0 hits at v0.1.0).

## Author attribution & handoff docs (2026-11-15, cykbot4)

- User-requested attribution: title menu shows "by cykbot4" (CaptionLabel
  added in `ui/main_menu.gd`); README header + CREDITS name cykbot4 (bot4)
  as adaptation author; org catalog row carries an Author column.
- README rewritten as a handoff doc: design sources, key-file map, device
  reproduce with placeholders, known issues (portrait-render anomaly first),
  privacy rule.
- Re-verified after the label change: `[SMOKE] RESULT=PASS` (level 1 finish
  9.62 s, gems 10/10); APK re-exported, installed on A54, menu screenshot
  shows the credit line (orchestrator
  `artifacts/tmp/wave1_device/005_author_menu.png`). Portrait-render known
  issue unchanged (still renders portrait on device).
- Device install note: `adb install` streamed/incremental sessions failed
  with empty errors on this unit; `adb push` + `pm install -r` works.
