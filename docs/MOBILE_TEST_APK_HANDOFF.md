# Mobile Test APK Handoff — Candidate 87 Withdrawn

## Do not use candidate 87 for further play testing

The historical GitHub pre-release **`apk-candidate-87`** is **withdrawn as a
mobile-test input**. A real Android tester supplied a screenshot on 2026-10-25
showing raw localization keys (`app.title`, `menu.map_select`, `menu.no_maps`)
and an empty map-selection list. That is a factual blocked player experience:
there is no playable map from that screen.

The screenshot does not contain the device identity, Android build, APK hash, or
a completed D01–D12 record, so it is not a physical-device PASS/FAIL matrix. It
is nevertheless sufficient evidence that this package must not be presented as a
playable handoff. **Do not install, redistribute, or continue testing candidate
87 as if it contained a usable game.**

## Retained identity for audit only

| Field | Value |
| --- | --- |
| Release | [Operation Redline debug APK candidate #87](https://github.com/islamyousuf032-glitch/2D-Game/releases/tag/apk-candidate-87) |
| Historical direct asset | [OperationRedline-debug.apk](https://github.com/islamyousuf032-glitch/2D-Game/releases/download/apk-candidate-87/OperationRedline-debug.apk) |
| Source commit | `eb43e0bb097492f217cc5da4922e7077aa258069` |
| Release timestamp | `2026-10-17T12:45:57Z` |
| Asset size | `68,613,858` bytes |
| GitHub asset SHA-256 | `77014c03daae21b395dd349c73188fab4c4681d050f543f2734bb96358395431` |
| Expected package ID | `com.operationredline.outpost` |

These values identify the rejected historical asset only. They are not a
recommendation to download it.

## Repair and replacement path

The defect is consistent with Android export content that was only found through
runtime directory/file access: loose-source checks could see the CSV and map
resources while the package shown to the tester could not. The repair now:

1. generates a GDScript translation catalog from the reviewable CSV so every
   English/Bengali message is an exported resource;
2. generates preload anchors for every `data/maps/*.tres` resource while keeping
   runtime map-folder discovery; and
3. runs `--verify-export-content` from an exported PCK in an otherwise empty
   directory before a human-review APK may be published.

A one-time **explicitly unvalidated human-review APK** is requested from the
repaired source through `.github/workflows/human-review-apk.yml`. It will be
published only after source/native checks, Godot import, APK archive/signature
verification, and the exported-PCK translation/playable-Desert check pass. The
first requested run ([40203309780](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/40203309780)) did not start: GitHub reported that recent account payments failed or the Actions spending limit needs increasing. Therefore no replacement APK URL exists yet. It will still not be an emulator pass, release candidate, supported delivery, or physical-device PASS when it does run.

## When the repaired human-review build is available

Use [`PHYSICAL_ANDROID_HANDOFF.md`](PHYSICAL_ANDROID_HANDOFF.md) and
[`PHYSICAL_DEVICE_QA.md`](PHYSICAL_DEVICE_QA.md). Return the following with the
new build's exact release URL and SHA-256:

- tester/reviewer name and timezone;
- device model, Android version/build, screen resolution, and refresh rate;
- exact APK hash and install/update output;
- screenshots/video of localized Boot and Map Select showing **Desert Outpost**;
- concrete D01–D12 observations, including play duration and thermal/FPS notes;
  and
- factual collector output where USB debugging is available:

```sh
./docs/capture_physical_android_qa.sh \
  --apk /absolute/path/OperationRedline-debug.apk \
  --serial <authorized-adb-serial> \
  --output /absolute/path/operation-redline-physical-qa-YYYYMMDD
```

A record is `PHYSICAL_DEVICE_TESTED` only after a named reviewer supplies real
observations and concrete evidence for all D01–D12 rows. `MP_RF_02` Highrise
remains locked; a phone test does not authorize guessed Highrise geometry,
traversal, or Gate 2 evidence.
