# Operation Redline — clean Unity rebuild plan

**Started:** 2026-11-06 (Asia/Dhaka)  
**Execution decision:** the previous code-owned Unity migration prototype is now
**retired from runtime execution**. Its source remains in the repository only as
an audit/reference record; it is not the game started by `Bootstrap.unity`.

## Why this is a restart

The earlier Unity work was a newly authored/procedural replacement, not a
binary conversion of the Godot game. It produced valid Android packages and
fixed the visible magenta terrain, but the user reported two successive builds
as frozen/nonfunctional on a real Android phone. That makes its runtime/input
architecture unsuitable as the delivery baseline. Adding another visual control
to that runtime is not an acceptable repair.

The new implementation is a clean Unity runtime under
`Assets/RedlineRebuild/`. It intentionally does not instantiate `OperationGame`
or `OutpostPlayerController`. It uses the explicit Unity `com.unity.ugui`
package and EventSystem pointer ownership for the touch surfaces instead of
screen-wide `OnGUI` and raw-touch polling.

## Fixed product contract

1. **Platform:** Unity 2022.3.62f1, Android, landscape, arm64, API 23+.
2. **First playable delivery:** Desert Outpost (`MP_DS_01`) only. Highrise stays
   locked pending authoritative B2 material; no geometry will be invented.
3. **Language:** English/Bengali labels must remain available in the shipped
   flow.
4. **Mobile is primary:** visible EventSystem-owned Move, Look, Fire, Reload,
   Pause, and Resume routes; no visible control is accepted as working merely
   because it renders.
5. **Runtime proof:** simulation progresses on `Time.unscaledDeltaTime`, app
   focus/background pauses safely, a new session has an immediate visible
   contact, and the HUD exposes input/simulation/contact state for review.
6. **Assets:** temporary source-owned/material-safe assets are permitted now.
   The player's later asset drop replaces an asset manifest/prefab layer, not
   input, combat, state, or release code.
7. **Truthfulness:** build/package success remains different from phone success.
   No device-pass claim is made without physical evidence for the exact APK.

## Consolidated execution batches

| Batch | Work performed together | Exit evidence | Planned source/build completion |
| --- | --- | --- | --- |
| R1 — clean playable core | New runtime bootstrap; EventSystem/UGUI shell; Home → Desert → Results loop; direct move/look/fire pointer surfaces; CharacterController; unscaled simulation; immediate waves; basic enemy combat; pause/resume; safe shader/material world; runtime telemetry. | Source/mutation/C# contracts and fresh Android review APK. | 30% |
| R2 — complete mission loop | Weapon variants, hit feedback, health/ammo/reload UX, wave/objective director, score/results/save data, full Bengali/English menu/settings, audio/haptics/captions, Android Back flow. | Automated unit/source contracts plus new review APK. | 55% |
| R3 — presentation and asset seam | Replace temporary world pieces with a stable prefab/material manifest; ingest the player's supplied assets; lighting, VFX, audio mix, menu art, and accessibility/color contrast pass. | Asset provenance/import check, Android-safe rendering check, fresh review APK. | 75% |
| R4 — mobile hardening | Touch gesture soak checks, lifecycle/relaunch handling, low-memory/performance settings, different aspect-ratio layout checks, physical D01–D12 test script, crash/log collection. | Evidence-gated device review of the exact build. | 90% |
| R5 — release readiness | Signing/update compatibility, complete physical acceptance, store/release metadata, and only then candidate/release gating. | Device evidence and signing evidence. | 100% |

The batches are intentionally large. The default is to complete the whole next
batch without waiting for another design input. Only missing authoritative
Highrise references, an asset drop, or physical device evidence changes that
sequence.

## R1 implementation in this commit

- `OperationBootstrap` now starts `RedlineRebuildBootstrap`, not the retired
  prototype runtime.
- `RedlineRebuildGame` owns one explicit `Home → Playing → Paused → Results`
  state machine and never changes `Time.timeScale` for normal pause behavior.
- `RedlineRebuildTouchSurface` implements UGUI `IPointerDownHandler`,
  `IDragHandler`, `IPointerUpHandler`, and `ICancelHandler`; individual pointer
  controls own Move, Look, and Fire interactions until release.
- The live loop creates a CharacterController/camera, direct UGUI HUD,
  immediate enemy contacts, three wave rounds, raycast combat/reload, enemy
  pursuit/damage, failure/success results, and app-focus pause.
- After the first clean-runtime phone report that Start Operation did not visibly
  advance, R1 now starts directly on pointer-down, has a narrowly scoped
  primary-pointer fallback for the start rectangle, stages Home → loading →
  world → control initialization across frames, and renders a recoverable error
  screen instead of silently remaining on a frozen surface if initialization
  throws.
- The temporary Desert Outpost uses the repository's explicit Android-safe
  shader and reviewed ground/concrete/metal/crate textures. It has no reliance
  on Unity's default primitive material.
- `WAVE`, `CONTACTS`, `HP`, `SIM`, and input-status text are deliberate test
  telemetry, not a claim that a device test passed.

### R1 build evidence

Protected [run 42174955399](https://github.com/black-glass-dev/2D-Game/actions/runs/42174955399)
passed the migration contract, 16-file C# syntax parse, protected Unity license
activation/build, APK ZIP/hash verification, artifact upload, and prerelease
publication. Its explicitly unvalidated review APK is
[Unity human-review `56f01d882dd5`](https://github.com/black-glass-dev/2D-Game/releases/tag/unity-human-review-56f01d882dd5),
SHA-256 `939b3266e851e1e80a8b4e9955af5d8235396d54e74a44f1a94758153affc359`.
It is the first package from the new runtime, not evidence that a touch or
Android session has passed. The user subsequently reported that Start Operation
again failed to advance on their phone. The source now uses direct pointer-down
activation, a constrained start-region fallback, staged loading, and an
on-screen recoverable error path. The first staged-start source commit exposed
a C# coroutine rule during the protected build (a yield cannot be inside a
try/catch); it was corrected immediately by moving exception handling to
non-yielding initialization stages. Protected
[run 42187615965](https://github.com/black-glass-dev/2D-Game/actions/runs/42187615965)
then passed source validation, Unity build, ZIP/hash verification, artifact
upload, and publication for the replacement
[Unity human-review `e1f109f4bdf6`](https://github.com/black-glass-dev/2D-Game/releases/tag/unity-human-review-e1f109f4bdf6),
SHA-256 `c7990497cf85afb450bf8f175670f3823e246e32519ec1bf1689d1db4e00f6bb`.
It remains a replacement review build, not physical proof. The retained workflow
artifact `operation-redline-unity-android-review-17` expires 2026-11-13 08:32 UTC.

## Asset handoff seam

Until final art arrives, only these temporary references are used:

- `Resources/Textures/desert_outpost_ground.png`
- `Resources/Textures/outpost_concrete.png`
- `Resources/Textures/outpost_corrugated_metal.png`
- `Resources/Textures/outpost_weathered_crate.png`
- `Resources/Shaders/OperationRedlineMobile.shader`

The rebuild now includes a documented asset manifest and automatic Resource
resolver for the future prefab/texture keys. See
[`REBUILD_ASSET_INTEGRATION.md`](REBUILD_ASSET_INTEGRATION.md) for exact drop
locations and names. The supplied art will not require rewriting the stable game
loop or mobile controls.

## Remaining evidence boundary

R1 establishes a new source/runtime architecture and must be built before it
can be reviewed. It does not prove import, Android installation, touch events,
GPU rendering, performance, or device playability. Those claims remain blocked
until a tester exercises the newly built APK.
