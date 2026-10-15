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
