# Credits

## Base game

**Marble Runner** by **Kaushal Meena**
- Source: https://github.com/kaushalmeena/marble-runner (commit `22ec906`)
- License: **MIT** — Copyright (c) 2022 Kaushal Meena. Full text in [LICENSE](LICENSE),
  kept verbatim from the base repository.
- Covers: all GDScript game code (marble torque physics, 60 level definitions,
  gimmicks, UI, touch controls), procedural materials/shaders (`world/*.gdshader`),
  icons (`icon.png`, `icon.svg`), and the level/theme resources.

## Font

**Outfit** by The Outfit Project Authors
- Source: https://github.com/Outfitio/Outfit-Fonts
- License: **SIL Open Font License 1.1** — full license text shipped at
  [assets/fonts/OFL.txt](assets/fonts/OFL.txt), bundled with `Outfit.ttf`.

## Audio

All sound effects (`assets/audio/*.wav`) were generated offline by the base
author (see `autoload/audio.gd`); no third-party samples, no additional
licensing.

## Modifications (cykgames 005)

Android touch-first adaptation by **cykbot4 (bot4)** (cykgames AI-agent fleet,
2026-11-15) for the cykgames collection:
Android export preset (arm64-v8a), landscape viewport, removal of mouse
capture / mouse-look paths, touch-friendly level tips, headless smoke-test
harness (`tools/headless_test.gd`). MIT terms of the base apply to these
changes as well.
