#!/usr/bin/env python3
"""Regression tests for read-only legacy artifact cleanup auditing."""
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import audit_legacy_artifacts as audit  # noqa: E402


CUTOFF = "2026-10-14T00:00:00Z"


def artifact(
    artifact_id: int,
    created_at: str,
    size_in_bytes: int,
    *,
    name: str = audit.AUDITED_ARTIFACT_NAME,
    expired: bool = False,
) -> dict[str, object]:
    return {
        "id": artifact_id,
        "name": name,
        "expired": expired,
        "created_at": created_at,
        "size_in_bytes": size_in_bytes,
    }


def invoke_with_payload(payload: object, *arguments: str) -> tuple[int, str, str]:
    with tempfile.TemporaryDirectory() as temporary_directory:
        payload_path = Path(temporary_directory) / "artifacts.json"
        payload_path.write_text(json.dumps(payload), encoding="utf-8")
        stdout = StringIO()
        stderr = StringIO()
        with redirect_stdout(stdout), redirect_stderr(stderr):
            try:
                audit.main(["--input", str(payload_path), "--cutoff", CUTOFF, *arguments])
            except SystemExit as exc:
                return int(exc.code), stdout.getvalue(), stderr.getvalue()
        return 0, stdout.getvalue(), stderr.getvalue()


class LegacyArtifactAuditTests(unittest.TestCase):
    def test_counts_only_active_exact_name_pre_cutoff_candidates_across_pages(self) -> None:
        payload = [
            {
                "artifacts": [
                    artifact(10, "2026-10-13T23:59:59Z", 40),
                    artifact(11, "2026-10-14T00:00:00Z", 50),
                    artifact(12, "2026-10-12T00:00:00Z", 60, expired=True),
                ]
            },
            {
                "artifacts": [
                    artifact(13, "2026-10-01T00:00:00+00:00", 70),
                    artifact(14, "2026-10-01T00:00:00Z", 80, name="unrelated-artifact"),
                ]
            },
        ]
        code, stdout, stderr = invoke_with_payload(payload, "--expect-pre-cutoff-count", "2")
        self.assertEqual(code, 0, stderr)
        self.assertIn("active_named=3 pre_cutoff=2 pre_cutoff_bytes=110", stdout)

    def test_cleanup_verification_rejects_remaining_legacy_candidate(self) -> None:
        payload = {"artifacts": [artifact(10, "2026-10-13T23:59:59Z", 40)]}
        code, _stdout, stderr = invoke_with_payload(payload, "--verify-cleanup")
        self.assertEqual(code, 1)
        self.assertIn("cleanup verification failed", stderr)

    def test_cleanup_verification_passes_when_no_active_pre_cutoff_candidate_remains(self) -> None:
        payload = {
            "artifacts": [
                artifact(10, "2026-10-14T00:00:00Z", 40),
                artifact(11, "2026-10-12T00:00:00Z", 50, expired=True),
                artifact(12, "2026-10-12T00:00:00Z", 60, name="unrelated-artifact"),
            ]
        }
        code, stdout, stderr = invoke_with_payload(payload, "--verify-cleanup")
        self.assertEqual(code, 0, stderr)
        self.assertIn("active_named=1 pre_cutoff=0 pre_cutoff_bytes=0", stdout)
        self.assertIn("ARTIFACT_CLEANUP_VERIFY_PASS", stdout)

    def test_rejects_malformed_inventory_timestamp(self) -> None:
        payload = {"artifacts": [artifact(10, "not-a-time", 40)]}
        code, _stdout, stderr = invoke_with_payload(payload)
        self.assertEqual(code, 1)
        self.assertIn("artifact.created_at is not a valid ISO-8601 timestamp", stderr)

    def test_rejects_malformed_repository_before_running_github_cli(self) -> None:
        with self.assertRaisesRegex(audit.ArtifactAuditError, "owner/repository"):
            audit.collect_live_payload("owner/repository/extra")

    def test_live_collection_command_is_read_only(self) -> None:
        captured: list[str] = []

        def fake_run(command: list[str], **_kwargs: object) -> subprocess.CompletedProcess[str]:
            captured.extend(command)
            return subprocess.CompletedProcess(command, 0, stdout="", stderr="")

        original_run = audit.subprocess.run
        audit.subprocess.run = fake_run  # type: ignore[assignment]
        try:
            payload = audit.collect_live_payload("owner/repository")
        finally:
            audit.subprocess.run = original_run  # type: ignore[assignment]
        self.assertEqual(payload, {"artifacts": []})
        self.assertEqual(captured[:5], ["gh", "api", "--paginate", "--jq", ".artifacts[]"])
        self.assertTrue(any("/actions/artifacts?" in item for item in captured))
        self.assertNotIn("DELETE", " ".join(captured).upper())


if __name__ == "__main__":
    unittest.main(verbosity=2)
