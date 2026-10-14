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
