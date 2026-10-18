# Operation Redline — Task Board

## In progress

- [x] M0.1 Register the verified source-control baseline and living production documents.
- [x] M0.2 Repeat static/resource/native validation against the registered baseline.
- [x] M0.3 Record the first QA baseline and close M0.

## Next: M1 foundation

- [x] Add additive service/autoload architecture without changing Desert gameplay ownership.
- [x] Introduce schema-versioned settings and save migration contracts.
- [x] Add the initial Bengali/English localization CSV catalog and a compatible OFL font family with provenance.
- [x] Create shared Redline UI theme and original SVG icon source set.
- [x] Introduce `MapData`, `MapRegistry`, and an `MP_DS_01` Desert compatibility resource.
- [x] Add named InputMap actions while preserving legacy input; add scoped persistent keyboard/gamepad rebind UI without altering touch safety.

## M2 started — Deliverable A flow

- [x] Add an independently runnable Boot → Splash → Main Menu shell.
- [x] Add a data-driven Desert map card and threaded `SceneLoader` hand-off.
- [x] Add a touch/keyboard/gamepad navigation baseline plus Android Back route in the shell.
- [x] Add five categorized settings sections, persistence, reset confirmation, immediate audio/FPS application, and legacy Desert compatibility write-through.
- [x] Connect the shared settings surface to a state-authoritative pause overlay with renderer-backed Bengali evidence.
- [x] Apply live joystick scale, action-button scale, opacity, and left-handed layout preferences without overwriting HUD-editor positions/sizes.
- [x] Complete conflict-aware keyboard and gamepad input rebinding with persistence, cancellation, conflict rejection, and reset.
- [x] Add map detail, difficulty/mode session selection, and a locked `MP_RF_02` future-map card without exposing a launch route.
- [x] Add fact-based loading telemetry with localized stages, actual progress samples, elapsed time, and normal-Boot hand-off verification.
- [x] Make difficulty/mode affect the Desert compatibility adapter without changing the Normal/Survival baseline.
- [x] Add the quality-aware visual menu background fallback (static original outpost image for non-LOW; no-texture procedural outpost for explicit LOW).
- [x] Run the normal-Boot Xvfb high/LOW renderer-capture gate and record its committed evidence; retain the physical-device matrix as a separate requirement.

## M3 — Deliverable A regression QA

- [x] Add a state-authoritative pause/back/focus-loss lifecycle with shared settings and renderer-backed Bengali UI evidence.
- [x] Persist Desert operation best score/furthest wave; show result summary and Map Select record without changing the wave director balance.
- [x] Route current combat and menu/settings feedback through SFX/UI buses; implement saved-volume-safe focus mute/restore and headless regression coverage.
- [x] Make subtitles, reduced-motion, colorblind HUD, damage-number, haptic, and gamepad-deadzone preferences operational in Desert; add normal-Boot input/accessibility coverage.
- [x] Add normal-Boot Android Back, Escape, controller-B, and paused-settings return/resume route coverage.
- [x] Create a device-identity/evidence-bound physical Android QA matrix and in-place-update recording template.
- [x] Add a schema-versioned validator/test suite that rejects template misuse and incomplete or falsely classified physical-device evidence.
- [ ] Validate the complete touch, mouse, keyboard, gamepad, Android Back, focus-mute/restore, quality-tier, language, and audible mix matrix on real devices where available.
- [x] Add one original background-music loop after provenance, mix, and mobile-memory review; keep physical-device listening/mix validation open as a separate requirement.
- [x] Record a normal-Boot CI audio-flow result for the new Music-bus loop; retain physical-device listening validation as a separate requirement.
- [x] Implement a forward-only downloadable-APK gate requiring Android install/launch; retain package ID and persistent debug-signing compatibility for in-place updates.
- [x] Verify on CI that an emulator failure skips candidate publication; retain physical-device validation as a separate requirement.
- [x] Harden the hosted Android-emulator gate with explicit KVM readiness, hardware acceleration, install-output capture, package verification, and foreground-activity proof.

## M4 — Highrise graybox and systems

- [x] Establish the coordinate-gated `MP_RF_02` graybox manifest and prevent a guessed layout from becoming playable.
- [x] Define and test the provenance-bound B2 coordinate-packet contract before accepting map data.
- [x] Add a map-neutral C++ route-topology core and regression suite without asserting any missing Highrise endpoints.
- [ ] Stage the authoritative B2 coordinate appendix/reference, then build the roof/office/lobby graybox from those exact inputs.
- [ ] Resolve navigation/floor links/spawns/cover, produce Gate 2 captures, and obtain director approval before art.

## Guardrails

- [ ] Preserve the existing playable Desert Outpost at every commit.
- [ ] Keep Android package identifier and persistent debug signing stream unchanged.
- [ ] Do not use commercial-game assets, branding, maps, names, or ripped content.
- [ ] Do not mark a physical-device test as passed without evidence.
