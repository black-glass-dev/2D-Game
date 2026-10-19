# Design Decisions

## D-001 — Preserve the Desert as a compatibility adapter

**Decision:** Keep the existing `WorldBuilder.build()` path operational while new menu, registry, save, and map systems are introduced around it.

**Reason:** The current Desert Outpost is runtime-built and its world, spawns, cover, radar, and presentation data are distributed across several scripts. A full rewrite before a compatibility layer would violate the requirement that the old Desert map remains playable after every commit.

**Alternative considered:** Convert the Desert directly into a new static map scene first.

**Why not selected:** It would combine scene migration, collision changes, UI/state changes, and map-data refactor in one high-risk batch.

## D-002 — Locale selection has a deterministic fallback

**Decision:** Use `Auto` by default; resolve Bengali for `bn` locale variants and English for all other or unavailable locales. Persist manual language override in versioned settings.

**Reason:** This fulfills device-language default behavior while avoiding an unreadable missing-font/missing-translation state.

**Alternative considered:** Force Bengali for all first launches.

**Why not selected:** Non-Bengali devices would not satisfy the requested device-language default.

## D-003 — Low-power menu presentation falls back to static map imagery

**Decision:** The menu will use a 3D rail-camera only on the allowed quality budget; a static generated/blurred map thumbnail with a subtle pan is the fallback.

**Reason:** AI, HUD, combat effects, and a full world renderer must not run behind the menu on low-power Android hardware.

**Alternative considered:** Always render the full desert scene behind the menu.

**Why not selected:** It would consume battery/frame budget before gameplay and make the boot flow less reliable.

## D-004 — Highrise graybox uses the coordinate specification as primary geometry authority

**Decision:** Build `MP_RF_02` against the B2 coordinate and height specification. Use the supplied top-down reference as a visual validation layer when its binary is available at the requested repository path.

**Reason:** The coordinate specification is explicit and testable. The attachment binary was not accessible in the workspace during Recon, so no unverifiable image-derived measurement will be invented.

**Alternative considered:** Delay graybox work until the image can be copied locally.

**Why not selected:** The user explicitly supplied a complete text fallback and requires progress without blocking.

## D-005 — Physical-device status remains evidence-gated

**Decision:** Debug APK candidates may be published after source/export/signature/headless/renderer gates pass, but only a recorded Android device or working emulator run can be called physical-device-tested.

**Reason:** The hosted CI emulator repeatedly timed out before boot, including a lightweight Android Test Device image. This is an infrastructure limitation, not evidence of a device pass.

## D-006 — Foundation services are additive before adoption

**Decision:** Register `GameManager`, `SceneLoader`, `SettingsService`, `SaveService`, `MapRegistry`, `InputService`, `AudioService`, and `LocalizationService` as autoloads first, but do not redirect the legacy `Main.tscn` gameplay loop through them in the same batch.

**Reason:** This establishes tested contracts and persistent data migration while leaving the known working Desert boot, input, HUD, weapons, and wave sequence intact.

**Alternative considered:** Replace `main.gd` startup and input handling as soon as the autoloads exist.

**Why not selected:** A simultaneous menu/state/input migration would create an untestable failure surface and violate the bootable-commit rule.

## D-007 — InputMap migration is additive

**Decision:** Add named Redline keyboard/mouse/gamepad actions through `InputService` while retaining direct legacy reads in `player.gd` for this batch.

**Reason:** Existing mobile controls do not depend on InputMap today. Keeping both paths during M1 prevents loss of touch control while establishing a rebinding-capable target contract.

**Alternative considered:** Remove direct key reads immediately.

**Why not selected:** The menu, pause, touch, and gamepad routes do not yet share a complete action consumer and would be at regression risk.

## D-008 — Boot flow is a dedicated shell scene

**Decision:** Change the default entry scene to `Boot.tscn`, then use `SceneLoader` to hand off the selected data-driven map to the unchanged `Main.tscn` Desert scene.

**Reason:** A separate UI shell provides a genuine Boot → Splash → Menu → Map Select → Loading route without turning the legacy gameplay scene into a menu controller. `Main.tscn` can still be launched independently for regression testing.

**Alternative considered:** Build the menu inside `main.gd` before world construction.

**Why not selected:** That keeps combat objects, HUD, world construction, and front-end state alive together and defeats the mobile performance/failure-isolation goal.

## D-009 — Bengali font is vendored with traceable OFL provenance

**Decision:** Vendor Noto Sans Bengali Regular and SemiBold from a pinned `notofonts/noto-fonts` revision as the shared UI font.

**Reason:** The font renders Bengali and Latin UI text, is licensed under SIL OFL 1.1, and is compact enough for the Android target. The exact binaries, hashes, source revision, and full license are in the repository.

**Alternative considered:** Depend on a device system font or retrieve the upstream release ZIP at build time.

**Why not selected:** System glyph coverage varies by device; the release ZIP redirect was unavailable in the restricted build network. Sparse Git retrieval from the pinned source safely produced reproducible vendor files.

## D-010 — Settings UI is reusable and writes through the compatibility seam

**Decision:** Build one `RedlineSettingsMenu` surface for the front end and future pause-menu host. Persist edits immediately in `SettingsService`, live-apply audio bus volume/FPS choices, and mirror the legacy Desert-owned settings that already have a consumer.

**Reason:** This establishes complete categorized settings UI without rewriting the current player, performance governor, HUD editor, or combat settings in the same change. Explicit manual quality tiers remain the authority for the next Desert hand-off; AUTO remains the only adaptive mode.

**Alternative considered:** Duplicate a small menu settings panel and the existing in-game settings panel.

**Why not selected:** Duplicated controls would drift in labels, persistence, behavior, and localization. A shared surface makes the later pause integration additive.

## D-011 — Reviewed CSV remains the localization source of truth

**Decision:** Parse the committed `redline.csv` at runtime and register transient Godot `Translation` resources instead of committing generated importer output or pointing project settings at a raw CSV as a Translation resource.

**Reason:** The raw CSV is reviewable, bilingual, and stable in source control. The direct project-setting approach produced an engine resource-load error in CI; runtime registration fixes it without generated caches.

**Alternative considered:** Commit generated translation binaries.

**Why not selected:** Generated import artifacts are editor/version dependent and violate the source-only repository convention.

## D-012 — Highrise appears as an honest pre-production card

**Decision:** Register `MP_RF_02` as a valid `COMING_SOON` metadata resource with no scene path and `playable = false`. The Map Select screen may display and inspect it but cannot launch it.

**Reason:** The director needs the future operation visible in the data-driven UI, while the Highrise graybox, navigation validation, and Gate 2 approval have not happened. The registry treats locked metadata as valid but requires a resolvable scene for any playable map.

**Alternative considered:** Omit the Highrise resource until its graybox scene is complete.

**Why not selected:** The map-select and data-registry acceptance criteria require locked future-map handling. Hiding it would leave that critical flow untested.

## D-013 — Difficulty and mode are session state before combat modifiers

**Decision:** Let the player choose difficulty and survival/endless mode in the map detail panel and store them in `GameManager`, but do not claim their gameplay modifiers are implemented until the legacy wave director consumes them.

**Reason:** It validates data flow, input, localization, and launch selection without altering the preserved 6/9/12 Desert wave behavior in the same batch.

**Alternative considered:** Add modifiers directly to `SurvivalDirector` now.

**Why not selected:** Wave size, score, HP, and balance are explicit non-regression requirements. Those changes need their own tested compatibility adapter and QA matrix.

## D-014 — Pause is a state transition with a live shared-settings child surface

**Decision:** Keep `Main` processable while the tree is paused, gate its gameplay work on `SceneTree.paused`, and use `GameManager.enter_pause()` / `leave_pause()` as the only pause-state transitions. The paused overlay hosts the existing `RedlineSettingsMenu` instead of a second settings implementation.

**Reason:** This freezes the current Desert simulation without losing Esc, Android Back, focus-loss, or touch pause access. It preserves the legacy wave/score/HP scene while keeping a single immediate-persistence settings contract. Pause, settings return, resume, restart, map-select, and desktop-quit routes are all explicit. The normal Boot hand-off test route additionally checks pause → settings → back → resume, and the Xvfb route captures the pause plus Bengali settings surfaces from the real game.

**Alternative considered:** Pause only the player/director and leave the scene tree running, or duplicate a compact pause settings panel.

**Why not selected:** Partial pausing risks background UI/timers and missed state ownership; duplicated settings would diverge from the already reviewed category UI, persistence behavior, and Bengali localization.

## D-015 — Operation results are durable per-map records, not a new progression system

**Decision:** At mission completion or player-down, record the Desert operation's highest score and furthest wave through the existing `SaveService` per-map `best_results` contract. Present score, reached wave, accuracy, and the durable best score in the existing result overlay; show the record on the Map Select detail card.

**Reason:** This completes the run-end link to score and retry without altering the verified 6/9/12 wave sequence, player HP, reward economy, map unlock state, or director ownership. The current data contract already persists score/wave atomically with the rest of the player save, so it is the smallest compatible surface for an offline single-player record.

**Alternative considered:** Add XP, currencies, a new profile scene, unlock rewards, or modify wave difficulty after a result.

**Why not selected:** Those systems would introduce progression and balance decisions outside the M3 regression scope. They also risk changing the existing Desert survival loop before its base results flow is fully validated.

## D-016 — Audio uses buses and focus policy before introducing music content

**Decision:** Route existing rifle, pistol, reload, and landing audio to the SFX bus; use a quiet existing original click for menu/settings confirmation on the UI bus; and centralize application focus muting in `AudioService`. On focus return, reapply the saved Master-volume mute state rather than blindly unmuting.

**Reason:** This makes the reviewed Audio settings functional for current combat and UI feedback while avoiding new music or licensed sound acquisition in a regression batch. The focus policy respects a player who deliberately set Master volume to zero, and does not write settings or emit recursive preference changes during focus transitions.

**Alternative considered:** Add an untracked background-music loop now, or have each weapon/menu individually mute itself on focus loss.

**Why not selected:** New music needs provenance, a mix pass, and mobile memory review. Distributed focus logic would let one player restore audio while another remains muted and would make the player preference unreliable.

## D-017 — Accessibility preferences modify the live Desert adapter

**Decision:** Make the existing accessibility settings directly affect the current Desert: reduce view recoil/bob/landing motion, use a colorblind-safe HUD palette, gate floating damage numbers, respect the haptics toggle, and expose a configurable analog-stick deadzone. Adopt the named `InputService` actions in `OutpostPlayer` so keyboard and gamepad use one gameplay route while visible touch controls remain explicit input sources.

**Reason:** The settings panel previously persisted these choices without reliable gameplay consumers. These narrow adapters improve readability and control comfort without changing enemy health, score, wave balance, touch-fire boundaries, or the player’s base movement model. A deterministic normal-Boot harness verifies action coverage plus the live reduced-motion, palette, and damage-number behaviors.

**Alternative considered:** Build a broad rebinding/keymap editor or add aim/auto-fire behavior to arbitrary touchscreen areas.

**Why not selected:** Conflict-aware rebinding needs its own UI, conflict-resolution policy, and device QA. Arbitrary-screen firing violates the explicit touch-control safety requirement and would regress the current visible-FIRE-only mobile contract.

## D-018 — Subtitles become concise tactical sound captions

**Decision:** Use the existing `subtitles` preference for brief, localized on-screen captions of player-owned audible combat cues: rifle fire, pistol fire, reload, and landing. Render a separate, non-interactive HUD label and immediately suppress it when the preference is disabled.

**Reason:** Desert currently has no voiced dialogue to transcribe, but it does have gameplay-relevant combat and movement sounds. Captioning those cues makes the setting operational for players who cannot rely on audio while avoiding a false claim that dialogue subtitles exist. The wording is localization-CSV backed in English and Bengali and the normal-Boot accessibility gate verifies both enabled and disabled behavior.

**Alternative considered:** Leave the setting stored until a narrative dialogue system is built, or place captions in the persistent status line.

**Why not selected:** An inert visible setting offers no present player benefit. Reusing the status line would overwrite mission/reload feedback and make audio captions hard to distinguish from objective state.

## D-019 — Android Back is one tested return/resume contract

**Decision:** Treat Android's `NOTIFICATION_WM_GO_BACK_REQUEST`, Escape, and controller B as equivalent return inputs. In Boot they leave Splash, Settings, or Map Select for the main menu; while Desert is paused they first leave shared settings and then resume the operation.

**Reason:** The visible routes already shared this intent but had no dedicated contract proving their notification and device-action paths. A normal-Boot gate now drives the native Back notification plus keyboard and gamepad menu events, while the pause gate uses the same Android notification to leave settings and resume.

**Alternative considered:** Keep separate Android-only Back paths or let Back quit whenever no modal is open.

**Why not selected:** Parallel routing can drift between controllers and mobile. Immediate gameplay exit conflicts with the expected pause/resume behaviour and makes accidental Android Back input destructive.

## D-020 — Touch preferences transform, rather than overwrite, player HUD layouts

**Decision:** Store HUD-editor rectangles as a player-authored base layout. Apply joystick scale, action-button scale, opacity, and left-handed placement as a separate live presentation layer; keep the minimap anchor and scale unchanged.

**Reason:** This makes the existing Controls settings visibly operational while preserving a player's manually positioned/resized controls. Persisting only base rectangles prevents scale/mirroring from compounding whenever the player saves a layout, changes preference, or rotates/resizes the viewport. The controller verifies scaling, opacity, mirroring, minimap stability, and base-rect round-trip in a normal Boot path.

**Alternative considered:** Persist already-scaled display rectangles, or only apply the Controls settings before a player enters HUD edit mode.

**Why not selected:** Display-rect persistence would multiply size and mirror offsets over successive sessions. Limiting preferences to first launch would leave visible saved settings inert for players with a customized layout.

## D-021 — Rebinding is scoped, conflict-rejecting, and independently persisted

**Decision:** Expose conflict-aware rebinding in Controls for all named gameplay keyboard actions and for the seven gameplay gamepad buttons (fire, aim, jump, crouch, weapon swap, reload, and pause). Store custom physical-key and gamepad-button values in `user://input_bindings.cfg`, independently of general settings. A proposed input already used by another action on the same rebind surface is rejected with the conflicting action named; Escape cancels keyboard capture and controller B cancels gamepad capture. Reset restores the reviewed defaults. Mouse bindings, touchscreen controls, left-stick axes, menu navigation, and controller Back remain fixed.

**Reason:** This gives keyboard and controller players an understandable, durable customization path without allowing an accidental duplicate gameplay mapping, breaking the established left-stick/mobile convention, or turning arbitrary screen touch into a firing route. A dedicated binding file lets reset and migration stay narrow while `InputService` remains the sole owner of named action maps.

**Alternative considered:** Swap the two conflicting action bindings automatically, allow arbitrary duplicate mappings, or expose every device event including touch, mouse, analog axes, and system menu controls.

**Why not selected:** Automatic swaps can silently remove an intentional binding; duplicates make action ownership ambiguous. Full device/event editing would endanger Android Back, focused-menu navigation, visible-control-only touch safety, and the verified Desert movement convention without a larger device QA matrix.

## D-022 — Loading telemetry reports loader facts, not simulated progress

**Decision:** Keep threaded scene loading in `SceneLoader`, but report its actual request, streaming, ready, transition, completion, and failure stages together with the `ResourceLoader` progress samples and monotonic elapsed time. Boot presents those values directly: the bar begins at zero, reaches 100 only after Godot reports the resource loaded, and shows a localized stage plus elapsed seconds. The last completed transition remains available to the incoming scene for normal-Boot verification.

**Reason:** The existing screen began at an invented four percent and exposed only a generic label. Fact-based telemetry gives a player meaningful deployment feedback while keeping the existing Main scene, fade, input safety, and map ownership unchanged.

**Alternative considered:** Animate a cosmetically smooth percentage independent of the loader, or add a separate loading scene with duplicated transition ownership.

**Why not selected:** Simulated percentages can reach completion while an Android device is still loading and undermine trust. A second scene would split fade/loading responsibility from the existing autoload and increase Boot-to-Desert regression risk.

## D-023 — Session options alter cadence and completion policy while preserving the default profile

**Decision:** Give the pre-deployment difficulty selector ownership of hostile spawn cadence only: Easy is slower, Normal is unchanged, Hard and Nightmare are faster, and every profile keeps the same 6/9/12 enemy count sequence. Survival completes after its third wave exactly as before. Endless repeats that same 6/9/12 sequence indefinitely, rather than inventing larger late-wave counts. The active Main HUD displays an infinite wave limit for Endless.

**Reason:** The selector must affect the real Desert session, but the verified Normal/Survival mode needs to retain its existing spawn counts, 0.83/0.71/0.59-second cadence, score, player HP, and three-wave completion contract. A narrow director adapter provides an explicit, understandable effect without changing enemy data or score economy.

**Alternative considered:** Scale enemy health/damage and reward score per difficulty, multiply wave sizes, or add random endless escalation.

**Why not selected:** Those changes would combine combat tuning, survival balance, result scoring, and device-performance risk in one compatibility batch. They would also make the established Normal/Survival regression baseline ambiguous.

## D-024 — Quality selection owns a static-or-procedural Boot backdrop

**Decision:** Keep Boot presentation independent from Desert gameplay. `AUTO`, `MEDIUM`, `HIGH`, and `ULTRA` use one original static 1024×576 Desert Outpost pixel-art image. Explicit `LOW` uses only a flat, no-texture procedural desert/outpost silhouette composed from `ColorRect` nodes. Settings changes apply this choice immediately and no automatic quality policy overrides a manual LOW selection.

**Reason:** The prior rail-camera concept in D-003 would still require a 3D scene and create boot/battery risk. A static image preserves the intended year-2000, non-futuristic outpost presentation at normal quality, while the LOW path avoids loading an image or starting `Main`, a world, AI, combat, HUD, or input simulation behind the menu. The two modes are simple to prove through normal Boot and renderer capture.

**Alternative considered:** Run the playable `Main` scene as a live menu background, use a 3D rail camera above LOW, or apply an adaptive override that changes a player-selected quality tier.

**Why not selected:** Live gameplay systems behind the menu couple presentation to wave/session state and waste CPU/GPU. A 3D camera raises import/render risk for a narrow UI improvement. An adaptive override would make the visible manual selection untrustworthy. D-024 supersedes D-003's unimplemented rail-camera direction.

## D-025 — One original, low-level Music-bus loop before more soundtrack scope

**Decision:** Add one original, non-lyrical 16-second tactical background loop generated from source-controlled standard-library synthesis. Own it globally in `AudioService`, route it only to `Music`, set its player gain to `-16 dB`, forward-loop it, and stop it when the saved Music volume is zero. Keep existing Master focus mute behavior. Do not add combat-adaptive layers, radio vocals, licensed tracks, or multiple music states in this batch.

**Reason:** The existing Music slider and bus had no audible consumer. A single reproducible loop makes that player-facing setting operational while preserving mobile budget and combat readability. The source PCM is mono 22,050 Hz and about 0.67 MiB, and its effective default level is about -18.5 dB—well below current transient weapon effects. The provenance, mix calculation, source generator, and memory boundary are independently recorded in `docs/AUDIO_ASSET_REVIEW.md`.

**Alternative considered:** Import a CC0 music-jingle pack, leave Music saved-only until a larger soundtrack is licensed, or add multiple adaptive gameplay tracks.

**Why not selected:** The inspected CC0 jingles were short stingers rather than credible background loops. Leaving an exposed volume slider without a sound source remains misleading. Multiple states and adaptive mixing would need transition design, more assets, broader memory measurements, and physical-device listening tests; they exceed this narrow M3 batch.

## D-026 — A downloadable candidate requires Android install/launch success

**Decision:** Gate the GitHub pre-release APK step on successful Android export, normal-Boot gameplay checks, and the Android emulator install/launch step. Keep the existing package ID and persistent debug-signing keystore stream. Do not publish a new player-downloadable candidate when the emulator times out or fails.

**Reason:** An export/signature check proves that an APK can be built, not that it can install as an in-place update and launch. The former workflow correctly labelled candidates as pre-releases but could still publish them while its final device gate was failing. A hard dependency on the named `android_emulator` step makes the user-facing delivery boundary match the stated test requirement.

**Alternative considered:** Publish an APK after export/headless success with a warning, block all export artifacts until a physical device is available, or retroactively delete historical pre-releases.

**Why not selected:** A warning can be missed and leaves an untested update downloadable. Blocking exports would eliminate valuable diagnostics and renderer evidence. Historical release deletion is destructive and would erase audit history; instead, `docs/RELEASE_GATING.md` explicitly records their non-tested status while the forward gate prevents recurrence.

## D-027 — Physical-device evidence is a structured matrix, not a status assertion

**Decision:** Use `docs/PHYSICAL_DEVICE_QA.md` and a completed `physical_qa_evidence.json` record for physical Android validation. The record must identify the APK/source/device, retain the `adb install -r` result, give every required control/audio/settings/survival row a PASS/FAIL/BLOCKED value, and point to concrete capture/log evidence. No template row, device field, or evidence path may be treated as completed evidence.

**Reason:** The project has broad normal-Boot and renderer coverage but no functioning hosted emulator/device run. A precise matrix makes the eventual on-device review repeatable across touch, keyboard/mouse, gamepad, Android Back, focus, Bengali/English, quality tiers, music mix, and the three-wave operation. It also proves the in-place update route without replacing it with an uninstall/reinstall.

**Alternative considered:** A short free-form tester note, a single launch screenshot, or marking all automated normal-Boot checks as a device pass.

**Why not selected:** A free-form note can omit critical controls and cannot reliably identify the exact APK. One screenshot does not prove lifecycle, input safety, audio, settings persistence, or survival completion. Automated renderer/headless checks are valuable but run outside the target device.

## D-028 — Highrise graybox is coordinate-gated rather than guessed

**Decision:** Keep `MP_RF_02` non-launchable while the authoritative B2 coordinate appendix and top-down reference are absent from the checkout. Record the known 120 m × 90 m card footprint, named zones, and required features in a source-controlled manifest; validate that the waiting manifest contains no coordinates and that the map remains `COMING_SOON`. Only a later manifest that truthfully stages the authoritative values may unlock geometry work.

**Reason:** The M4 exit criteria require exact footprint, heights, gaps, bridges, skylights, navigation, cover, and captures. The current repository carries the topology but not the coordinate source. A technical gate enables productive contract/test preparation without inventing a level that could be mistaken for the director-approved design.

**Alternative considered:** Estimate a plausible rooftop from the 120 m × 90 m card, recreate dimensions from memory of the unavailable diagram, or start art before graybox input is complete.

**Why not selected:** Estimated coordinates would undermine the exact B2 contract and make later nav/capture comparisons invalid. Starting art first violates Gate 2 sequencing and makes corrective layout changes expensive. The manifest gate preserves the user-visible map lock and the Desert regression baseline until real inputs are staged.

## D-029 — Coordinate intake requires provenance, frame, and feature anchors

**Decision:** Upgrade the M4 manifest to a versioned, test-covered coordinate-packet contract before receiving the B2 sources. A staged packet must hash and identify two distinct repository files (the coordinate appendix and top-down reference), describe its coordinate frame, trace each zone to the source, and supply semantic anchor records for every named gap, bridge, traversal link, supply node, and wave route. The map remains locked even when that intake gate passes.

**Reason:** A zone-only list could claim that numbers were staged while leaving the reference unverifiable, coordinate axes ambiguous, or critical navigation features unplaced. An integrity-bound packet makes the later graybox reproducible and reviewable without inserting any invented map value into the current project.

**Alternative considered:** Accept un-hashed prose notes, wait to design the data shape until graybox implementation starts, or unlock the card immediately after the zone rectangles are entered.

**Why not selected:** Prose cannot be mechanically checked against a source file. Delaying the contract risks entangling source interpretation with scene construction. Zone rectangles alone do not establish lightwell, bridge, traversal, supply, or wave-route placement, and an unlocked card before navigation/capture review would bypass Gate 2.

## D-030 — Navigation behavior begins with a coordinate-free native topology core

**Decision:** Add a portable C++ `RouteTopology` graph before M4 receives B2 geometry. The graph accepts only explicit zone IDs and registered traversal links, supports walk/bridge/rappel/lift-shaft/zipline semantics, directionality, enabled/disabled state, and deterministic fallback-route queries. It deliberately contains no Highrise zone endpoints or world coordinates. The future Godot adapter may populate it only from the validated graybox/navigation packet.

**Reason:** Raider movement across floors and traversal links needs a testable route contract, yet recording even a single Highrise endpoint before the B2 source arrives would be an invented layout decision. The native core advances the requested C++ architecture and gives later navigation work a focused unit-test surface without touching Desert gameplay.

**Alternative considered:** Add a speculative Highrise `NavigationRegion3D`, embed the graph in a Godot scene now, or wait until all art/navigation work begins.

**Why not selected:** A speculative scene or endpoints would violate the coordinate gate. Scene-first logic would couple Godot navigation setup to unverified geometry. Waiting would postpone duplicate-link, direction, disabled-traversal, and fallback-route tests until the most failure-prone integration phase.

## D-031 — Emulator evidence requires acceleration, install, and foreground proof

**Decision:** Strengthen the existing Android release gate before its emulator action starts: require accessible KVM, require `-accel on`, retain a bounded boot allowance, capture exact `adb install -r` output, verify the package manager can resolve the installed package, and require the app to become the resumed Android activity before the crash-log scan. Preserve the existing rule that no candidate is published unless this same `android_emulator` step succeeds.

**Reason:** Repeated hosted boot timeouts leave no useful distinction between missing acceleration, runner capacity, install failure, launch failure, or a process crash. These checks make the runner prerequisite explicit and turn a later success into auditable install-and-foreground evidence, while a failure retains a more actionable boundary than an unchecked launch delay.

**Alternative considered:** Increase the boot timeout without diagnostics, publish after export with a warning, or treat a successful `adb install` as launch proof.

**Why not selected:** A longer timeout alone may consume CI time without fixing software emulation. Warning-labelled downloads would violate the delivery gate. Installation only proves package acceptance; it does not prove that the process started and reached a foreground activity.

## D-032 — Physical QA records are machine-validated evidence, not editable checklists

**Decision:** Give the physical Android QA template a schema version and validate both the committed non-evidence template and any future completed record. A completed record must identify the exact source/APK/device/install/logcat/reviewer and supply concrete evidence plus an observation for every D01–D12 row. Its release classification is derived from the matrix: only all PASS rows may state `PHYSICAL_DEVICE_TESTED`; a record containing FAIL or BLOCKED remains `NOT_PHYSICAL_DEVICE_TESTED`.

**Reason:** A well-written checklist can still be copied with blank identity fields, a placeholder install command, a missing capture, or an optimistic status. A dependency-free validator makes the release wording auditable before a reviewer sees a device claim, while preserving FAIL/BLOCKED records as useful evidence rather than forcing a false success.

**Alternative considered:** Keep the JSON as an unvalidated template, reject all records with a non-PASS row, or let a reviewer select any release classification manually.

**Why not selected:** Unvalidated JSON cannot reliably distinguish a procedure from proof. Rejecting failure records erases diagnostic information and discourages honest reporting. Manual classifications can contradict the matrix and are especially risky while hosted emulator evidence remains unavailable.

## D-033 — Traversal endpoints must be source-referenced before navigation wiring

**Decision:** Extend the Highrise intake contract to require one source-referenced topology record for each bridge, rappel, lift-shaft, and zipline when the B2 packet is staged. Each record must name its feature, two distinct staged zones, and whether traversal is bidirectional. The map stays locked and no endpoint record exists while the source inputs remain absent.

**Reason:** Coordinate anchors show where a traversal feature sits, but they do not by themselves prove which two navigation zones it joins or whether an AI/player can travel in both directions. Validating that relationship before Godot wiring gives the native route graph a traceable input and prevents a plausible-but-invented connection from becoming gameplay behavior.

**Alternative considered:** Infer link endpoints from the nearest anchors after graybox construction, add only generic route tests, or record bridge endpoints now from the card names.

**Why not selected:** Nearest-anchor inference can cross floors or gaps incorrectly. Generic tests do not prove a map's actual connections. Recording an association before its B2 source arrives would be the same fabricated-layout risk the M4 gate is intended to prevent.

## D-034 — Probe the documented emulator baseline instead of retrying a timing-out image

**Decision:** Keep the same Android release gate but replace the repeated API-30 AOSP ATD probe with the emulator-runner action's documented API-29/default x86_64 baseline. Apply its documented persistent KVM udev policy, explicitly retain Linux hardware acceleration, and increase the bounded boot allowance to 600 seconds. Preserve install-output, package, resumed-activity, crash-log, and publication conditions unchanged.

**Reason:** KVM passed in two prior runs, yet the API-30 ATD image still timed out before boot. Repeating the identical configuration would provide no new diagnostic signal. The action documentation presents API 29/default on an accelerated Ubuntu runner as its primary working path; the exported x86_64 APK can install on that API-level baseline without changing the package or signing stream.

**Alternative considered:** Keep retrying API-30 ATD, remove the device gate, or attempt an ARM emulator.

**Why not selected:** Identical retries waste CI minutes. Removing the gate would recreate untested downloadable APK risk. ARM images are slower and the action documentation identifies modern x86/x86_64 images as the accelerated CI path.

## D-035 — A failed live udev trigger must not suppress an otherwise usable KVM probe

**Decision:** Attempt the documented persistent KVM udev rule, but treat failure to reload or trigger live udev as a runner-specific diagnostic rather than an automatic release-gate failure. Verify `/dev/kvm` exists, apply the previously successful direct node-permission fallback, then require read/write access before the emulator action proceeds.

**Reason:** CI run 39129496696 completed all source/export/renderer gates but failed in the new udev preparation step before the API-29 emulator was ever attempted. Earlier runs proved that the hosted image can expose an accessible `/dev/kvm` with direct node permissions. The fallback preserves the udev attempt and its audit signal without conflating an in-run device-rule refresh failure with emulator availability.

**Alternative considered:** Remove the udev policy entirely, leave the hard failure in place, or waive KVM verification.

**Why not selected:** Removing udev loses a documented durable configuration path. Leaving the hard failure prevents testing the distinct API-29 image hypothesis. Waiving KVM would hide the acceleration prerequisite that the release gate is meant to verify.

## D-036 — Emulator action probe is one tracked POSIX script

**Decision:** Keep the Android-emulator-runner YAML input to one command, `sh scripts/android_emulator_probe.sh`, and keep all install/package/foreground control flow in that tracked POSIX `sh` file. Use `set -eu`/`set -x` and `[ ... ]` tests, not Bash-only `pipefail` or `[[ ... ]]`; statically syntax-check the file beside the existing evidence contract.

**Reason:** CI run 39130099493 reached the new KVM/API-29 launch path, then failed with `/usr/bin/sh` exit code 1 before installation/launch evidence. Upstream action-source review shows `parseScript()` splits every YAML `script` line and invokes each independently as `sh -c`. Therefore the original multiline block could neither preserve shell state nor contain a multiline `if`/loop, even after Bash-only constructs were removed. Run 39130918946 retained the generic annotation, and run 39131623011's failure-only marker confirmed the block had not produced a persistent trace. Run 39132269643 still produced no tracked trace with a relative script path, so the action now invokes the file by `$GITHUB_WORKSPACE` and uses absolute evidence paths rather than assuming the action's current directory.

**Alternative considered:** Treat the run as an emulator boot failure, remove strict shell options, or wrap a nested Bash command.

**Why not selected:** The annotation identifies an action-shell failure rather than a boot timeout. Removing error handling would hide failed ADB/package checks. A nested Bash wrapper obscures the action-native environment; one tracked POSIX script preserves control flow, makes local `/usr/bin/sh -n` verification meaningful, and leaves the action input unambiguous.

## D-037 — Persist failed emulator-probe command traces in the branch

**Decision:** Redirect the POSIX emulator probe's traced stdout/stderr to `build/android-emulator-probe.log` and, only if the action fails, copy that log to `ci-logs/` and commit it to the same branch. Include it in the normal evidence artifact when storage permits.

**Reason:** GitHub run 39130918946 still returned only the action-level `/usr/bin/sh` exit annotation, while signed job-log retrieval is unavailable in this environment and artifact upload is quota-blocked. Run 39131623011 committed the explicit missing-log marker, which exposed that the action's line parser had prevented the previous inline redirection from persisting. With D-036's single tracked script, the same failure-only path now gives the next review an exact command boundary without treating it as successful device evidence.

**Alternative considered:** Re-run unchanged, suppress `set -e`, or add a Bash wrapper.

**Why not selected:** An unchanged retry cannot narrow the failure. Suppressing failure behavior can falsely continue past a broken evidence command. A nested Bash wrapper obscures the action-native `sh` environment instead of recording the actual failing command. The runner's unproven relative working directory is also not an acceptable evidence path, so the tracked script and every output path use `$GITHUB_WORKSPACE` explicitly.

## D-038 — Record the emulator runner's pre-launch boundary separately

**Decision:** Use a second, one-line `pre-emulator-launch-script` input to run a workspace-absolute POSIX pre-launch probe after AVD creation and before emulator boot. Record the action working directory, Android paths, AVD config presence, emulator version, and a boundary marker; preserve this file with the failure diagnostics.

**Reason:** Run 39132968303 again reached all prior KVM/API-29 gates yet committed no post-launch probe trace, despite workspace-absolute post-launch paths. The evidence cannot distinguish a failure before the custom probe (AVD/launch path) from a trace-preservation failure. The runner defines the pre-launch hook precisely at that boundary, so it provides the smallest additional observation without relaxing any gate.

**Alternative considered:** Change the API/profile/acceleration inputs blindly, disable the strict action gate, or treat the generic annotation as device evidence.

**Why not selected:** Changing several variables at once destroys failure attribution. Relaxing the gate or claiming a device result would violate the release contract. The pre-launch record narrows the execution boundary first while preserving KVM, API, acceleration, install, package, foreground, and crash requirements.

## D-039 — Use action defaults beyond the explicit API-29/x86_64/KVM baseline

**Decision:** Retain only API 29, `target: default`, `arch: x86_64`, the bounded 600-second allowance, and `disable-linux-hw-accel: false`; let android-emulator-runner supply its documented AVD profile/memory and launch-option defaults. Keep the pre-launch boundary probe.

**Reason:** Run 39133730161 still did not reach the pre-launch hook, placing the opaque `sh` failure before the custom probe and before a proven boot path. The prior configuration had added a Pixel 7 Pro profile, RAM/heap overrides, and custom emulator options. A public Servo workflow uses the same action and API-29/default/x86_64 trio without those overrides. Returning to that supported minimum isolates those extra action inputs while preserving the required KVM acceleration policy.

**Alternative considered:** Alter API level/target/architecture, disable KVM acceleration, or keep all overrides and retry unchanged.

**Why not selected:** Altering the baseline invalidates the already selected API-29 test hypothesis. Disabling acceleration violates the release gate. Retrying identical pre-launch-unreached inputs cannot determine whether an override caused AVD setup failure.

## D-040 — Install the emulator's missing PulseAudio runtime library

**Decision:** Install Ubuntu package `libpulse0` immediately before the Android-emulator-runner action and assert `libpulse.so.0` is present in the dynamic-linker cache. Keep `-noaudio`; this package restores a runtime loader dependency, not audio playback.

**Reason:** The committed pre-launch record from run 39134522905 proves AVD setup reached the hook and captures the exact emulator-loader error: `qemu-system-x86_64: error while loading shared libraries: libpulse.so.0: cannot open shared object file`. The action then timed out waiting for boot, which is consistent with the emulator binary being unable to start. Installing the specific missing library is the minimal evidence-backed repair.

**Alternative considered:** Relax the emulator gate, remove `-noaudio`, change Android image/API, or install an unbounded desktop-audio package set.

**Why not selected:** None addresses the recorded dynamic-loader error as directly. `-noaudio` does not remove QEMU's linked library requirement. Unrelated image/API changes would conflate causes, while broad packages add unnecessary runner surface. Run 39136026161 then proved the repair: the pre-launch record reports emulator version 37.2.12.0 and `test.avd/config.ini` without a loader error. The action nevertheless used its full 600-second allowance and timed out waiting for boot, so this is runtime-dependency confirmation only—not emulator, APK, or device success.

## D-041 — Persist guest serial output for boot-timeout attribution

**Decision:** Preserve the runner's documented headless emulator options and add only the QEMU serial sink `-qemu -serial file:$GITHUB_WORKSPACE/build/android-emulator-serial.log`. On action failure, copy that file into `ci-logs/`; include it in normal build evidence when artifact storage permits.

**Reason:** Run 39136026161 proved that QEMU and the AVD load after the targeted `libpulse0` repair, then timed out at boot before the post-boot probe can execute. The guest serial stream is the narrowest available host-side record of kernel/init progress inside this existing action invocation.

**Alternative considered:** Increase the boot timeout again, change API/image parameters, or classify the run as a successful emulator test.

**Why not selected:** Increasing an already bounded 600-second wait without new information wastes CI time. Changing the tested baseline conflates variables. A timeout contains no install/foreground proof and cannot be classified as success. Run 39203792018 again timed out, and no serial file was committed; the existing pre-launch record remains the only persisted action diagnostic. The serial option is retained as harmless source instrumentation, but no further unchanged hosted retry is justified without a newly available runner or physical device.

## D-042 — Physical-device capture is factual collection, never automatic QA classification

**Decision:** Provide a device-side collector and handoff that record the exact APK hash, `adb install -r` output, package lookup, launch/resumed-activity data, bounded logcat, crash scan, and raw device properties. Keep it outside the CI trigger path. The collector never writes D01–D12 results or `PHYSICAL_DEVICE_TESTED`; a named reviewer must complete and validate the existing schema-1 record.

**Reason:** The emulator gate remains boot-blocked after source, KVM, runtime-library, and boot diagnostics. A real Android device is now the only evidence path that can exercise touch, landscape, input hardware, audio, thermal behavior, and in-place update semantics. Capturing machine facts reduces handoff error while keeping human gameplay review and the all-PASS rule authoritative.

**Alternative considered:** Automatically convert successful ADB install/launch into D01–D12 PASS, edit the committed template into evidence, or mark an exported APK as device-tested.

**Why not selected:** ADB facts cannot prove touch safety, quality, language, audio, survival, or thermal behavior. The committed template is deliberately non-evidence, and any automatic pass label would violate the physical-QA contract.

## D-043 — Make source-level delivery guardrails executable

**Decision:** Add a dependency-free delivery-guardrail validator and regression suite. It asserts the landscape Boot entrypoint, direct-update package/signing/architectures, playable Desert map identity and 6/9/12 profile, Highrise lock, and the committed CC0 provenance records. Integrate it into the normal project validator.

**Reason:** M3 physical-device evidence and M4 authoritative B2 input remain external blockers, but the roadmap still requires the Desert to remain playable, package identity to remain stable, the future map to remain locked, and permissive asset provenance to remain auditable on every source change. These are enforceable now without inventing map geometry or device results.

**Alternative considered:** Mark the guardrails complete only in documentation, or unlock/construct Highrise placeholders while waiting for B2.

**Why not selected:** Documentation alone cannot prevent a later accidental package change, Desert profile regression, or premature Highrise unlock. A placeholder Highrise scene would violate the coordinate gate. The executable checks give forward progress while preserving those boundaries.

## D-044 — Stabilize Godot clean imports before runtime QA

**Decision:** On a fresh CI checkout, run Godot editor import twice before Android export and headless gameplay checks. Preserve the first log separately and make the second pass fail on a GDScript parse error or failed autoload creation.

**Reason:** CI run 39249610440 passed source/native, Android export, and the new delivery-guardrail tests but its committed first-import log shows that `AudioService` tried to preload WAV files before initial WAV import metadata existed, leaving the autoload uncompiled. A first editor scan creates that metadata; the second pass confirms the actual project compiles before any export/runtime acceptance claim. The same run's later audio-resume failure is tracked separately in D-045; the available logs do not establish a causal relationship.

**Alternative considered:** Remove audio preloads, ignore the import diagnostic because export succeeded, or rerun the existing workflow unchanged.

**Why not selected:** Removing audio regresses a required gameplay system. Export alone did not prove a clean compile. An unchanged retry retains a clean-checkout race rather than validating the full project lifecycle.

## D-045 — Retry deferred background-music start only when a loop is still inactive

**Decision:** After a nonzero Music-volume update starts an inactive background loop, schedule one deferred recheck. It creates a fresh duplicated looping WAV resource and starts it only if the current saved volume remains nonzero and the player is still inactive.

**Reason:** The normal-Boot audio verifier in CI run 39249610440 reached the final unmute/resume assertion but observed no active background player after a stop/start transition. The subsequent changed-run diagnostic preserved the substate (`playing=false`, Music bus unmuted, requested volume `0.50`) even after an ordinary deferred retry. The source repair is deliberately narrow: it rebuilds the stopped playback resource only for that inactive requested resume, without claiming a device/audio-output result.

**Alternative considered:** Mark Music as resumed without an active player, continuously restart it on every nonzero volume update, or make an unchanged retry.

**Why not selected:** Declaring success without a player weakens the regression contract. Continuous restarts interrupt a listener moving the volume slider. An unchanged retry would preserve the diagnosed inactive-player state. The targeted recovery preserves user-selected mute state and makes a changed source contract available for validation.

## D-046 — Test M6 foundation contracts without inventing runtime/device evidence

**Decision:** Add a dependency-free source validator and regression suite for the current `SettingsService`, `SaveService`, `GameManager`, `RedlineMapData`, and `MapRegistry` contracts. It checks schema-versioned migration surfaces, protected Desert defaults, monotonic operation results, guarded pause/restore state, input option fallback, and data-driven map validity/launch boundaries; `tools/validate_project.py` runs it on every source check.

**Reason:** M6 explicitly calls for expanded tests of map profiles, settings migrations, and state transitions. Physical Android evidence and Highrise B2 geometry remain blocked externally, but these existing source rules can regress silently before those inputs arrive. The contract provides measurable unblocked M6 progress without claiming that static analysis is gameplay or device QA.

**Alternative considered:** Wait for a device/B2 packet, write a headless Godot test locally despite the unavailable local engine, or add a synthetic Highrise profile.

**Why not selected:** Waiting leaves high-value Desert services unprotected. Local Godot runtime validation is unavailable in this workspace. A synthetic Highrise profile would violate the coordinate gate. The suite only validates existing source responsibilities and leaves physical/runtime claims to their actual gates.

## D-047 — Enforce catalog/source localization parity before rendered QA

**Decision:** Add a dependency-free localization validator and regression suite. It requires `data/localization/redline.csv` to contain the exact `keys,en,bn` header, valid unique keys, non-empty English/Bengali values with Bengali-script content, the existing `LocalizationService` loader/locale registration contract, and coverage for literal, helper-routed, input-binding, caption, settings, and session-mode GDScript keys.

**Reason:** The roadmap calls for English/Bengali UI, live locale selection, and accessibility/localization completion. The catalog already contains reviewed bilingual content, but a future UI key or CSV edit could silently leave one language untranslated. The check protects those existing routes while physical rendered-glyph/device review remains unavailable.

**Alternative considered:** Rely on manual catalog review, generate Godot import artifacts, or claim the source catalog proves device localization.

**Why not selected:** Manual review does not catch every consumer route; generated artifacts are deliberately not tracked; and source strings cannot prove font rendering, locale switching, or touch readability. The validator is an additive source safeguard only.

## D-048 — Bound CI artifact retention and make legacy cleanup explicitly authorized

**Decision:** Retain Android evidence artifacts for seven days and upload them only for Android export/normal-Boot failures or a successful Android launch gate. Add a separate manually dispatched cleanup workflow that requires the exact `DELETE_LEGACY_ARTIFACTS` confirmation, a supplied cutoff, and deletes only non-expired `operation-redline-android-debug` artifacts created before that cutoff.

**Reason:** The artifact audit found 75 duplicate bundles totaling about 4.95 GB. Their storage-quota exhaustion blocks uploads even though renderer evidence is committed and no emulator-only timeout should be represented as delivery. The current CLI token may list but cannot delete artifacts (HTTP 403), so the repository-owned workflow needs narrowly scoped `actions: write` authority rather than broadening unrelated build permissions.

**Alternative considered:** Keep uploading every timeout, delete artifacts automatically on every build, add broad `actions: write` to the Android build workflow, or silently discard historical evidence.

**Why not selected:** Repeated timeout uploads recreate the quota issue. Automatic cleanup is destructive and hard to audit. The Android build does not need artifact-deletion authority. The manual workflow makes the target, cutoff, confirmation, and action log reviewable while commits/releases remain untouched.
