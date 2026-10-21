# CI Artifact Retention and Storage Recovery

**Last audited:** 2026-10-20 (Asia/Dhaka)

## Purpose

GitHub Actions artifacts are useful for actionable import/runtime failures and a
future emulator-launch-gated APK candidate, but they are not the project's release-delivery
record. Verified renderer frames and failure diagnostics are retained in the
branch; a successful future player-downloadable APK must be published through
the launch-gated GitHub pre-release path in `RELEASE_GATING.md`.

## Audit before cleanup

A GitHub Actions API inventory was first recorded on 2026-10-19 and repeated
read-only on 2026-10-20. Both audits found **75 active** artifacts named
`operation-redline-android-debug`, totaling **4,954,824,380 bytes**. Repeated
hosted-emulator boot timeouts had retained duplicate debug APK/capture bundles
from routine non-device runs and exhausted the repository's artifact-storage
allowance.

The retention cleanup removes only workflow artifacts created before
`2026-10-14`, preserving release files, commits, current source logs/frames, and
all artifacts created on or after that date. The selected set is **53 artifacts**
totaling **3,337,865,269 bytes**; the retained newer set is **22 artifacts**
totaling **1,616,959,111 bytes**.

The current command-line GitHub integration was audited against the first selected ID and returned `HTTP 403: Resource not accessible by integration`; it could list artifacts but did not have authority to remove them. No artifact was deleted by that failed call. To keep the cleanup permission narrow and auditable, `.github/workflows/cleanup-legacy-artifacts.yml` now offers a manual workflow with `actions: write`, an explicit `DELETE_LEGACY_ARTIFACTS` confirmation, a reviewer-supplied ISO cutoff, and a hard-coded artifact-name filter. It cannot remove releases, source commits, or any artifact outside that exact pre-cutoff filter.

Selected artifact IDs, recorded for the confirmed cleanup workflow:

```text
11391067371, 11391183643, 11391502361, 11392194100, 11392841356,
11478778747, 11660809002, 11661243196, 11661909038, 11662935539,
11663274030, 11663965603, 11665439510, 11669022184, 11670055968,
11670960767, 11671022867, 11699232364, 11705983814, 11726969949,
11727254580, 11727594649, 11728745137, 11728875229, 11728251224,
11729040436, 11728641794, 11728578668, 11729331545, 11729272681,
11729705227, 11729890388, 11734713747, 11735273550, 11736856890,
11742163502, 11741914760, 11744120270, 11743758073, 11746495446,
11786601965, 11787445458, 11787219203, 11793040032, 11793056085,
11793245764, 11801701309, 11802143197, 11803755653, 11811931447,
11819390558, 11820470378, 11826842882
```

## Independent post-cleanup verification

The cleanup workflow is the only repository component that may delete an
artifact. `tools/audit_legacy_artifacts.py` is deliberately **read-only**: it
uses `gh api --paginate --jq '.artifacts[]'` only to list every page, then
filters the exact audited name, active state, and cutoff locally. It does not
call a delete endpoint and can be run with a listing-only integration. Separately,
`tools/validate_cleanup_workflow.py` and its mutation suite make source checks
reject an automatic trigger, weakened confirmation, broadened name filter, or
non-strict cutoff before the destructive workflow can reach the default branch.

Before dispatch, a reviewer can confirm the audited scope still matches the
recorded inventory:

```sh
python3 tools/audit_legacy_artifacts.py \
  --repo islamyousuf032-glitch/2D-Game \
  --cutoff 2026-10-14T00:00:00Z \
  --expect-pre-cutoff-count 53
```

Only after the workflow is available on the default branch, manually dispatched
with the exact `DELETE_LEGACY_ARTIFACTS` confirmation and cutoff, and has a
completed GitHub Actions result, independently verify that it left no active
matching artifact before that cutoff:

```sh
python3 tools/audit_legacy_artifacts.py \
  --repo islamyousuf032-glitch/2D-Game \
  --cutoff 2026-10-14T00:00:00Z \
  --verify-cleanup
```

A zero-candidate result verifies the bounded inventory state, not an Android
launch, physical-device run, APK delivery, or immediate storage-quota refresh.
GitHub's reported usage may still take several hours to recalculate.

## Forward policy

The Android workflow now uses a seven-day artifact retention period. It uploads
the bundle only when Android export or normal-Boot runtime QA itself fails, or
when the Android launch gate succeeds. Renderer captures are already committed
after validation. On the successful-launch path, that upload now has to succeed
before a pre-release candidate can be published. A hosted-emulator-only timeout
therefore cannot consume another APK archive while still retaining source logs
and committed evidence. Legacy cleanup is deliberately manual through the
bounded confirmation workflow above; it is never performed automatically during
a build.

CI run [39271155212](https://github.com/islamyousuf032-glitch/2D-Game/actions/runs/39271155212) then confirmed the forward policy: all non-device gates passed, the hosted emulator alone timed out, and `Upload tested build evidence` was skipped rather than quota-failing. PR [#2](https://github.com/islamyousuf032-glitch/2D-Game/pull/2) subsequently merged the bounded cleanup workflow to the default branch. Its exact default-branch source, confirmation, name filter, and strict cutoff were rechecked before dispatch.

A manual default-branch dispatch was then attempted with the documented exact
`2026-10-14T00:00:00Z` cutoff and `DELETE_LEGACY_ARTIFACTS` confirmation. The
current GitHub CLI integration returned `HTTP 403: Resource not accessible by
integration` while creating the dispatch event. No cleanup workflow run was
created, no artifact was deleted, and an immediate independent read-only audit
still found the original 75 active artifacts / 53 pre-cutoff candidates /
3,337,865,269 candidate bytes. A repository user or integration with authority
to dispatch Actions workflows must perform the same bounded default-branch
manual dispatch; only then may `--verify-cleanup` be used for the post-run
zero-candidate check.

GitHub states that artifact usage can take several hours to recalculate. This
storage recovery does not prove an emulator launch, physical-device test, APK
delivery, or release candidate. The existing same-run Android launch gate stays
mandatory.
