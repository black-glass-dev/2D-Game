#!/usr/bin/env python3
"""Regression tests for immutable source-level delivery guardrails."""
from __future__ import annotations

import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import validate_delivery_guardrails as guardrails  # noqa: E402


class DeliveryGuardrailTests(unittest.TestCase):
    def test_committed_sources_validate(self) -> None:
        guardrails.validate(ROOT)

    def test_rejects_changed_android_package_identifier(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            workspace = Path(temporary_directory)
            for relative_path in (
                "project.godot",
                "export_presets.cfg",
                "data/maps/MP_DS_01.tres",
                "data/maps/MP_RF_02.tres",
                "data/highrise/MP_RF_02_graybox_manifest.json",
                "scenes/Boot.tscn",
                "scenes/Main.tscn",
                "scripts/main.gd",
                "scripts/player.gd",
                "scripts/wave_director.gd",
                "scripts/world_builder.gd",
                "assets/third_party/kenney_cc0/README.md",
                "assets/third_party/kaykit_cc0/README.md",
                "assets/third_party/kaykit_cc0/LICENSE.txt",
                "CREDITS.md",
            ):
                source = ROOT / relative_path
                destination = workspace / relative_path
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, destination)

            preset = workspace / "export_presets.cfg"
            preset.write_text(
                preset.read_text(encoding="utf-8").replace(
                    "com.operationredline.outpost", "com.example.changed"
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(guardrails.DeliveryGuardrailError, "package/unique_name"):
                guardrails.validate(workspace)

    def test_rejects_unlocked_highrise_before_authoritative_packet(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            workspace = Path(temporary_directory)
            shutil.copytree(ROOT, workspace, dirs_exist_ok=True, ignore=shutil.ignore_patterns(".git", "node_modules"))
            highrise = workspace / "data/maps/MP_RF_02.tres"
            highrise.write_text(
                highrise.read_text(encoding="utf-8").replace("playable = false", "playable = true"),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(guardrails.DeliveryGuardrailError, "playable = false"):
                guardrails.validate(workspace)


if __name__ == "__main__":
    unittest.main(verbosity=2)
