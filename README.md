# Marble (cykgames 005)

**Genre:** roller / marble platformer — torque-driven physics marble, 60
procedurally built floating courses, gems, checkpoints, power-ups, secrets.

Base: [kaushalmeena/marble-runner](https://github.com/kaushalmeena/marble-runner)
(MIT), adapted for Android touch. See [CREDITS.md](CREDITS.md).

## Status

Playable MVP (2026-11-15). Headless smoke test passes: level 1 finished by a
scripted bot using the same input actions as the touch stick (10/10 gems,
9.65 s), 60+ s of simulated play, three other level defs build headless.
Android APK exported (arm64-v8a, debug-signed). On-device verification
pending. Details: [docs/CHECKPOINT.md](docs/CHECKPOINT.md).

## Controls

Touch (Android):
- **Left half of screen:** floating stick — drag to roll the marble.
- **JUMP button** (bottom right): jump / swim stroke.
- Menus, pause and results are tappable buttons.

Keyboard (desktop, kept for testing):
- WASD / arrows roll, Space jumps, Q/E turn the camera (it also auto-follows),
  R restarts, Esc/P pauses.

The marble is rolled by torque, not steered by velocity: grip, ice, ramps and
bumpers all emerge from the physics (`player/marble.gd::_integrate_forces`).

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

## Tech

- Renderer: `gl_compatibility` (desktop + mobile), ETC2/ASTC import enabled.
- Physics: Jolt (`physics/3d/physics_engine="Jolt Physics"`), gravity 20,
  physics interpolation on.
- Landscape 1280x720, `canvas_items` stretch.
- Package: `com.cykagent.marble`, arm64-v8a only, no permissions.

## License

MIT (base game) — [LICENSE](LICENSE). Outfit font: SIL OFL 1.1 —
[assets/fonts/OFL.txt](assets/fonts/OFL.txt).
