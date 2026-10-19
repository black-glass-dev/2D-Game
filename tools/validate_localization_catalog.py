#!/usr/bin/env python3
"""Validate the bilingual source catalog and its current GDScript key consumers.

The check is deliberately source-only: it does not claim rendered glyph coverage,
input-layout usability, or Android language testing. It prevents a committed UI key
from silently missing either English or Bengali catalog content.
"""
from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG_PATH = "data/localization/redline.csv"
KEY_PATTERN = re.compile(r"[a-z][a-z0-9_]*(?:\.[a-z][a-z0-9_]*)+")
BENGALI_PATTERN = re.compile(r"[\u0980-\u09ff]")
LITERAL_TRANSLATION_PATTERN = re.compile(r'\btr\(\s*"([a-z][a-z0-9_.-]*)"\s*\)')
HELPER_KEY_PATTERN = re.compile(
    r'\b(?:_make_button|_make_menu_button|_make_pause_button|_add_(?:choice|slider|toggle)|_show_sound_caption)\(\s*"([a-z][a-z0-9_.-]*)"'
)
ACTION_LABEL_PATTERN = re.compile(r'"(bindings\.[a-z0-9_.-]+)"')
SESSION_KEYS = {
    "game.easy",
    "game.normal",
    "game.hard",
    "game.nightmare",
    "game.survival",
    "game.endless",
}


class LocalizationCatalogError(ValueError):
    """A source localization catalog or its consumer contract is invalid."""


def fail(message: str) -> None:
    raise LocalizationCatalogError(message)


def read_required(root: Path, relative_path: str) -> str:
    path = root / relative_path
    if not path.is_file():
        fail(f"missing required file: {relative_path}")
    return path.read_text(encoding="utf-8")


def load_catalog(root: Path) -> dict[str, dict[str, str]]:
    path = root / CATALOG_PATH
    if not path.is_file():
        fail(f"missing catalog: {CATALOG_PATH}")
    with path.open(encoding="utf-8", newline="") as file:
        reader = csv.DictReader(file)
        if reader.fieldnames != ["keys", "en", "bn"]:
            fail(f"{CATALOG_PATH} must use the exact keys,en,bn header")
        catalog: dict[str, dict[str, str]] = {}
        for row_number, row in enumerate(reader, start=2):
            key = (row.get("keys") or "").strip()
            english = (row.get("en") or "").strip()
            bengali = (row.get("bn") or "").strip()
            if not KEY_PATTERN.fullmatch(key):
                fail(f"{CATALOG_PATH}:{row_number} has invalid key {key!r}")
            if key in catalog:
                fail(f"{CATALOG_PATH}:{row_number} duplicates key {key}")
            if not english or not bengali:
                fail(f"{CATALOG_PATH}:{row_number} requires non-empty en and bn text")
            if not BENGALI_PATTERN.search(bengali):
                fail(f"{CATALOG_PATH}:{row_number} bn text lacks Bengali script")
            catalog[key] = {"en": english, "bn": bengali}
    if not catalog:
        fail(f"{CATALOG_PATH} has no translation rows")
    return catalog


def source_translation_keys(root: Path) -> set[str]:
    scripts_directory = root / "scripts"
    if not scripts_directory.is_dir():
        fail("missing required scripts directory")
    keys: set[str] = set()
    for path in scripts_directory.rglob("*.gd"):
        source = path.read_text(encoding="utf-8")
        keys.update(LITERAL_TRANSLATION_PATTERN.findall(source))
        keys.update(HELPER_KEY_PATTERN.findall(source))
        keys.update(ACTION_LABEL_PATTERN.findall(source))
    main = read_required(root, "scripts/main.gd")
    if 'tr("game.%s" % GameManager.selected_difficulty.to_lower())' in main:
        keys.update(SESSION_KEYS)
    return keys


def validate(root: Path = ROOT) -> None:
    catalog = load_catalog(root)
    localization_service = read_required(root, "scripts/services/localization_service.gd")
    required_service_contract = (
        'const CATALOG_PATH := "res://data/localization/redline.csv"',
        "OS.get_locale_language().to_lower()",
        "TranslationServer.set_locale(active_locale)",
        "TranslationServer.add_translation",
        "translation.add_message(key, row[index].strip_edges())",
    )
    for snippet in required_service_contract:
        if snippet not in localization_service:
            fail(f"localization_service.gd is missing required catalog contract: {snippet}")

    used_keys = source_translation_keys(root)
    missing = sorted(used_keys.difference(catalog))
    if missing:
        fail(f"catalog misses source translation keys: {', '.join(missing)}")


def main() -> None:
    try:
        validate()
    except LocalizationCatalogError as exc:
        print(f"LOCALIZATION_CATALOG_ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
    print("LOCALIZATION_CATALOG_PASS locales=en,bn source_keys=covered")


if __name__ == "__main__":
    main()
