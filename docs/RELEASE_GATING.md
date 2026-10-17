# Downloadable APK Release Gate

## Policy

A GitHub pre-release APK is a player-downloadable in-place update, not merely an export artifact. Starting with the Batch 13 workflow policy, it may be created only when all of these checks succeed in the same run:

1. source/static/native checks;
2. Godot import, Android debug export, ZIP integrity, and APK signature verification;
3. normal-Boot gameplay-flow checks and renderer capture gates; and
4. the Android emulator install/launch step, including crash-log scan.

The release step explicitly requires the `android_export`, `gameplay_smoke`, and `android_emulator` step outcomes to be `success`. `tools/validate_project.py` rejects source changes that remove the named emulator gate from the workflow.

## In-place update compatibility

The workflow continues to use the existing package identifier and restores/caches the persistent `operation-redline-debug.keystore`. This preserves the package/signing prerequisites for Android's `adb install -r` update path. It does not prove a device update unless the emulator/device install gate actually succeeds.

## Historical candidate status

Earlier workflow revisions could publish pre-release candidates after export/headless success even when the Android emulator timed out. Those historical releases are retained as auditable records and are not retroactively relabelled or removed in this batch. They are **not** physical-device-tested deliveries and must not be offered as such. The new gate applies to every future candidate release.

## Evidence boundary

Artifact upload quota and hosted-emulator availability remain independent infrastructure risks. A quota-blocked archive is not an APK delivery. An emulator timeout is not a passing device result. A successful future release created through this gate still represents emulator evidence; physical-device testing is separately recorded.
