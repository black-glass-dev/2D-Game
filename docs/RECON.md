# Operation Redline — Recon Report

**তারিখ:** 2026-10-14 (Asia/Dhaka)

**পর্ব:** §0 Recon — কোনো gameplay বা scene code পরিবর্তন করা হয়নি

**যাচাইকরণ কমান্ড:** `npm run test:gdscript`, `python3 tools/validate_project.py`, `./scripts/run_native_tests.sh`

## 1. যাচাইকৃত বেসলাইন

| পরীক্ষা | ফলাফল | প্রমাণ |
| --- | --- | --- |
| GDScript static analysis | PASS — 13 scripts, 0 errors, 0 warnings | `npm run test:gdscript` output |
| Resource consistency | PASS — 30 `res://` links, 4টি 128×128 texture | `python3 tools/validate_project.py` output |
| Native wave core | PASS — 3 waves, 27 spawns, completion state | `./scripts/run_native_tests.sh` output |
| Git whitespace scan | কোনো diff-report নেই | `git diff --check` |

এই ফলাফলগুলো source-level gate; এগুলো real Godot editor launch অথবা physical Android playtest-এর বিকল্প নয়।

## 2. Engine, renderer এবং project configuration

- **Engine target:** Godot `4.7` (`project.godot` > `config/features`)।
- **Renderer:** `gl_compatibility` desktop ও mobile — Forward+ বা Godot Mobile renderer নয়। বর্তমান project setting-এ nearest texture filtering এবং ETC2/ASTC VRAM compression সক্রিয়।
- **Window/orientation:** design viewport `1280×720`, canvas-items stretch, expand aspect, landscape (`handheld/orientation=0`)।
- **Main scene:** `res://scenes/Main.tscn`। scene-এ একটি `OperationRedline: Node3D`; runtime content `scripts/main.gd` থেকে তৈরি হয়।
- **Physics layers:** conventionটি code-এ পাওয়া গেছে: world/structural collision layer **1**, player **2** (`OutpostPlayer`), Raider **4** (`Raider`), headshot `Area3D` **8**। অস্ত্র raycast mask `13` ব্যবহার করে world + Raider + headshot query করার জন্য।
- **Input Map:** `project.godot`-এ কোনো `[input]` section নেই। movement এবং action keys বর্তমানে সরাসরি `Input.is_key_pressed()`/keycode দিয়ে `player.gd`-তে পড়া হয়; rebinding বা gamepad abstraction এখনো নেই।
- **Autoload:** `project.godot`-এ কোনো `[autoload]` section নেই।
- **Localization:** কোনো `TranslationServer`, `.translation`, CSV localization বা locale setting পাওয়া যায়নি। HUD strings বর্তমানে `main.gd`-তে hard-coded English।

## 3. Export/build inventory

| লক্ষ্য | বর্তমান অবস্থা | ফাইল |
| --- | --- | --- |
| Android Debug | arm64-v8a + x86_64, signed debug export | `export_presets.cfg` |
| Package | `com.operationredline.outpost` | `export_presets.cfg` |
| Desktop export preset | পাওয়া যায়নি | `export_presets.cfg` |
| CI APK lane | source tests, Godot import/export, headless launch, renderer capture, APK/signature check, emulator attempt | `.github/workflows/android-apk.yml` |

CI-তে persistent debug keystore এবং monotonically-increasing candidate version path আছে। Hosted emulator boot timeout একটি জানা infra-risk; এটি gameplay pass/fail-এর সমতুল্য নয়।

## 4. Runtime scene tree এবং বর্তমান game systems

### Runtime tree

`Main.tscn` → `OperationRedline (Node3D)` → runtime-created children:

- `WorldBuilder.build(self)` → environment, lighting, terrain, collision floor, outpost, imported conventional CC0 dressing, particles এবং cinematic presentation layer
- `PerformanceGovernor`
- `Player (OutpostPlayer)` → Head → Recoil pivot → PlayerCamera → Rifle/Pistol
- `SurvivalDirector`
- `Tactical HUD (CanvasLayer)` → header, VITALS, wave/score/ammo labels, reticle, radar, customizable touch controls, HUD editor, settings panel এবং loading splash
- per-wave `Raider` instances এবং pooled weapon effects

### Player controller

`res://scripts/player.gd`-এর `OutpostPlayer` একটি `CharacterBody3D` motor:

- WASD + mouse development controls; touch joystick + right-side touch-look
- walk/sprint/crouch/slide/jump/coyote time/jump buffer/mantle
- camera recoil, movement bob, ADS FOV tween, health regeneration, damage/down এবং timed redeploy
- hard-coded desktop actions: Space jump, C crouch, Q swap, Esc releases mouse; current Esc path pause menu নয়

### HUD এবং touch controls

`res://scripts/main.gd` runtime HUD-তে পাওয়া গেছে:

- **VITALS**, health bar, **WAVE**, **SCORE**, weapon/ammo, accuracy, status/alert, hit marker, damage direction, radar
- touch controls: joystick, **FIRE**, **SINGLE/AUTO**, **AIM**, **RELOAD**, **JUMP**, **CROUCH**, **SWAP**, plus **HUD** editor and **SET** settings button
- movable/resizable HUD layout: `user://operation_redline_hud.cfg`
- existing settings: look sensitivity, aim assist, screen effects, AUTO/LOW/MEDIUM/HIGH/ULTRA quality tier এবং SINGLE/AUTO fire mode

বর্তমান settings panel ছোট runtime panel; full §A3 graphics/audio/accessibility/rebind/localization scope এখনো নেই।

### Weapons, enemies এবং waves

- `rifle.gd` / `pistol.gd`: hitscan, ammo/reserve/reload, recoil, spread, aim assist, muzzle/impact/casing effects।
- `enemy.gd`: `CharacterBody3D` Raider, LOS ray, damage/headshot, simple locomotion, conventional CC0-derived visual rig।
- `raider_tactics.gd`: deterministic approach/strafe/flank/cover selection, pre-authored fixed cover points।
- `wave_director.gd`: fixed three-wave schedule **6 / 9 / 12**, 4-second intermission; main map-specific নয় এমন spawn source নেই।
- C++ `OperationCore` mirrors the fixed 3-wave pacing contract and has unit tests, but is not yet an active GDExtension in the Godot runtime.

### Audio

SFX assets for rifle/pistol/reload/landing exist under `assets/audio/`. Audio bus layout, music service, ambient menu soundtrack, focus-loss mute এবং pooled ambience service এখনো পাওয়া যায়নি।

## 5. Current Desert Outpost (`MP_DS_01` candidate)

বর্তমান desert map আলাদা `.tscn` map scene নয়; এটি `WorldBuilder`-এর procedural runtime build:

- **Source path:** `res://scripts/world_builder.gd`, called from `res://scripts/main.gd`.
- **Walkable/collision footprint:** centred flat collision floor, approximately `x/z −64 … +64` (128 m square).
- **Visual terrain:** same approximate `−64 … +64` extent; terrain is cosmetic while flat collision remains authority.
- **Outpost perimeter dressing:** north/west/east/south edges roughly at `±54 m`; main buildings, watchtower, depot, fuel yard, checkpoint and cover lie within it.
- **Player start:** `(0, 0.12, 13)`.
- **Raider spawn pattern:** eight fixed perimeter/lane points around approximately `x ±44–48`, `z ±38–47`, plus deterministic small lateral jitter in `main.gd`.
- **Current map risk:** map data, spawn topology, cover points, minimap building rectangles, HUD objectives and visual collision are distributed across `main.gd`, `world_builder.gd`, `raider_tactics.gd`, and `tactical_radar.gd`; this must be wrapped behind `MapData` without silently changing Desert behaviour.

## 6. Repository and folder inventory

```text
assets/                 textures, audio, shaders, UI icon, curated CC0 third-party subset
scenes/Main.tscn        current minimal startup scene
scripts/                player, combat, AI, waves, world builder, HUD/runtime settings
a native/               portable C++20 survival core and tests
tools/                  static analysis, asset generation, validation, renderer capture
docs/                   current plan and test report
screenshots/            genuine before/after renderer evidence
.github/workflows/      Android export/capture/release pipeline
```

Asset inventory during Recon: 40 files under `assets/` (~3.45 MiB source payload); 11 GLB files, 19 PNG files, 4 WAV files, 2 shaders. Existing CC0 provenance is recorded in `CREDITS.md` and vendor READMEs.

## 7. Rooftop Highrise authoritative reference status

- The supplied top-down map diagram was visible in the task context and its zone logic matches the text specification: roof A/B/C, two lightwell gaps, bridges, office and lobby circulation, helipad, safe room, breach and wave routes.
- The injected attachment path announced by the interface was not accessible from this workspace at Recon time, therefore no binary was copied to `docs/level_design/rooftop_highrise_map.png` and no hash can honestly be claimed.
- এটি M4 graybox-এর blocker: §B2 coordinate appendix এবং image binary দুটিই বর্তমান checkout-এ অনুপস্থিত। দুটো source পাওয়া গেলে `docs/HIGHRISE_GRAYBOX_INPUTS.md`-এর schema-2, SHA-256-bound packet অনুযায়ী stage করতে হবে; কোনো assumption coordinate-এর বিকল্প হতে পারবে না।

## 8. Risk register and mandatory registration before touching files

| Risk | Why it can break | Mandatory protection before edit |
| --- | --- | --- |
| `scripts/main.gd` | Owns startup, world construction, HUD, combat wiring, respawn and fixed desert spawns in one large runtime script | Create a bootable baseline commit; migrate via adapters/facade rather than rewrite in one pass; run source/native checks after each batch |
| `scripts/player.gd` | Direct keyboard/touch paths, camera and movement state are coupled | Introduce `InputService` behind preserved public methods; test touch regions and keyboard fallback before replacing direct reads |
| `scripts/world_builder.gd` | Current playable desert collision/visual map is procedural and tightly coupled to performance tiers | Leave `WorldBuilder.build()` as the Desert adapter during A; move only map metadata/configuration first |
| `scripts/wave_director.gd` + `native/` | Fixed 3-wave contract is tested; MapData schedule needs an extension without breaking old tests | Keep default `6/9/12` profile byte-for-byte behaviour; add new map profile layer with explicit unit tests |
| `scripts/tactical_radar.gd` | Hard-coded building/objective coordinates would be false for a second map | Add map-aware radar data only after registry exists; retain Desert defaults as fallback |
| `scripts/game_settings.gd` | Existing `user://operation_redline_settings.cfg` contains user preferences | Add schema version and migration; never discard old keys; backup/migrate atomically |
| `project.godot` | Main scene, renderer and input/autoload registration determine whether project boots | Add autoloads/input entries incrementally; validate with real headless launch before each commit |
| `.github/workflows/android-apk.yml` | Can publish releases and push evidence back to branch | Change only after source tests pass; test YAML and keep signing/package identifiers unchanged |
| Git baseline | Current Git index lists only `README.md` while the gameplay project appears as untracked workspace content | M0 must inventory/hash the untouched tree and establish a reviewed baseline commit before functional edits; do not stage generated caches/APKs/node_modules |

## 9. Recon conclusion

The existing desert survival game is a working runtime-built prototype with stable automated source/native gates and a reusable visual vocabulary. It is **not yet** menu/state-machine/data-driven-map/localized architecture. Deliverable A therefore must establish services and wrap the desert map before Deliverable B introduces multi-floor navigation, new traversal and map-specific waves. This avoids breaking the user’s explicit requirement that the current desert map remain playable after every commit.
