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

### Changed

- `project.godot` now boots `Boot.tscn` and registers the foundation services as autoloads; `LocalizationService` loads the reviewed CSV catalog at runtime into Godot Translation resources without committing generated import artifacts.
- `Main.tscn` remains directly runnable; it now marks the global game state as Playing when the legacy Desert runtime takes ownership after loading.
- Existing Desert gameplay, direct touch/keyboard input, runtime world builder, Android package/signing, and current HUD remain intact during the boot-flow migration.
- Settings changes now synchronize quality tier, look sensitivity, aim assist, fire mode, and screen-effect compatibility values to the legacy Desert settings file for the next map hand-off; audio bus volumes apply immediately.
