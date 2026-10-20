#!/usr/bin/env python3
"""Validate the source-level boundary around destructive legacy-artifact cleanup.

This static contract protects the manually dispatched workflow from quietly
becoming broad, automatic, or unconfirmed. It does not dispatch the workflow or
delete an artifact.
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKFLOW_PATH = ".github/workflows/cleanup-legacy-artifacts.yml"
AUDITED_ARTIFACT_NAME = "operation-redline-android-debug"
CONFIRMATION_TEXT = "DELETE_LEGACY_ARTIFACTS"


class CleanupWorkflowContractError(ValueError):
    """The manual cleanup workflow no longer has its required safety boundary."""


def fail(message: str) -> None:
    raise CleanupWorkflowContractError(message)


def validate(root: Path = ROOT) -> None:
    path = root / WORKFLOW_PATH
    if not path.is_file():
        fail(f"missing cleanup workflow: {WORKFLOW_PATH}")
    content = path.read_text(encoding="utf-8")
    required = (
        "name: Cleanup legacy CI artifacts",
        "workflow_dispatch:",
        "cutoff:",
        "confirmation:",
        "required: true",
        "actions: write",
        "contents: read",
        f'Delete only {AUDITED_ARTIFACT_NAME} artifacts created before this ISO-8601 time',
        f'Type {CONFIRMATION_TEXT} to authorize the bounded cleanup',
        f'const expected = "{CONFIRMATION_TEXT}";',
        "if (confirmation !== expected)",
        "const cutoff = Date.parse(cutoffText);",
        "if (Number.isNaN(cutoff))",
        "github.rest.actions.listArtifactsForRepo",
        f'artifact.name === "{AUDITED_ARTIFACT_NAME}"',
        "!artifact.expired",
        "Date.parse(artifact.created_at) < cutoff",
        "github.rest.actions.deleteArtifact",
        "await core.summary.write();",
    )
    for snippet in required:
        if snippet not in content:
            fail(f"cleanup workflow is missing required boundary: {snippet}")
    disallowed_triggers = (
        "push:",
        "pull_request:",
        "schedule:",
        "workflow_call:",
        "workflow_run:",
        "repository_dispatch:",
        "issue_comment:",
        "merge_group:",
        "check_suite:",
    )
    for trigger in disallowed_triggers:
        if trigger in content:
            fail(f"cleanup workflow must remain manual-only; found disallowed trigger: {trigger}")


def main() -> None:
    try:
        validate()
    except CleanupWorkflowContractError as exc:
        print(f"CLEANUP_WORKFLOW_CONTRACT_ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
    print("CLEANUP_WORKFLOW_CONTRACT_PASS dispatch=manual scope=bounded confirmation=required")


if __name__ == "__main__":
    main()
