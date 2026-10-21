#!/usr/bin/env python3
"""Regression tests for the bilingual localization source contract."""
from __future__ import annotations

import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import validate_localization_catalog as catalog_validator  # noqa: E402


class LocalizationCatalogTests(unittest.TestCase):
    def test_committed_catalog_validates(self) -> None:
        catalog_validator.validate(ROOT)

    def test_rejects_duplicate_catalog_key(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            workspace = Path(temporary_directory)
            shutil.copytree(ROOT, workspace, dirs_exist_ok=True, ignore=shutil.ignore_patterns(".git", "node_modules"))
            catalog = workspace / "data/localization/redline.csv"
            catalog.write_text(
                catalog.read_text(encoding="utf-8") + "\nmenu.play,PLAY AGAIN,আবার খেলুন\n",
                encoding="utf-8",
            )
            with self.assertRaisesRegex(catalog_validator.LocalizationCatalogError, "duplicates key menu.play"):
                catalog_validator.validate(workspace)

    def test_rejects_missing_source_translation_key(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            workspace = Path(temporary_directory)
            shutil.copytree(ROOT, workspace, dirs_exist_ok=True, ignore=shutil.ignore_patterns(".git", "node_modules"))
            main = workspace / "scripts/main.gd"
            main.write_text(
                main.read_text(encoding="utf-8").replace('tr("pause.title")', 'tr("missing.title")', 1),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(catalog_validator.LocalizationCatalogError, "missing.title"):
                catalog_validator.validate(workspace)

    def test_rejects_blank_bengali_translation(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            workspace = Path(temporary_directory)
            shutil.copytree(ROOT, workspace, dirs_exist_ok=True, ignore=shutil.ignore_patterns(".git", "node_modules"))
            catalog = workspace / "data/localization/redline.csv"
            catalog.write_text(
                catalog.read_text(encoding="utf-8").replace(
                    "app.title,OPERATION REDLINE,অপারেশন রেডলাইন",
                    "app.title,OPERATION REDLINE,",
                    1,
                ),
                encoding="utf-8",
            )
            with self.assertRaisesRegex(catalog_validator.LocalizationCatalogError, "requires non-empty en and bn text"):
                catalog_validator.validate(workspace)


if __name__ == "__main__":
    unittest.main(verbosity=2)
