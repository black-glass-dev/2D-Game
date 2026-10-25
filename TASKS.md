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
- [x] Prepare a factual physical Android capture/handoff path for APK hash, `adb install -r`, device identity, package/launch/foreground evidence, bounded logcat, and reviewer-owned D01–D12 completion.
- [x] Record and withdraw historical candidate 87 after a real Android screenshot showed raw localization keys and an empty map list; retain its immutable release metadata only for audit.
- [x] Anchor generated localization/maps in exported content and require an exported-PCK translation/playable-Desert check before any repaired human-review APK can publish.
- [ ] Restore GitHub Actions billing/spending eligibility: requested runs 40203309780 and 40203309723 did not start because GitHub reported failed account payments or a spending-limit issue; then publish the explicitly unvalidated repaired human-review APK after its export/PCK workflow succeeds and validate the complete touch, mouse, keyboard, gamepad, Android Back, focus-mute/restore, quality-tier, language, and audible mix matrix on a real device with evidence.
- [x] Add one original background-music loop after provenance, mix, and mobile-memory review; keep physical-device listening/mix validation open as a separate requirement.
- [x] Record a normal-Boot CI audio-flow result for the new Music-bus loop; retain physical-device listening validation as a separate requirement.
- [x] Stabilize clean-checkout WAV import by requiring a successful second Godot editor-import pass before export or normal-Boot runtime QA.
- [x] Make an otherwise requested but inactive Music loop rebuild/retry once after the current frame; preserve stop/mute behavior and record actual resume state on a future failure.
- [x] Implement a forward-only downloadable-APK gate requiring Android install/launch; retain package ID and persistent debug-signing compatibility for in-place updates.
- [x] Verify on CI that an emulator failure skips candidate publication; retain physical-device validation as a separate requirement.
- [x] Harden the hosted Android-emulator gate with explicit KVM readiness, hardware acceleration, install-output capture, package verification, and foreground-activity proof.
- [x] Probe the runner's documented KVM udev policy and API-29/default x86_64 baseline; retain direct-node fallback when live udev refresh is unavailable rather than repeatedly retrying the timing-out API-30 ATD image.
- [x] Keep the emulator action's inline install/foreground probe POSIX-shell compatible, matching its `/usr/bin/sh` execution environment.
- [x] Persist the next failed emulator probe's POSIX command trace in a branch diagnostic so opaque hosted-action failures can be narrowed without fabricating launch evidence.
- [x] Move emulator install/foreground control flow to one tracked POSIX script because the runner independently executes every YAML `script` line.
- [x] Address the runner's unproven current directory by invoking the probe and all evidence paths through `$GITHUB_WORKSPACE`.
- [x] Record the runner's post-AVD/pre-boot boundary separately so action failure can be attributed before changing emulator configuration again.
- [x] Return the Android runner to documented AVD/launch defaults while retaining API-29/default/x86_64, acceleration, bounded boot, diagnostics, and release evidence gates.
- [x] Install and verify the minimal `libpulse0` loader dependency identified by a committed pre-launch QEMU diagnostic before the emulator action.
- [x] Re-run the dependency-backed API-29 emulator gate: QEMU/AVD pre-launch evidence passed, but hosted boot still timed out at the full 600-second bound; candidate publication remained blocked.
- [x] Attempt to preserve hosted boot-timeout QEMU serial output without changing the API-29/default/x86_64/KVM release hypothesis; the runner emitted no serial file and still timed out, so no unchanged retry is scheduled.
- [x] Revalidate every non-device CI gate after clean-import/Music-resume repairs; run 39250923376 passed them all, then the unchanged hosted emulator again timed out, so no further emulator-only retry is scheduled.

## M6 started — source-level regression and release foundations

- [x] Expand dependency-free source-contract tests for settings/save schemas and migration paths, monotonic operation records, state-authoritative pause restoration, and data-driven map validity/launch boundaries; run 39259336341 passed the expanded non-device CI suite.
- [x] Enforce the bilingual `keys,en,bn` localization catalog and every current GDScript translation-key route; reject duplicate, blank Bengali/English, missing-key, or locale-loader regressions in source.
- [x] Constrain Android evidence retention to seven days and provide a confirmation-gated workflow that can remove only audited pre-cutoff duplicate debug artifacts; run 39271155212 confirmed emulator-only timeout upload is skipped. The workflow is on `main`, but the current CLI integration cannot create the exact manual dispatch (`HTTP 403`), so no deletion is claimed.
- [x] Exercise the physical Android factual collector against a deterministic fake `adb`, including install/package/launch evidence files and a truthful blocked package-lookup path; retain real D01–D12 review as a separate device-only task.
- [x] Enforce truthful emulator-launch-gated candidate wording, same-run source/Boot/emulator release conditions, bounded qualifying-artifact retention, and the separate physical-QA boundary with dependency-free regression tests.
- [x] Prepare a read-only, paginated GitHub artifact audit and post-cleanup zero-candidate verifier; it cannot delete artifacts. The workflow is now on `main`, while the current CLI integration lacks authority to create the exact approved dispatch.
- [x] Add mutation-tested source protection that keeps the legacy cleanup workflow manual-only, exact-confirmation-gated, exact-name/cutoff-bounded, and separately authorized for deletion.
- [x] Require qualifying evidence storage to succeed before an emulator-launch-gated candidate can publish; retain source-level regressions for gate presence and ordering.
- [ ] Complete the manual desktop/mobile input matrix and physical Android D01–D12 review with a real device and evidence record.
- [ ] Publish a signed release candidate only after the existing same-run Android launch gate passes and storage is available; do not substitute historical exports or hosted boot timeouts.

## M4 — Highrise graybox and systems

- [x] Establish the coordinate-gated `MP_RF_02` graybox manifest and prevent a guessed layout from becoming playable.
- [x] Define and test the provenance-bound B2 coordinate-packet contract before accepting map data.
- [x] Add a map-neutral C++ route-topology core and regression suite without asserting any missing Highrise endpoints.
- [x] Require source-referenced endpoint records for every later bridge/rappel/lift/zipline before topology may reach the graybox adapter.
- [ ] Stage the authoritative B2 coordinate appendix/reference, then build the roof/office/lobby graybox from those exact inputs.
- [ ] Resolve navigation/floor links/spawns/cover, produce Gate 2 captures, and obtain director approval before art.

## Guardrails

- [x] Enforce the existing playable Desert Outpost entry/profile in the delivery-guardrail validator at every source check.
- [x] Enforce the Android package identifier/signing/architecture export contract in the delivery-guardrail validator; CI still restores the persistent debug signing stream.
- [x] Enforce recorded CC0 provenance for the imported Kenney/KayKit subset; do not add commercial-game assets, branding, maps, names, or ripped content.
- [x] Enforce the schema-1 physical-evidence boundary so a physical-device test cannot be marked passed without evidence.
