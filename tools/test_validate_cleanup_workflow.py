#!/usr/bin/env python3
"""Regression tests for the confirmation-gated legacy cleanup workflow contract."""
from __future__ import annotations

import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import validate_cleanup_workflow as cleanup  # noqa: E402


def workspace_with_workflow() -> tuple[tempfile.TemporaryDirectory[str], Path]:
    temporary_directory = tempfile.TemporaryDirectory()
    workspace = Path(temporary_directory.name)
    destination = workspace / cleanup.WORKFLOW_PATH
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(ROOT / cleanup.WORKFLOW_PATH, destination)
    return temporary_directory, workspace


class CleanupWorkflowContractTests(unittest.TestCase):
    def test_committed_workflow_validates(self) -> None:
        cleanup.validate(ROOT)

    def test_rejects_missing_exact_confirmation_comparison(self) -> None:
        temporary_directory, workspace = workspace_with_workflow()
        with temporary_directory:
            workflow = workspace / cleanup.WORKFLOW_PATH
            workflow.write_text(
                workflow.read_text(encoding="utf-8").replace(
                    "if (confirmation !== expected)", "if (confirmation === expected)"
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(cleanup.CleanupWorkflowContractError, "confirmation !== expected"):
                cleanup.validate(workspace)

    def test_rejects_broadened_artifact_name_filter(self) -> None:
        temporary_directory, workspace = workspace_with_workflow()
        with temporary_directory:
            workflow = workspace / cleanup.WORKFLOW_PATH
            workflow.write_text(
                workflow.read_text(encoding="utf-8").replace(
                    'artifact.name === "operation-redline-android-debug"',
                    'artifact.name === "*"',
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(cleanup.CleanupWorkflowContractError, "artifact.name"):
                cleanup.validate(workspace)

    def test_rejects_non_strict_cutoff_comparison(self) -> None:
        temporary_directory, workspace = workspace_with_workflow()
        with temporary_directory:
            workflow = workspace / cleanup.WORKFLOW_PATH
            workflow.write_text(
                workflow.read_text(encoding="utf-8").replace(
                    "Date.parse(artifact.created_at) < cutoff",
                    "Date.parse(artifact.created_at) <= cutoff",
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(cleanup.CleanupWorkflowContractError, "created_at"):
                cleanup.validate(workspace)

    def test_rejects_automatic_push_trigger(self) -> None:
        temporary_directory, workspace = workspace_with_workflow()
        with temporary_directory:
            workflow = workspace / cleanup.WORKFLOW_PATH
            workflow.write_text(
                workflow.read_text(encoding="utf-8").replace(
                    "  workflow_dispatch:\n", "  workflow_dispatch:\n  push:\n"
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(cleanup.CleanupWorkflowContractError, "manual-only"):
                cleanup.validate(workspace)


if __name__ == "__main__":
    unittest.main(verbosity=2)
