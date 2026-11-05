# Unity Migration — Operation Redline

## Decision and scope

The requested target is a **Unity Android project** under `unity/`. The Godot
project remains intact during migration as the only detailed behavior reference
and rollback source; it must not be deleted before a Unity APK is exported and a
real tester can enter the Desert operation. The Unity project is the forward
implementation target, not a claim that existing Godot packages are usable.

## Implemented Unity baseline

The committed Unity 2022.3.62f1 project contains a runnable Bootstrap scene and
code-owned runtime root with these player-facing systems:

- localized English/Bengali Splash, Main Menu, Settings, and Map Select;
- one **playable** `MP_DS_01` Desert Outpost card and an honest locked
  `MP_RF_02` Highrise card;
- procedural 3D desert/outpost, first-person keyboard/mouse and mobile-touch
  movement/look, touch/desktop FIRE route, pause/Android Back route, HUD, and
  crosshair;
- 6/9/12 Desert survival waves, raider pursuit/damage, raycast shooting,
  score/HP HUD, mission-complete/failure panel, restart, and map return;
- persisted Unity language/quality/music settings; original menu backdrop,
  Noto Bengali fonts, and project audio copied under Unity `Resources`; and
- Android identity `com.operationredline.outpost`, landscape orientation,
  arm64 target, and minimum API 23.

The Unity source is an actual vertical-slice port, not a scene screenshot or an
empty folder. It is not yet build/import/device evidence.

## License automation research and safe workflow

The current [GameCI `unity-builder` v6 source](https://github.com/game-ci/unity-builder/blob/v6.0.0/src/index.ts) states that Unity credentials are read from the process environment as `UNITY_EMAIL`, `UNITY_PASSWORD`, `UNITY_SERIAL`, `UNITY_LICENSE`, or `UNITY_LICENSING_SERVER`, rather than command arguments. The companion [GameCI `unity-activate` action](https://github.com/game-ci/unity-activate/blob/v2.0.0/src/index.ts) has the same environment-only contract. The user has confirmed the repository's exact email/password secret identifiers, so `unity-android.yml` passes only these two environment references to `game-ci/unity-builder@v6`:

```yaml
env:
  UNITY_EMAIL: ${{ secrets.UNITY_EMAIL }}
  UNITY_PASSWORD: ${{ secrets.UNITY_PASSWORD }}
```

The workflow never prints credentials, never places them in command arguments,
and has a non-empty preflight that reports only whether the secret references are
available. The requested first branch build is allowed only by the one-time
`[build-unity-review-apk]` commit marker; later builds require explicit manual
confirmation `BUILD_UNITY_REVIEW_APK`. It checks the APK ZIP, produces SHA-256,
and retains the workflow artifact seven days. After those checks succeed, it also
publishes a prerelease tagged `unity-human-review-<commit>` containing the exact
APK and SHA-256. That public handoff is explicitly unvalidated: it is for the
named tester's mobile review, not an emulator-gated candidate, signing proof,
or device-pass claim.

The GitHub integration returned HTTP 403 when attempting to enumerate secret
names, so no values were accessed or disclosed. Earlier runs passed source/C#
syntax validation and exited before activation when their credential preflight
found unavailable references. Once the repository's Actions-secret configuration
was corrected, successful protected run
[42033864492](https://github.com/black-glass-dev/2D-Game/actions/runs/42033864492)
passed credential preflight, Unity license activation/build, APK ZIP validation,
SHA-256 generation, artifact upload, and review-prerelease publication. Its
[Unity human-review release](https://github.com/black-glass-dev/2D-Game/releases/tag/unity-human-review-d2b24d452afc)
contains `OperationRedline-Unity-review.apk` and its `.sha256` sidecar. The
release is explicitly unvalidated: this CI evidence does not assert emulator
launch, physical-device behavior, signing compatibility, visual parity, or
Highrise acceptance. The GitHub API's 403 secret-metadata boundary remains
appropriate; the only credential evidence recorded is that the protected
references were non-empty in the successful job.

## Android renderer correction — 2026-11-05

A user-provided Android screenshot from the first Unity review APK showed the
Desert ground as solid magenta. In Unity, that color is the visible failure mode
for a missing, unsupported, or stripped material shader. The runtime had been
using the implicit material supplied by `GameObject.CreatePrimitive`, which is
not a safe Android shipping dependency when the project has no serialized
material reference to preserve its shader.

The correction replaces every runtime world primitive (ground, structures,
raiders, and tracers) with the bundled `Resources/Shaders/OperationRedlineMobile`
shader. It also adds an original, deterministic `desert_outpost_ground.png`
sand/track/stone texture, tileable terrain material, outpost gate, signal mast,
fuel drums, sandbag walls, and radio array so the playable view is no longer a
flat placeholder. Source/mutation validation requires both the shader and
texture. Run [42033864492](https://github.com/black-glass-dev/2D-Game/actions/runs/42033864492)
completed Unity Android build, archive/hash verification, and review-release
publication for this correction. This establishes build/package evidence only;
the user must install the replacement APK and confirm that the actual device
no longer renders magenta terrain.

## Android signing boundary

Unity preserves the Android application ID, but a Unity APK cannot truthfully be
claimed to update the historical Godot APK in place until it is signed with the
same certificate. The previous debug keystore is not available to this migration
workflow as a reviewed Unity signing secret. A tester must be prepared to
uninstall the withdrawn historical package for the first Unity review install,
unless the identical keystore is separately supplied through a protected build
mechanism.

## What remains before a complete Unity migration

1. Install the published review APK on a real Android device and prove localized
   Map Select, Desert load, touch controls, audio, gameplay, Android Back,
   results, and D01–D12 evidence. This is the named tester's remaining activity;
   no result may be inferred from the CI build.
2. Resolve signing/in-place-update compatibility separately from preserved
   application-ID evidence, if an update over a historical install is required.
3. Finish external-only gates: authoritative Highrise B2 coordinates/reference,
   performance tuning from a real device profile, and full
   visual/audio/tactical-radar parity review.

The Unity source now includes persisted bilingual settings in Graphics, Audio,
Controls, Accessibility and Other sections; player movement with sprint, jump,
crouch, aiming, mobile look/joystick controls and gamepad-axis deadzone; two
ammo/reload/swap weapons; difficulty and Survival/Endless selection; result
accuracy/best-record persistence; sound captions, focus mute, haptics,
colorblind HUD, screen-effects preference, resolution-independent persistent HUD
layout editing, and a conflict-safe keyboard binding baseline. These are
source-level contracts until a Unity import/build proves them.
4. Keep `MP_RF_02` locked until its authoritative B2 reference/coordinate inputs
   arrive; Unity does not authorize guessed Highrise geometry or traversal.
5. Only after parity and device validation, retire/archival-plan the Godot build
   pipeline deliberately rather than deleting the fallback during a migration.

## Validation boundary

`tools/validate_unity_migration.py` and its mutation suite protect Unity version,
Android identity/orientation/architecture, Bootstrap scene, playable Desert
6/9/12 baseline, locked Highrise wording, mobile/back/combat contracts, migrated
resources, safe GameCI configuration, and no credential echo. They do not run
Unity, activate a license, export an APK, or test a device.
