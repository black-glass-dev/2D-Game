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
- Live touch-control preferences: joystick scale, action-button scale, opacity, and left-handed mirroring apply immediately without overwriting player-authored HUD editor rectangles.
- Normal-Boot `--verify-control-layout-flow` harness for scaled/mirrored controls, opacity, fixed minimap placement, and base-layout preservation.
- Conflict-aware Controls rebinding for named gameplay keyboard actions and selected gameplay gamepad buttons, with localized capture UI, conflicting-action feedback, Escape/controller-B cancellation, reset, and `user://input_bindings.cfg` persistence.
- Normal-Boot `--verify-rebind-flow` gate for keyboard/gamepad capture and persistence, conflict rejection, UI-row creation/cancellation, and default restoration.
- Fact-based loading telemetry: localized loader stages, raw threaded-resource progress, monotonic elapsed time, and completed transition records for the Boot loading presentation.
- Normal-Boot `--verify-loading-flow` gate for zero-percent start, localized preparing state, Main hand-off, truthful completion, and telemetry validity.
- Desert session adapter: Easy/Normal/Hard/Nightmare now vary spawn cadence, Survival preserves the three-wave operation, and Endless repeats the 6/9/12 profile with an infinite HUD wave limit.
- Normal-Boot `--verify-session-adapter-flow` gate for Boot-to-Main session hand-off, default-baseline preservation, all difficulty cadence ordering, and Endless continuation.
- Quality-aware Boot-menu backdrop: non-LOW selections display an original 1024×576 Desert Outpost pixel-art image, while explicit LOW uses a no-texture procedural desert/outpost silhouette.
- Normal-Boot `--verify-menu-background-flow` contract and Xvfb high/LOW capture route. The workflow validates two named renderer outputs before it publishes them as evidence.
- Original, source-controlled `outpost_watch.wav` background-music loop, owned by `AudioService`, routed to the existing Music bus, looped forward, and stopped/resumed by the saved Music volume.
- Reproducible music-generator/source validation plus expanded normal-Boot audio-flow coverage for Music routing, loop metadata, mute-stop, and enabled resume.
- A release-truth gate requiring Android emulator install/launch success before CI can publish a downloadable debug APK candidate.
- A 12-row physical Android QA matrix and machine-readable evidence template for a later real-device handoff; templates cannot be mistaken for completed device evidence.
- An M4 Highrise graybox input manifest/validator that blocks guessed coordinates and keeps `MP_RF_02` non-launchable until authoritative B2 inputs are staged.
- A schema-2, test-covered Highrise coordinate-packet contract that binds future B2 appendix/reference files by SHA-256 and requires explicit coordinate-frame, zone-source, and feature-anchor records before graybox construction.
- A coordinate-free C++ `RouteTopology` core and regression suite for later map navigation links, directionality, disabled traversal, and fallback-route verification.

### Changed

- `project.godot` now boots `Boot.tscn` and registers the foundation services as autoloads; `LocalizationService` loads the reviewed CSV catalog at runtime into Godot Translation resources without committing generated import artifacts.
- `Main.tscn` remains directly runnable; it now marks the global game state as Playing when the legacy Desert runtime takes ownership after loading.
- Existing Desert gameplay, direct touch/keyboard input, runtime world builder, Android package/signing, and current HUD remain intact during the boot-flow migration.
- Settings changes now synchronize quality tier, look sensitivity, aim assist, fire mode, and screen-effect compatibility values to the legacy Desert settings file for the next map hand-off; audio bus volumes and live accessibility adapters apply immediately.
- The graphics capture path can now instantiate the real Player without project autoloads, preserving renderer evidence alongside the new deadzone preference.
