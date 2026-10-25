#!/usr/bin/env python3
"""Protect menu translations/maps against dynamically-loaded export omissions.

This is a source contract. The Android workflow separately executes the exported
PCK with `--verify-export-content`; neither check is a device test or APK launch
claim.
"""
from __future__ import annotations

import sys
from pathlib import Path

import generate_embedded_localization_catalog as localization_catalog
import generate_packaged_map_catalog as map_catalog

ROOT = Path(__file__).resolve().parents[1]


class ExportedContentError(ValueError):
    """A required packaged-content guard is absent or stale."""


def fail(message: str) -> None:
    raise ExportedContentError(message)


def text(root: Path, path: str) -> str:
    file_path = root / path
    if not file_path.is_file():
        fail(f"missing required file: {path}")
    return file_path.read_text(encoding="utf-8")


def require(content: str, path: str, snippets: tuple[str, ...]) -> None:
    for snippet in snippets:
        if snippet not in content:
            fail(f"{path} is missing export-content guard: {snippet}")


def validate(root: Path = ROOT) -> None:
    try:
        localization_entries, locales = localization_catalog.check(root)
        map_count = map_catalog.check(root)
    except (OSError, ValueError) as exc:
        fail(str(exc))
    if locales != ("en", "bn") or localization_entries < 1 or map_count < 1:
        fail("generated packaged catalogs have incomplete locale/map coverage")

    service = text(root, "scripts/services/localization_service.gd")
    require(
        service,
        "scripts/services/localization_service.gd",
        (
            "RedlineLocalizationCatalog.build_translations()",
            "TranslationServer.add_translation(translation)",
            "generated catalog is empty",
        ),
    )
    if "FileAccess.open" in service:
        fail("localization service must not depend on a dynamically opened export-prunable CSV")

    registry = text(root, "scripts/services/map_registry.gd")
    require(
        registry,
        "scripts/services/map_registry.gd",
        (
            "RedlinePackagedMapCatalog.all_maps()",
            "_register_map(map_data, \"packaged_catalog:%s\" % map_data.id)",
            "MapRegistry could not open %s; using packaged map anchors.",
        ),
    )

    boot_flow = text(root, "scripts/boot_flow.gd")
    require(
        boot_flow,
        "scripts/boot_flow.gd",
        (
            'const EXPORT_CONTENT_TEST_ARGUMENT := "--verify-export-content"',
            "func _begin_export_content_test() -> void:",
            'MapRegistry.get_map("MP_DS_01")',
            'tr("app.title")',
            'tr("menu.map_select")',
            'print("EXPORT_CONTENT_PASS maps=", maps.size()',
        ),
    )

    workflow = text(root, ".github/workflows/android-apk.yml")
    require(
        workflow,
        ".github/workflows/android-apk.yml",
        (
            "- name: Verify exported PCK menu content",
            '--export-pack "Android Debug" build/OperationRedline-content-check.pck',
            "--main-pack \"$GITHUB_WORKSPACE/build/OperationRedline-content-check.pck\" -- --verify-export-content",
            'grep -q "EXPORT_CONTENT_PASS" build/godot-export-content.log',
        ),
    )

    review_workflow = text(root, ".github/workflows/human-review-apk.yml")
    require(
        review_workflow,
        ".github/workflows/human-review-apk.yml",
        (
            "[publish-human-qa-apk]",
            "PUBLISH_HUMAN_REVIEW_APK",
            "--verify-export-content",
            'grep -q "EXPORT_CONTENT_PASS" build/godot-export-content.log',
            "Publish explicitly unvalidated human-review APK",
            "not** a release candidate, supported delivery, or physical-device PASS",
        ),
    )


def main() -> None:
    try:
        validate()
    except ExportedContentError as exc:
        print(f"EXPORTED_CONTENT_ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
    print("EXPORTED_CONTENT_CONTRACT_PASS localization=packaged maps=anchored pck_check=required")


if __name__ == "__main__":
    main()
