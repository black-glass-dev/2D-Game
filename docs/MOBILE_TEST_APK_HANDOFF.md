# Mobile Test APK Handoff — Historical Candidate 87

## What this package is

The newest retained downloadable package available for a **real Android tester**
is the historical GitHub pre-release **`apk-candidate-87`**. It is being handed
off only so a tester can install it on their own phone and collect factual
feedback. It is **not** the current-branch APK, a current release candidate, an
emulator pass, a physical-device pass, or a supported player delivery.

The sandbox cannot retrieve GitHub release binaries because GitHub redirects
release-asset downloads to a host outside the sandbox's permitted network
allowlist. The direct GitHub URL below is intended for the tester's normal mobile
browser, where that redirect is handled by GitHub.

## Exact release identity

| Field | Value |
| --- | --- |
| Release | [Operation Redline debug APK candidate #87](https://github.com/islamyousuf032-glitch/2D-Game/releases/tag/apk-candidate-87) |
| Direct APK download | [OperationRedline-debug.apk](https://github.com/islamyousuf032-glitch/2D-Game/releases/download/apk-candidate-87/OperationRedline-debug.apk) |
| Source commit | `eb43e0bb097492f217cc5da4922e7077aa258069` |
| Release timestamp | `2026-10-17T12:45:57Z` |
| Filename | `OperationRedline-debug.apk` |
| Expected size | `68,613,858` bytes |
| GitHub asset SHA-256 | `77014c03daae21b395dd349c73188fab4c4681d050f543f2734bb96358395431` |
| Package ID expected by the project | `com.operationredline.outpost` |

The SHA-256 and size above are GitHub release-asset metadata. If the downloaded
file differs, **do not install or test it**; download it again from the release
page.

## Install on the tester's Android phone

1. Open the **Direct APK download** link above in the phone's browser and finish
downloading the file.
2. Verify the displayed filename and, if the file manager supports checksums,
verify the SHA-256 above.
3. Android may require permission for the browser/file manager to install an
unknown app. Grant that permission only for this reviewed debug-package install,
then revoke it afterwards if desired.
4. Install the APK. Do **not** claim it updated an earlier install in place
unless the exact install output or Android UI observation supports that result.
5. Start the app and retain screenshots/video/logs for the real-device reviewer.

The package is a debug pre-release. It is not a store build and must not be
redistributed, described as current, or described as tested/supported delivery.

## What to test and return

Use [`PHYSICAL_ANDROID_HANDOFF.md`](PHYSICAL_ANDROID_HANDOFF.md) and
[`PHYSICAL_DEVICE_QA.md`](PHYSICAL_DEVICE_QA.md) as the source of truth.
Provide the reviewer with:

- tester/reviewer name and timezone;
- device model, Android version/build, screen resolution and refresh rate;
- downloaded APK SHA-256 and install method/output;
- screenshots/video for Boot, touch controls, Bengali/English settings, quality
  selection, results, and any failure;
- concrete observations for D01–D12, including play duration and thermal/FPS
  notes; and
- if a USB-debugging computer is available, the factual collector output from:

```sh
./docs/capture_physical_android_qa.sh \
  --apk /absolute/path/OperationRedline-debug.apk \
  --serial <authorized-adb-serial> \
  --output /absolute/path/operation-redline-physical-qa-YYYYMMDD
```

The collector and a filled evidence record may validate facts, but they do not
turn missing observations into `PASS`. A record can be classified
`PHYSICAL_DEVICE_TESTED` only when every D01–D12 row has a real reviewer
observation and concrete evidence path.

## Current boundaries

- Candidate 87 predates the current source branch, so feedback applies to its
  recorded source commit unless and until a current-source APK is exported.
- The current Android emulator remains launch-blocked; its timeout is not a
  device test.
- `MP_RF_02` Highrise remains locked because the authoritative B2 numeric
  appendix and reference image are absent. A phone test does not authorize
  guessed Highrise coordinates, geometry, traversal, or Gate 2 evidence.
