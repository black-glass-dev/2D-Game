# Changelog

All notable production changes are documented here.

## Unreleased

### Added

- Production Recon report, M0–M6 plan, baseline audit, progress board, task board, decision log, risk register, QA report, asset import log, blocked-asset register, and initial asset-manifest schema.
- Additive global service contracts for game state, threaded scene loading, versioned settings/save data, map registry, input actions, audio buses, and localization selection.
- `RedlineMapData` plus `MP_DS_01` data resource for the existing Desert Outpost.
- Initial English/Bengali CSV localization catalog.
- `Boot.tscn` and a responsive Boot → Splash → Menu → Map Select → Loading shell that dynamically reads `MapRegistry` and hands off through `SceneLoader`.
- Noto Sans Bengali Regular/SemiBold under SIL OFL 1.1 with pinned source, copied license, and SHA-256 evidence.
- Shared Redline theme and original play, settings, back, and lock SVG source icons.
- Reusable five-section settings menu covering graphics, audio, controls, accessibility, and other preferences, including automatic persistence and reset confirmation.
- `MP_RF_02` Rooftop Highrise metadata-only map resource, a locked/coming-soon Map Select card, tactical detail panel, and pre-deployment difficulty/mode session selection state.
- State-authoritative gameplay pause overlay with touch PAUSE target, resume, shared five-section settings, restart, map-select, and desktop-quit routes; localized English/Bengali pause copy.
- Normal-Boot pause lifecycle verifier plus Xvfb renderer capture of the pause overlay and Bengali pause-settings surface.
- Per-map durable operation records for best score and furthest wave, a localized end-of-operation summary (score, wave, accuracy, best record), and Map Select record display.
- Normal-Boot `--verify-result-flow` harness that validates mission-complete state, result panel creation, and SaveService score/wave round-trip.
- SFX routing for rifle, pistol, reload, and landing audio; UI-bus confirmation feedback for menus/settings; and a Master-volume-safe focus mute/restore policy.
- Normal-Boot `--verify-audio-flow` harness covering bus availability, focus mute/restore, combat/landing SFX assignment, and UI feedback routing.
- Live accessibility adapters: reduced camera bob/recoil/landing motion, colorblind-safe HUD palettes, preference-gated floating damage numbers, haptics enforcement, and a configurable gamepad deadzone.
- Named gameplay-action consumption in the Desert player for keyboard/gamepad movement, fire, jump, crouch, weapon swap, reload, aim, and pause; visible touch controls remain the only touchscreen fire route.
- Normal-Boot `--verify-input-accessibility-flow` harness for named gamepad bindings and the live reduced-motion, palette, damage-number, and sound-caption contracts.
- Localized tactical sound captions for rifle fire, pistol fire, reload, and landing, controlled by the existing subtitles preference.
- Normal-Boot `--verify-back-flow` coverage for Android Back from Splash, keyboard Escape from Settings, and controller B from Map Select; pause regression now drives Android's actual Back notification when leaving shared settings and resuming.

### Changed

- `project.godot` now boots `Boot.tscn` and registers the foundation services as autoloads; `LocalizationService` loads the reviewed CSV catalog at runtime into Godot Translation resources without committing generated import artifacts.
- `Main.tscn` remains directly runnable; it now marks the global game state as Playing when the legacy Desert runtime takes ownership after loading.
- Existing Desert gameplay, direct touch/keyboard input, runtime world builder, Android package/signing, and current HUD remain intact during the boot-flow migration.
- Settings changes now synchronize quality tier, look sensitivity, aim assist, fire mode, and screen-effect compatibility values to the legacy Desert settings file for the next map hand-off; audio bus volumes and live accessibility adapters apply immediately.
- The graphics capture path can now instantiate the real Player without project autoloads, preserving renderer evidence alongside the new deadzone preference.
