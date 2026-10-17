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
