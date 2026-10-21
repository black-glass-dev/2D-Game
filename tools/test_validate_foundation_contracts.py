#!/usr/bin/env python3
"""Regression tests for source-level M6 foundation-service contracts."""
from __future__ import annotations

import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import validate_foundation_contracts as contracts  # noqa: E402


SOURCE_FILES = (
    "scripts/services/settings_service.gd",
    "scripts/services/save_service.gd",
    "scripts/services/game_manager.gd",
    "scripts/services/map_registry.gd",
    "data/map_data.gd",
)


def copy_contract_sources(destination_root: Path) -> None:
    for relative_path in SOURCE_FILES:
        source = ROOT / relative_path
        destination = destination_root / relative_path
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)


class FoundationContractTests(unittest.TestCase):
    def test_committed_sources_validate(self) -> None:
        contracts.validate(ROOT)

    def test_rejects_unversioned_settings_schema(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            workspace = Path(temporary_directory)
            copy_contract_sources(workspace)
            settings = workspace / "scripts/services/settings_service.gd"
            settings.write_text(
                settings.read_text(encoding="utf-8").replace("const SCHEMA_VERSION := 1", "const SCHEMA_VERSION := 0"),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(contracts.FoundationContractError, "settings_service.gd must declare"):
                contracts.validate(workspace)

    def test_rejects_unguarded_pause_entry(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            workspace = Path(temporary_directory)
            copy_contract_sources(workspace)
            manager = workspace / "scripts/services/game_manager.gd"
            manager.write_text(
                manager.read_text(encoding="utf-8").replace("if state != State.PLAYING:", "if state != State.MAIN_MENU:"),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(contracts.FoundationContractError, "if state != State.PLAYING"):
                contracts.validate(workspace)

    def test_rejects_non_monotonic_best_score(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            workspace = Path(temporary_directory)
            copy_contract_sources(workspace)
            save = workspace / "scripts/services/save_service.gd"
            save.write_text(
                save.read_text(encoding="utf-8").replace(
                    'maxi(score, int(previous.get("score", 0)))', "score"
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(contracts.FoundationContractError, "maxi\(score"):
                contracts.validate(workspace)


if __name__ == "__main__":
    unittest.main(verbosity=2)
