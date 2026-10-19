#!/usr/bin/env python3
"""Validate the immutable source-level delivery guardrails.

These checks protect the currently playable Desert operation, Android direct-update
identity, landscape presentation, audited external-asset records, and the locked
state of the future Highrise map. They are intentionally not Android-device or
Highrise-gameplay evidence.
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class DeliveryGuardrailError(ValueError):
    """A required source-level release guardrail is absent or altered."""


def fail(message: str) -> None:
    raise DeliveryGuardrailError(message)


def require_file(root: Path, relative_path: str) -> Path:
    path = root / relative_path
    if not path.is_file():
        fail(f"missing required file: {relative_path}")
    return path


def require_text(root: Path, relative_path: str, snippets: tuple[str, ...]) -> None:
    content = require_file(root, relative_path).read_text(encoding="utf-8")
    for snippet in snippets:
        if snippet not in content:
            fail(f"{relative_path} is missing required guardrail: {snippet}")


def validate(root: Path = ROOT) -> None:
    require_text(
        root,
        "project.godot",
        (
            'run/main_scene="res://scenes/Boot.tscn"',
            "size/viewport_width=1280",
            "size/viewport_height=720",
            "handheld/orientation=0",
        ),
    )
    require_text(
        root,
        "export_presets.cfg",
        (
            'export_path="build/OperationRedline-debug.apk"',
            "architectures/arm64-v8a=true",
            "architectures/x86_64=true",
            'package/unique_name="com.operationredline.outpost"',
            "package/signed=true",
        ),
    )
    require_text(
        root,
        "data/maps/MP_DS_01.tres",
        (
            'id = "MP_DS_01"',
            'scene_path = "res://scenes/Main.tscn"',
            '"wave_sizes": [6, 9, 12]',
            "playable = true",
        ),
    )
    for path in (
        "scenes/Boot.tscn",
        "scenes/Main.tscn",
        "scripts/main.gd",
        "scripts/player.gd",
        "scripts/wave_director.gd",
        "scripts/world_builder.gd",
    ):
        require_file(root, path)

    require_text(
        root,
        "data/maps/MP_RF_02.tres",
        (
            'id = "MP_RF_02"',
            'unlock_state = "COMING_SOON"',
            "playable = false",
        ),
    )
    require_text(
        root,
        "data/highrise/MP_RF_02_graybox_manifest.json",
        ('"status": "AWAITING_AUTHORITATIVE_B2_COORDINATES"',),
    )

    require_text(
        root,
        "assets/third_party/kenney_cc0/README.md",
        ("Creative Commons Zero 1.0 Universal (CC0)", "Source mirror"),
    )
    require_text(
        root,
        "assets/third_party/kaykit_cc0/README.md",
        ("Creative Commons Zero 1.0 Universal (CC0)", "KayKit Character Pack"),
    )
    require_file(root, "assets/third_party/kaykit_cc0/LICENSE.txt")
    require_text(
        root,
        "CREDITS.md",
        ("Kenney", "KayKit", "No Kenney sci-fi, space, blaster, alien, laser"),
    )


def main() -> None:
    try:
        validate()
    except DeliveryGuardrailError as exc:
        print(f"DELIVERY_GUARDRAIL_ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
    print("DELIVERY_GUARDRAIL_PASS desert=playable android=stable highrise=locked assets=audited")


if __name__ == "__main__":
    main()
