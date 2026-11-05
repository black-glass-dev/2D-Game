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

The current [GameCI `unity-builder` v6 source](https://github.com/game-ci/unity-builder/blob/v6.0.0/src/index.ts) states that Unity credentials are read from the process environment as `UNITY_EMAIL`, `UNITY_PASSWORD`, `UNITY_SERIAL`, `UNITY_LICENSE`, or `UNITY_LICENSING_SERVER`, rather than command arguments. The companion [GameCI `unity-activate` action](https://github.com/game-ci/unity-activate/blob/v2.0.0/src/index.ts) has the same environment-only contract. `unity-android.yml` therefore passes only these two expected GitHub Actions secret references to `game-ci/unity-builder@v6`:

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
and retains the review artifact seven days.

The current GitHub integration returned HTTP 403 when attempting to enumerate
secret names, so the repository's exact secret identifiers could not be read and
no values were accessed. If the existing secret names differ from
`UNITY_EMAIL`/`UNITY_PASSWORD`, change only the two references above (or provide
the secret **names**, never the values). The GitHub API also returns 404 when
trying to dispatch a workflow that exists only on this unmerged branch, so the
first requested build uses the narrow marker-trigger described above. GitHub
Actions billing/spending must permit the job to start before Unity activation or
APK export can be claimed.

## Android signing boundary

Unity preserves the Android application ID, but a Unity APK cannot truthfully be
claimed to update the historical Godot APK in place until it is signed with the
same certificate. The previous debug keystore is not available to this migration
workflow as a reviewed Unity signing secret. A tester must be prepared to
uninstall the withdrawn historical package for the first Unity review install,
unless the identical keystore is separately supplied through a protected build
mechanism.

## What remains before a complete Unity migration

1. Restore GitHub Actions billing/spending eligibility and use the manual Unity
   workflow to prove license activation, Unity import/compile, Android export,
   APK hash, and artifact retrieval.
2. Install that APK on a real Android device and prove localized Map Select,
   Desert load, touch controls, audio, gameplay, Android Back, results, and
   D01–D12 evidence.
3. Continue feature-parity ports from the Godot reference: advanced HUD editor,
   keyboard/gamepad rebinding, accessibility/colorblind/haptics controls,
   result persistence, tactical radar, weapon variants/effects, settings depth,
   graphics/performance tuning, and evidence capture.
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
