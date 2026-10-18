# Physical Android QA Checklist

> This is a test procedure and evidence template, **not** a completed device-test record. Do not mark a row PASS unless the listed observation and evidence exist for the exact APK under test.

## Preconditions

1. A future CI run must have created a candidate through the device-validated release gate in [`RELEASE_GATING.md`](RELEASE_GATING.md), or the tester must provide an equivalently signed local APK.
2. Record the exact source commit, APK SHA-256, package version code/name, device model, Android version/build, screen resolution/refresh rate, and tester/timezone in `physical_qa_evidence.json` made from [`physical_qa_evidence.template.json`](physical_qa_evidence.template.json).
3. Preserve the install console output from `adb install -r <apk>`; `-r` is the in-place update check and must not be replaced by an uninstall/reinstall for that row.
4. Capture landscape screenshots/video and `adb logcat -d -t 1200` after the test. Redact no game-state evidence; do not include personal notifications or account information.

## Required matrix

| ID | Area | Procedure | Pass condition | Required evidence |
| --- | --- | --- | --- | --- |
| D01 | Install/update | Install the exact APK with `adb install -r`; launch `com.operationredline.outpost`. | Installs over the prior same-signature build and reaches Boot without crash. | Install output, version fields, logcat. |
| D02 | Landscape / Boot | Cold start, rotate only if the OS allows it, and wait through Splash → Menu. | Landscape is retained; no clipped title/buttons or unintended portrait surface. | Boot screenshot/video. |
| D03 | Touch movement/look | Use left movement control and right look region for at least 30 seconds in Desert. | Movement and look are smooth; no stuck control after lift. | 30-second video. |
| D04 | Touch fire safety | Tap neutral HUD/background areas, then FIRE only; repeat for SINGLE and hold-to-fire AUTO. | Neutral taps never fire; FIRE works only from visible control; SINGLE/AUTO behavior is distinct. | Video with mode selection visible. |
| D05 | Touch actions | Exercise AIM, RELOAD, swap, jump, crouch, pause, HUD-layout editor, resized/moved controls, and left-handed option. | Every visible target responds and saved layout survives a relaunch. | Before/after HUD screenshots and video. |
| D06 | Keyboard/mouse | Connect supported keyboard/mouse or desktop-equivalent Android setup; test movement, aim, fire, reload, pause, Escape/back. | Named actions work without breaking visible touch controls. | Short video or input log. |
| D07 | Gamepad | Test left stick, face buttons, pause, menu accept, controller B/back, and deadzone setting. | Input maps correctly; Back follows deterministic menu/pause route. | Video and selected deadzone value. |
| D08 | Android Back / focus | From Splash, Settings, Map Select, Pause settings, and Main Menu, use Android Back. Background/foreground the app with mute-when-unfocused on/off. | Each route matches UI hint; focus policy mutes/restores without changing saved Master volume. | Route video and settings screenshots. |
| D09 | Settings / language | Verify AUTO locale, English, Bengali, quality tiers AUTO/LOW/MEDIUM/HIGH/ULTRA, slider persistence, and reset confirmation. | Bengali glyphs are readable; explicit LOW remains procedural menu fallback and non-LOW remains static; settings persist. | One English and one Bengali screenshot; HIGH/LOW menu frames. |
| D10 | Audio | At default, zero, and restored Music volume, play/reload/land and navigate menus with headphones/speaker. | Music is below tactical SFX; zero stops it; restored volume resumes it; focus mute behaves correctly. | Listening result, volume values, and logcat. |
| D11 | Survival regression | Complete/retry a three-wave Normal/Survival operation; also start selected difficulty/mode paths. | Score/HP/HUD, waves, result persistence, and retry/map return remain correct. | Result screenshot, Save record screenshot, logcat. |
| D12 | Performance / thermal | Run 10 minutes on each relevant explicit quality tier. | No sustained control failure, fatal error, or unexplained severe throttling; report measured FPS/thermal observations rather than guessing. | Per-tier notes/video and logcat. |

## Evidence review rule

Copy the schema-versioned template to a separate, untracked-or-reviewable `physical_qa_evidence.json`; never overwrite the committed template with a test result. Set its status to `PHYSICAL_DEVICE_EVIDENCE` only after a real run. A completed record is accepted only when it includes the exact source SHA, APK SHA-256/version/package, exact non-placeholder `adb install -r` command and output reference, device identity/input hardware, logcat reference, reviewer/time, and every required row with a PASS/FAIL/BLOCKED value, non-empty observation, and at least one concrete evidence reference.

Validate a proposed record before release review:

```bash
python3 tools/validate_physical_qa_evidence.py physical_qa_evidence.json
```

All-PASS rows are the only route to `PHYSICAL_DEVICE_TESTED`. Any FAIL or BLOCKED row must retain `NOT_PHYSICAL_DEVICE_TESTED`, even though the record remains valuable evidence. The validator rejects a template that is modified to claim PASS, blank identity/install/logcat fields, unreferenced rows, placeholder commands, malformed hashes, and a false release classification. Record observed problems verbatim; do not convert a timeout, missing clip, or unavailable hardware into PASS.
