#!/usr/bin/env python3
"""Exercise the physical-Android factual collector against a deterministic fake adb.

This checks collection mechanics only. It does not emulate a device and never
turns the generated output into D01–D12 or physical-device evidence.
"""
from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COLLECTOR = ROOT / "docs/capture_physical_android_qa.sh"

FAKE_ADB = r'''#!/usr/bin/env sh
set -eu
if [ "${1:-}" = "-s" ]; then
  printf '%s\n' "-s $2" >> "$FAKE_ADB_LOG"
  shift 2
fi
printf '%s\n' "$*" >> "$FAKE_ADB_LOG"
case "${1:-}" in
  devices)
    printf 'List of devices attached\nfake-serial device product:outpost model:Test\n'
    ;;
  get-state)
    printf 'device\n'
    ;;
  get-serialno)
    printf 'fake-serial\n'
    ;;
  install)
    printf 'Success\n'
    ;;
  logcat)
    if [ "${2:-}" = "-d" ]; then
      printf 'I/OperationRedline: fake bounded log\n'
    fi
    ;;
  shell)
    shift
    case "${1:-}" in
      pm)
        if [ "${FAKE_ADB_PACKAGE_MISSING:-0}" = "1" ]; then
          printf 'Error: package not found\n'
        else
          printf 'package:/data/app/com.operationredline.outpost/base.apk\n'
        fi
        ;;
      monkey)
        printf 'Events injected: 1\n'
        ;;
      dumpsys)
        printf 'mResumedActivity: com.operationredline.outpost/.MainActivity\n'
        ;;
      *)
        printf 'fake device properties\n'
        ;;
    esac
    ;;
  *)
    printf 'fake adb handled command\n'
    ;;
esac
'''


class PhysicalQaCaptureTests(unittest.TestCase):
    def run_collector(self, *, package_missing: bool = False) -> tuple[subprocess.CompletedProcess[str], Path, str]:
        temporary_directory = tempfile.TemporaryDirectory()
        self.addCleanup(temporary_directory.cleanup)
        root = Path(temporary_directory.name)
        fake_bin = root / "bin"
        fake_bin.mkdir()
        adb = fake_bin / "adb"
        adb.write_text(FAKE_ADB, encoding="utf-8")
        adb.chmod(0o755)
        sleep = fake_bin / "sleep"
        sleep.write_text("#!/usr/bin/env sh\nexit 0\n", encoding="utf-8")
        sleep.chmod(0o755)
        apk = root / "OperationRedline-debug.apk"
        apk.write_bytes(b"fake apk bytes for collector mechanics\n")
        output = root / "capture"
        adb_log = root / "fake-adb.log"
        environment = os.environ.copy()
        environment.update(
            {
                "PATH": f"{fake_bin}:{environment['PATH']}",
                "FAKE_ADB_LOG": str(adb_log),
                "FAKE_ADB_PACKAGE_MISSING": "1" if package_missing else "0",
            }
        )
        completed = subprocess.run(
            ["/usr/bin/sh", str(COLLECTOR), "--apk", str(apk), "--output", str(output), "--serial", "fake-serial"],
            cwd=ROOT,
            env=environment,
            text=True,
            capture_output=True,
            check=False,
        )
        return completed, output, adb_log.read_text(encoding="utf-8") if adb_log.exists() else ""

    def test_help_does_not_require_adb(self) -> None:
        completed = subprocess.run(
            ["/usr/bin/sh", str(COLLECTOR), "--help"],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(completed.returncode, 0)
        self.assertIn("reviewer must still complete every D01-D12", completed.stdout)

    def test_collects_factual_outputs_without_claiming_device_qa(self) -> None:
        completed, output, adb_log = self.run_collector()
        self.assertEqual(completed.returncode, 0, completed.stderr)
        self.assertIn("PHYSICAL_QA_CAPTURE_COLLECTED", completed.stdout)
        expected_files = {
            "capture-manifest.txt",
            "apk.sha256",
            "adb-devices.txt",
            "adb-state.txt",
            "adb-serial.txt",
            "device-properties.txt",
            "clear-logcat.txt",
            "install-output.txt",
            "package-path.txt",
            "launch-output.txt",
            "resumed-activity.txt",
            "logcat.txt",
            "crash-scan.txt",
        }
        self.assertEqual({path.name for path in output.iterdir()}, expected_files)
        manifest = (output / "capture-manifest.txt").read_text(encoding="utf-8")
        self.assertIn("package_id=com.operationredline.outpost", manifest)
        self.assertIn("requested_serial=fake-serial", manifest)
        self.assertIn("adb_install_exit=0", manifest)
        self.assertIn("crash_scan=no_matches_in_bounded_log", manifest)
        self.assertNotIn("PHYSICAL_DEVICE_TESTED", manifest)
        self.assertNotIn("D01", manifest)
        self.assertIn("-s fake-serial", adb_log)
        self.assertIn("install -r", adb_log)

    def test_blocks_when_the_package_lookup_has_no_package_path(self) -> None:
        completed, output, _adb_log = self.run_collector(package_missing=True)
        self.assertEqual(completed.returncode, 1)
        self.assertIn("PHYSICAL_QA_CAPTURE_BLOCKED: package lookup failed", completed.stderr)
        self.assertTrue((output / "install-output.txt").is_file())
        self.assertTrue((output / "package-path.txt").is_file())
        self.assertFalse((output / "launch-output.txt").exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
