# Baseline Registration Audit

**Recorded:** 2026-10-14 (Asia/Dhaka)

**Purpose:** Protect the previously playable project before M1 architecture work.

## Source-control reconciliation

At session start, the working tree content matched the published Arena branch but its local index only registered `README.md`. Before changing gameplay or configuration, the workspace was compared byte-for-byte against `origin/arena/e2b9c124-2d-game`.

- Remote baseline commit: `5e7142329b4b28f756546857a807b01559a0f877`
- Comparison result: every remote-tracked project file matched the workspace exactly.
- Intentional local differences before reconciliation:
  - `docs/PLAN.md` — replaced by the current director-approved production plan.
  - `docs/RECON.md` — new Recon report.
- Audit report SHA-256: `d905d6a313ef29a625b97d94efc14db5560cf73943dd0516e67715935cb972c7`
- Safety archive SHA-256: `e9a71d561a9b69dc8d7801a0e2be8405160bab3e367ce5fc347335e356139b03`

The local branch was then reset to the verified remote baseline before the two Recon documents were restored. No gameplay, asset, or configuration content was discarded because the audit established byte identity first.

## Baseline quality gates

| Gate | Result |
| --- | --- |
| GDScript analysis | PASS — 13 scripts, 0 errors, 0 warnings |
| Resource consistency | PASS — 30 `res://` links and 4 original 128×128 textures |
| Native survival tests | PASS — 3 waves, 27 spawns, completion state |
| Whitespace check | PASS — `git diff --check` produced no findings |

## Registration rule

All later batches must start from a clean, committed working tree. Generated Godot caches, Node dependencies, export products, keys, and locally downloaded tool data remain excluded by `.gitignore`.
