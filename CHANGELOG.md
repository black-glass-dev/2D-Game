# Changelog

All notable production changes are documented here.

## Unreleased

### Added

- Production Recon report, M0–M6 plan, baseline audit, progress board, task board, decision log, risk register, QA report, asset import log, blocked-asset register, and initial asset-manifest schema.
- Additive global service contracts for game state, threaded scene loading, versioned settings/save data, map registry, input actions, audio buses, and localization selection.
- `RedlineMapData` plus `MP_DS_01` data resource for the existing Desert Outpost.
- Initial English/Bengali CSV localization catalog.

### Changed

- `project.godot` now registers the foundation services as autoloads and registers the CSV catalog for Godot localization import.
- Existing Desert gameplay, direct touch/keyboard input, runtime world builder, Android package/signing, and current HUD remain intact during the additive foundation batch.
