#!/usr/bin/env python3
"""Validate source-level M6 regression contracts for foundation services.

These dependency-free checks cover settings/save migration, state transitions, and
data-driven map registry behavior. They complement engine/runtime QA; they do not
claim Godot, Android, or physical-device execution.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class FoundationContractError(ValueError):
    """A required foundation-service regression contract is missing."""


def fail(message: str) -> None:
    raise FoundationContractError(message)


def read_required(root: Path, relative_path: str) -> str:
    path = root / relative_path
    if not path.is_file():
        fail(f"missing required file: {relative_path}")
    return path.read_text(encoding="utf-8")


def require_snippets(relative_path: str, content: str, snippets: tuple[str, ...]) -> None:
    for snippet in snippets:
        if snippet not in content:
            fail(f"{relative_path} is missing required contract: {snippet}")


def require_schema_version(relative_path: str, content: str) -> None:
    match = re.search(r"const\s+SCHEMA_VERSION\s*:=\s*(\d+)", content)
    if match is None or int(match.group(1)) < 1:
        fail(f"{relative_path} must declare a schema version of at least 1")


def validate(root: Path = ROOT) -> None:
    settings_path = "scripts/services/settings_service.gd"
    settings = read_required(root, settings_path)
    require_schema_version(settings_path, settings)
    require_snippets(
        settings_path,
        settings,
        (
            'const SETTINGS_PATH := "user://settings.cfg"',
            'const LEGACY_SETTINGS_PATH := "user://operation_redline_settings.cfg"',
            '"language": "AUTO"',
            '"quality_tier": "AUTO"',
            '"master_volume": 1.0',
            '"music_volume": 0.75',
            '"touch_joystick_scale": 1.0',
            '"gamepad_deadzone": 0.20',
            '"subtitles": true',
            'values = DEFAULTS.duplicate(true)',
            "_migrate_legacy_settings()",
            "_migrate_schema(version)",
            "_sync_legacy_runtime_settings()",
            "setting_changed.emit(key, value)",
        ),
    )

    save_path = "scripts/services/save_service.gd"
    save = read_required(root, save_path)
    require_schema_version(save_path, save)
    require_snippets(
        save_path,
        save,
        (
            'const SAVE_PATH := "user://save.json"',
            'const LEGACY_HUD_LAYOUT_PATH := "user://operation_redline_hud.cfg"',
            '"unlocked_maps": ["MP_DS_01"]',
            '"best_results": {}',
            '"last_map": "MP_DS_01"',
            "data.merge(_default_data(), false)",
            "maxi(score, int(previous.get(\"score\", 0)))",
            "maxi(wave, int(previous.get(\"wave\", 0)))",
            "save_changed.emit()",
        ),
    )

    game_manager_path = "scripts/services/game_manager.gd"
    game_manager = read_required(root, game_manager_path)
    require_snippets(
        game_manager_path,
        game_manager,
        (
            "BOOT,",
            "SPLASH,",
            "MAIN_MENU,",
            "MAP_SELECT,",
            "LOADING,",
            "PLAYING,",
            "PAUSED,",
            "GAME_OVER,",
            "MISSION_COMPLETE,",
            "if state != State.PLAYING:",
            "state_before_pause = state",
            "get_tree().paused = true",
            "set_state(State.PAUSED)",
            "if state != State.PAUSED:",
            "get_tree().paused = false",
            "set_state(state_before_pause)",
            'selected_difficulty = difficulty if difficulty in DIFFICULTIES else "NORMAL"',
            'selected_mode = mode if mode in MODES else "SURVIVAL"',
        ),
    )

    map_data_path = "data/map_data.gd"
    map_data = read_required(root, map_data_path)
    require_snippets(
        map_data_path,
        map_data,
        (
            "func is_valid_map() -> bool:",
            "return not playable or (not scene_path.is_empty() and ResourceLoader.exists(scene_path))",
            'return playable and unlock_state == "UNLOCKED" and not scene_path.is_empty()',
            'return unlock_state == "COMING_SOON"',
        ),
    )

    registry_path = "scripts/services/map_registry.gd"
    registry = read_required(root, registry_path)
    require_snippets(
        registry_path,
        registry,
        (
            'const MAP_DIRECTORY := "res://data/maps"',
            "resource_names.sort()",
            "ResourceLoader.load(resource_path) as RedlineMapData",
            "not map_data.is_valid_map() or maps_by_id.has(map_data.id)",
            "if map_data.playable:",
        ),
    )


def main() -> None:
    try:
        validate()
    except FoundationContractError as exc:
        print(f"FOUNDATION_CONTRACT_ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
    print("FOUNDATION_CONTRACT_PASS settings=versioned save=monotonic state=guarded maps=data_driven")


if __name__ == "__main__":
    main()
