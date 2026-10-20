#!/usr/bin/env python3
"""Validate source-level truthfulness of the Android candidate-release contract.

A GitHub-hosted emulator install/launch is an actionable release gate, but it is
not a physical-device result.  This validator keeps the workflow, release policy,
and physical-QA handoff aligned with that boundary.  It is intentionally a static
source check and does not establish export, emulator, physical-device, or release
success.
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class ReleaseContractError(ValueError):
    """The source-level release contract is missing, unsafe, or misleading."""


def fail(message: str) -> None:
    raise ReleaseContractError(message)


def require_file(root: Path, relative_path: str) -> str:
    path = root / relative_path
    if not path.is_file():
        fail(f"missing required file: {relative_path}")
    return path.read_text(encoding="utf-8")


def require_snippets(relative_path: str, content: str, snippets: tuple[str, ...]) -> None:
    for snippet in snippets:
        if snippet not in content:
            fail(f"{relative_path} is missing required release contract: {snippet}")


def validate(root: Path = ROOT) -> None:
    workflow_path = ".github/workflows/android-apk.yml"
    workflow = require_file(root, workflow_path)
    publish_condition = (
        "steps.android_export.outcome == 'success' && "
        "steps.gameplay_smoke.outcome == 'success' && "
        "steps.android_emulator.outcome == 'success'"
    )
    require_snippets(
        workflow_path,
        workflow,
        (
            "id: android_export",
            "id: gameplay_smoke",
            "id: android_emulator",
            "- name: Publish an emulator-launch-gated debug APK candidate",
            publish_condition,
            'gh release create "apk-candidate-${GITHUB_RUN_NUMBER}" build/OperationRedline-debug.apk',
            '--target "${GITHUB_SHA}"',
            "--prerelease",
            "Android emulator install/launch all passed.",
            "- name: Upload tested build evidence",
            "steps.android_export.outcome != 'success' || steps.gameplay_smoke.outcome != 'success' || steps.android_emulator.outcome == 'success'",
            "retention-days: 7",
        ),
    )
    if "device-validated" in workflow.lower():
        fail(f"{workflow_path} must not label emulator-only candidate evidence as device-validated")

    release_policy_path = "docs/RELEASE_GATING.md"
    release_policy = require_file(root, release_policy_path)
    require_snippets(
        release_policy_path,
        release_policy,
        (
            "A successful future release created through this gate still represents emulator evidence; physical-device testing is separately recorded.",
            "Publish an emulator-launch-gated debug APK candidate",
            "not a passing device result",
        ),
    )
    if "device-validated release gate" in release_policy.lower():
        fail(f"{release_policy_path} must distinguish its emulator gate from physical-device QA")

    handoff_path = "docs/PHYSICAL_DEVICE_QA.md"
    handoff = require_file(root, handoff_path)
    require_snippets(
        handoff_path,
        handoff,
        (
            "emulator-launch-gated candidate",
            "only after a real run",
            "PHYSICAL_DEVICE_TESTED",
        ),
    )
    if "device-validated release gate" in handoff.lower():
        fail(f"{handoff_path} must not describe emulator-only candidate gating as physical validation")

    artifact_policy_path = "docs/ARTIFACT_RETENTION.md"
    artifact_policy = require_file(root, artifact_policy_path)
    require_snippets(
        artifact_policy_path,
        artifact_policy,
        (
            "future emulator-launch-gated APK candidate",
            "storage recovery does not prove an emulator launch",
            "delivery, or release candidate.",
        ),
    )


def main() -> None:
    try:
        validate()
    except ReleaseContractError as exc:
        print(f"RELEASE_CONTRACT_ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
    print("RELEASE_CONTRACT_PASS emulator_gate=truthful physical_qa=separate artifacts=bounded")


if __name__ == "__main__":
    main()
