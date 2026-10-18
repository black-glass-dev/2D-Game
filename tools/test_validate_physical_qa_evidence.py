#!/usr/bin/env python3
"""Regression tests for physical-device evidence validation.

The completed records built here are temporary synthetic fixtures. They are not
Android-device evidence and are never stored in the repository's QA records.
"""
from __future__ import annotations

import copy
import json
import tempfile
import unittest
from pathlib import Path

import validate_physical_qa_evidence as physical_qa

ROOT = Path(__file__).resolve().parents[1]


class PhysicalQaEvidenceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.template = json.loads(
            (ROOT / "docs/physical_qa_evidence.template.json").read_text(encoding="utf-8")
        )

    def validate_temporary_record(self, record: dict) -> str:
        with tempfile.TemporaryDirectory() as temporary_directory:
            record_path = Path(temporary_directory) / "physical_qa_evidence.json"
            record_path.write_text(json.dumps(record), encoding="utf-8")
            return physical_qa.validate_record(record_path)

    def test_committed_template_is_not_evidence(self) -> None:
        self.assertEqual(physical_qa.validate_record(), "template")

    def test_template_rejects_claimed_result(self) -> None:
        invalid_template = copy.deepcopy(self.template)
        invalid_template["matrix"]["D01_install_update"]["result"] = "PASS"
        with self.assertRaisesRegex(physical_qa.PhysicalQaValidationError, "must remain NOT_RUN"):
            self.validate_temporary_record(invalid_template)

    def test_complete_record_requires_identity_evidence_and_truthful_classification(self) -> None:
        record = copy.deepcopy(self.template)
        record.update(
            {
                "status": "PHYSICAL_DEVICE_EVIDENCE",
                "tester": "synthetic test operator",
                "timezone": "UTC",
                "tested_at": "2099-01-01T00:00:00Z",
                "source_commit": "0123456789abcdef",
                "logcat_path": "evidence/synthetic-logcat.txt",
                "reviewed_by": "synthetic reviewer",
                "reviewed_at": "2099-01-01T00:10:00Z",
                "release_classification": "PHYSICAL_DEVICE_TESTED",
            }
        )
        record["apk"] = {
            "path_or_release_url": "evidence/synthetic-debug.apk",
            "sha256": "a" * 64,
            "package_id": "com.operationredline.outpost",
            "version_code": "999",
            "version_name": "synthetic",
            "install_command": "adb install -r evidence/synthetic-debug.apk",
            "install_output_path": "evidence/synthetic-install.txt",
        }
        record["device"] = {
            "manufacturer": "synthetic",
            "model": "test device",
            "codename": "test",
            "android_version": "99",
            "build_fingerprint": "synthetic/fingerprint",
            "display_resolution": "1280x720",
            "refresh_rate_hz": "60",
            "input_hardware": ["touchscreen"],
        }
        for row_id, row in record["matrix"].items():
            row["result"] = "PASS"
            row["evidence"] = [f"evidence/{row_id}.mp4"]
            row["notes"] = "synthetic test observation"

        self.assertEqual(self.validate_temporary_record(record), "physical_device_evidence")

        incomplete = copy.deepcopy(record)
        incomplete["matrix"]["D12_performance_thermal"]["result"] = "BLOCKED"
        with self.assertRaisesRegex(physical_qa.PhysicalQaValidationError, "NOT_PHYSICAL_DEVICE_TESTED"):
            self.validate_temporary_record(incomplete)

        incomplete["release_classification"] = "NOT_PHYSICAL_DEVICE_TESTED"
        self.assertEqual(self.validate_temporary_record(incomplete), "physical_device_evidence")


if __name__ == "__main__":
    unittest.main(verbosity=2)
