#!/usr/bin/env python3
"""Validate the source-level Unity migration contract.

This check never claims a Unity import, license activation, Android export, or
physical-device result. Those require the manually dispatched Unity workflow.
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class UnityMigrationError(ValueError):
    """The committed Unity migration baseline is incomplete or unsafe."""


def fail(message: str) -> None:
    raise UnityMigrationError(message)


def required_text(relative_path: str, root: Path = ROOT) -> str:
    path = root / relative_path
    if not path.is_file():
        fail(f"missing Unity migration file: {relative_path}")
    return path.read_text(encoding="utf-8")


def require(relative_path: str, snippets: tuple[str, ...], root: Path = ROOT) -> None:
    content = required_text(relative_path, root)
    for snippet in snippets:
        if snippet not in content:
            fail(f"{relative_path} is missing migration contract: {snippet}")


def validate(root: Path = ROOT) -> None:
    project_version = required_text("unity/ProjectSettings/ProjectVersion.txt", root)
    if "m_EditorVersion: 2022.3.62f1" not in project_version:
        fail("Unity project must pin the documented 2022.3.62f1 editor")

    require(
        "unity/ProjectSettings/ProjectSettings.asset",
        (
            "productName: Operation Redline",
            "Android: com.operationredline.outpost",
            "AndroidMinSdkVersion: 23",
            "defaultScreenOrientation: 3",
            "AndroidTargetArchitectures: 2",
        ),
        root,
    )
    require(
        "unity/ProjectSettings/EditorBuildSettings.asset",
        (
            "path: Assets/Scenes/Bootstrap.unity",
            "guid: 5d670c3be2dc43b5997fe72b8b135a24",
        ),
        root,
    )
    require("unity/Assets/Scenes/Bootstrap.unity", ("SceneSettings:",), root)
    require(
        "unity/Assets/OperationRedline/Scripts/OperationBootstrap.cs",
        ("RuntimeInitializeOnLoadMethod", "root.AddComponent<OperationGame>()"),
        root,
    )
    require(
        "unity/Assets/OperationRedline/Scripts/OperationGame.cs",
        (
            "WaveSizes = { 6, 9, 12 }",
            "MP_DS_01 Desert Outpost",
            "map.highrise.detail",
            "FireRifle()",
            "OnRaiderEliminated",
            "ApplyPlayerDamage",
            "KeyCode.Escape",
            "Application.isMobilePlatform",
        ),
        root,
    )
    require(
        "unity/Assets/OperationRedline/Scripts/UnitySettings.cs",
        ("PlayerPrefs", "SetQuality", "SetMusicVolume", "ToggleLanguage"),
        root,
    )
    require(
        "unity/Assets/OperationRedline/Scripts/LocalizedCatalog.cs",
        ("OPERATION REDLINE", "অপারেশন রেডলাইন", "DESERT OUTPOST", "ডেজার্ট আউটপোস্ট"),
        root,
    )
    require(
        "unity/Assets/OperationRedline/Scripts/RaiderActor.cs",
        ("TakeDamage", "owner.ApplyPlayerDamage", "owner.OnRaiderEliminated"),
        root,
    )
    for asset in (
        "unity/Assets/OperationRedline/Resources/Audio/outpost_watch.wav",
        "unity/Assets/OperationRedline/Resources/Audio/rifle_shot.wav",
        "unity/Assets/OperationRedline/Resources/Fonts/NotoSansBengali-Regular.ttf",
        "unity/Assets/OperationRedline/Resources/UI/menu_desert_outpost.png",
    ):
        if not (root / asset).is_file():
            fail(f"missing migrated Unity resource: {asset}")

    workflow = required_text(".github/workflows/unity-android.yml", root)
    for snippet in (
        "workflow_dispatch:",
        "BUILD_UNITY_REVIEW_APK",
        "game-ci/unity-builder@v6",
        "unityVersion: 2022.3.62f1",
        "targetPlatform: Android",
        "projectPath: unity",
        "UNITY_EMAIL: ${{ secrets.UNITY_EMAIL }}",
        "UNITY_PASSWORD: ${{ secrets.UNITY_PASSWORD }}",
        "Unity credential references are present; values remain masked.",
        "actions/upload-artifact@v4",
        "retention-days: 7",
    ):
        if snippet not in workflow:
            fail(f".github/workflows/unity-android.yml is missing migration contract: {snippet}")
    unsafe_secret_tokens = ("echo \"$UNITY_EMAIL", "echo \"$UNITY_PASSWORD", "printenv")
    if any(token in workflow for token in unsafe_secret_tokens):
        fail("Unity workflow must not print credential values")


def main() -> None:
    try:
        validate()
    except UnityMigrationError as exc:
        print(f"UNITY_MIGRATION_ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
    print("UNITY_MIGRATION_CONTRACT_PASS project=2022.3.62f1 android=ready gameplay=desert-baseline")


if __name__ == "__main__":
    main()
