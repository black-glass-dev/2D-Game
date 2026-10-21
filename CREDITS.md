# Operation Redline — Asset Credits

## Original project assets

The following assets were authored specifically for this repository and are included under the repository's project licence:

- `tools/generate_assets.py` and every texture it writes in `assets/textures/`
  - seamless desert sand, concrete, corrugated/weathered metal, crate paint, rock strata, asphalt and normal detail maps
- Runtime visual kits in `scripts/world_builder.gd`, including terrain, structures, weathering dressing, distant mesas, signs, lamps and atmospheric cards
- Runtime Raider character kit in `scripts/enemy.gd`
- Runtime rifle, pistol, hands and combat effect kits in `scripts/rifle.gd`, `scripts/pistol.gd` and `scripts/weapon_effects.gd`
- Generated game sound effects already stored under `assets/audio/`
- `assets/audio/outpost_watch.wav`, an original non-lyrical 16-second tactical music loop synthesized by `tools/generate_music.py`; it has no sampled audio, commercial-game material, or third-party audio content. Its reproducible source, file hash, format, and Music-bus use are registered in `assets_manifest.json`.
- Shared menu UI icon source files in `assets/ui/icons/`
- `assets/ui/menu_desert_outpost.png`, an original project-commissioned, AI-assisted pixel-art illustration of the year-2000 Desert Outpost. It contains no third-party character, weapon, building, logo, HUD, text, or commercial-game material; its file hash and dimensions are registered in `assets_manifest.json`.

## Third-party assets

### Kenney — CC0 1.0 Universal

The project vendors a deliberately small set of conventional low-poly models from the Kenney asset library, credited voluntarily to **Kenney / kenney.nl**. They are used for player/raider conventional weapon details, outpost wall/garage/roof modules, barriers, fuel drums, sheet-metal repairs and desert rocks.

- **License:** [Creative Commons Zero 1.0 Universal (CC0)](https://creativecommons.org/publicdomain/zero/1.0/)
- **Auditable source/pin:** `shorepine/kenney` commit `3694c6879e487c108f55677be7dd2ca75b07cc3b`
- **Vendored subset and exact source paths:** [`assets/third_party/kenney_cc0/README.md`](assets/third_party/kenney_cc0/README.md)

Only real-world/period-appropriate assets were selected. No Kenney sci-fi, space, blaster, alien, laser, commercial-game, branded, or copied material is part of this project. Godot's built-in primitives, materials, fonts and particle renderer remain engine features rather than redistributed art assets.

### KayKit / Kay Lousberg — CC0 1.0 Universal

The project vendors a trimmed, rigged low-poly **KayKit Adventurers** human model as the base geometry and animation source for hostile smugglers. The CC0 derivative retains only the two-handed aim/shoot and walk clips; source knife, crossbow, throwable props, cape and exaggerated source head are removed before import. The game applies its own restrained field clothing, tactical kit and conventional carbine. No medieval source accessory, KayKit logo, map or commercial-game material is used.

- **License:** [Creative Commons Zero 1.0 Universal (CC0)](https://creativecommons.org/publicdomain/zero/1.0/)
- **Auditable source/pin:** `KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0` commit `672074b73ba276876a19e8816ecdc5241817ab47`
- **Vendored subset and exact source paths:** [`assets/third_party/kaykit_cc0/README.md`](assets/third_party/kaykit_cc0/README.md)

### Noto Sans Bengali — SIL Open Font License 1.1

The player-facing localized UI bundles Noto Sans Bengali Regular and SemiBold for consistent Bengali and Latin glyph coverage.

- **Copyright holder:** The Noto Project Authors
- **License:** [SIL Open Font License 1.1](https://openfontlicense.org/)
- **Auditable source/pin:** `notofonts/noto-fonts` commit `ffebf8c1ee449e544955a7e813c54f9b73848eac`
- **Vendored files, source paths, and license:** [`assets/third_party/noto_sans_bengali_ofl/README.md`](assets/third_party/noto_sans_bengali_ofl/README.md)
