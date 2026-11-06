# Physical Android QA Handoff

## Purpose

This handoff is the physical-device path for Operation Redline. It does **not**
replace the emulator release gate and it does not make a downloaded APK tested.
Use it only with the exact APK, source commit, Android device, and reviewer that
will be named in a completed physical-evidence record.

The attached-device collector is `docs/capture_physical_android_qa.sh`. It is
intentionally a factual collector: it never assigns D01–D12 results and never
writes `PHYSICAL_DEVICE_TESTED`.

[`MOBILE_TEST_APK_HANDOFF.md`](MOBILE_TEST_APK_HANDOFF.md) records a real-device
blocker in historical candidate 87 (raw translation keys and no map card) and
withdraws it from testing. Wait for the separately labelled repaired
human-review build; it remains an explicitly unvalidated test input, not a
current tested-release claim.

## Preconditions

1. Use the exact debug APK and source commit under review.
2. Confirm the APK has the expected package ID:
   `com.operationredline.outpost`.
3. Enable USB debugging on the physical Android device and confirm that the
   operator is authorized by `adb devices -l`.
4. Retain the existing app when checking an update. The required install path is
   `adb install -r`, not uninstall/reinstall.
5. Create a separate, empty evidence directory outside a source commit or in a
   reviewer-managed evidence store. Do not overwrite an earlier collection.
6. Prepare a copy of `docs/physical_qa_evidence.template.json`; the committed
   template must remain a non-evidence template.

## Collect factual install and launch material

Run one collector session per APK/device pair:

```sh
chmod +x docs/capture_physical_android_qa.sh
./docs/capture_physical_android_qa.sh \
  --apk /absolute/path/OperationRedline-debug.apk \
  --serial <adb-serial> \
  --output /absolute/path/operation-redline-physical-qa-YYYYMMDD
```

Omit `--serial` only when exactly one authorized device is attached. The tool
records:

- `apk.sha256` and a timestamped capture manifest;
- connected-device state/serial and raw device property output;
- the exact `adb install -r` output and exit code;
- package lookup, launch output, resumed-activity dump, and bounded logcat;
- a crash-pattern scan result.

A successful collector run proves only that those files were collected. It does
not prove touch controls, language, audio, gameplay, thermal behavior, or any
D01–D12 result.

## Manual D01–D12 review

A named reviewer must exercise and record every matrix item from the template:

- **D01:** verify the same signed package updates in place through `adb install -r`.
- **D02:** verify landscape boot and return flows.
- **D03–D05:** verify movement/look, FIRE safety, AIM/RELOAD/action HUD, and
  control layout editing on touch hardware.
- **D06–D08:** verify connected keyboard/mouse, gamepad, Android Back,
  focus-loss/mute/restore behavior as applicable to the device setup.
- **D09–D10:** verify settings persistence, Bengali/English localization,
  explicit quality choice, and audible mix.
- **D11:** verify the Desert survival baseline: waves, score, HP, HUD, and
  controls remain intact.
- **D12:** record concrete performance/thermal observations with the selected
  quality tier and a defined play duration.

Each D01–D12 row must contain a concrete evidence path and reviewer-written
notes. A failure or block remains `FAIL`/`BLOCKED`; it must not be changed to
`PASS` to unblock delivery.

## Complete and validate the record

Populate all source/APK/device/reviewer fields in a copy of the template. Keep
paths/references concrete, include the exact `adb install -r` command and
install-output path, and classify the record accurately:

```sh
python3 tools/validate_physical_qa_evidence.py /absolute/path/completed-record.json
```

Only a complete record with all twelve rows `PASS` may use
`PHYSICAL_DEVICE_TESTED`. Any `FAIL` or `BLOCKED` row must be classified as
`NOT_PHYSICAL_DEVICE_TESTED`.

## Current release boundary

The hosted emulator remains boot-blocked, so it has not installed or launched
the APK. This physical procedure is prepared for a real attached device; it is
not evidence that such a device test has occurred.
