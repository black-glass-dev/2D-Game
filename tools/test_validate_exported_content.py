#!/usr/bin/env python3
"""Regression tests for exported localization/map content guardrails."""
from __future__ import annotations

import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import validate_exported_content as exported_content_validator  # noqa: E402


class ExportedContentTests(unittest.TestCase):
    def copied_workspace(self) -> tempfile.TemporaryDirectory[str]:
        temporary_directory = tempfile.TemporaryDirectory()
        workspace = Path(temporary_directory.name)
        shutil.copytree(ROOT, workspace, dirs_exist_ok=True, ignore=shutil.ignore_patterns(".git", "node_modules"))
        return temporary_directory

    def test_committed_exported_content_contract_validates(self) -> None:
        exported_content_validator.validate(ROOT)

    def test_rejects_stale_packaged_map_anchor(self) -> None:
        with self.copied_workspace() as temporary_directory:
            workspace = Path(temporary_directory)
            catalog = workspace / "data/maps/packaged_map_catalog.gd"
            catalog.write_text(catalog.read_text(encoding="utf-8").replace("MP_DS_01.tres", "MISSING.tres", 1), encoding="utf-8")
            with self.assertRaisesRegex(exported_content_validator.ExportedContentError, "packaged_map_catalog.gd is stale"):
                exported_content_validator.validate(workspace)

    def test_rejects_dynamic_localization_file_access(self) -> None:
        with self.copied_workspace() as temporary_directory:
            workspace = Path(temporary_directory)
            service = workspace / "scripts/services/localization_service.gd"
            service.write_text(service.read_text(encoding="utf-8") + "\n# FileAccess.open export-prunable path\n", encoding="utf-8")
            with self.assertRaisesRegex(exported_content_validator.ExportedContentError, "dynamically opened export-prunable CSV"):
                exported_content_validator.validate(workspace)

    def test_rejects_missing_exported_pck_execution(self) -> None:
        with self.copied_workspace() as temporary_directory:
            workspace = Path(temporary_directory)
            workflow = workspace / ".github/workflows/android-apk.yml"
            workflow.write_text(
                workflow.read_text(encoding="utf-8").replace('grep -q "EXPORT_CONTENT_PASS" build/godot-export-content.log', "# exported PCK assertion removed", 1),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(exported_content_validator.ExportedContentError, "godot-export-content.log"):
                exported_content_validator.validate(workspace)

    def test_rejects_review_publisher_without_explicit_unvalidated_boundary(self) -> None:
        with self.copied_workspace() as temporary_directory:
            workspace = Path(temporary_directory)
            workflow = workspace / ".github/workflows/human-review-apk.yml"
            workflow.write_text(
                workflow.read_text(encoding="utf-8").replace("not** a release candidate, supported delivery, or physical-device PASS", "review boundary removed", 1),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(exported_content_validator.ExportedContentError, "human-review-apk.yml is missing export-content guard"):
                exported_content_validator.validate(workspace)


if __name__ == "__main__":
    unittest.main(verbosity=2)
