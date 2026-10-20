#!/usr/bin/env python3
"""Regression tests for the source-level Android release truth contract."""
from __future__ import annotations

import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import validate_release_contract as contract  # noqa: E402


REQUIRED_FILES = (
    ".github/workflows/android-apk.yml",
    "docs/RELEASE_GATING.md",
    "docs/PHYSICAL_DEVICE_QA.md",
    "docs/ARTIFACT_RETENTION.md",
)


def copy_contract_sources(destination: Path) -> None:
    for relative_path in REQUIRED_FILES:
        source = ROOT / relative_path
        copied = destination / relative_path
        copied.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, copied)


class ReleaseContractTests(unittest.TestCase):
    def test_committed_sources_validate(self) -> None:
        contract.validate(ROOT)

    def test_rejects_candidate_without_same_run_emulator_success(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            workspace = Path(temporary_directory)
            copy_contract_sources(workspace)
            workflow = workspace / ".github/workflows/android-apk.yml"
            workflow.write_text(
                workflow.read_text(encoding="utf-8").replace(
                    "steps.android_export.outcome == 'success' && steps.gameplay_smoke.outcome == 'success' && steps.android_emulator.outcome == 'success'",
                    "steps.android_export.outcome == 'success' && steps.gameplay_smoke.outcome == 'success'",
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(contract.ReleaseContractError, "steps.android_emulator.outcome"):
                contract.validate(workspace)

    def test_rejects_misleading_device_validated_candidate_label(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            workspace = Path(temporary_directory)
            copy_contract_sources(workspace)
            workflow = workspace / ".github/workflows/android-apk.yml"
            workflow.write_text(
                workflow.read_text(encoding="utf-8") + "\n# device-validated\n",
                encoding="utf-8",
            )
            with self.assertRaisesRegex(contract.ReleaseContractError, "device-validated"):
                contract.validate(workspace)

    def test_rejects_unbounded_success_artifact_retention(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            workspace = Path(temporary_directory)
            copy_contract_sources(workspace)
            workflow = workspace / ".github/workflows/android-apk.yml"
            workflow.write_text(
                workflow.read_text(encoding="utf-8").replace("retention-days: 7", "retention-days: 90"),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(contract.ReleaseContractError, "retention-days: 7"):
                contract.validate(workspace)


if __name__ == "__main__":
    unittest.main(verbosity=2)
