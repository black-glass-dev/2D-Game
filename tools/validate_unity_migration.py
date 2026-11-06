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
        "unity/Packages/manifest.json",
        ("com.unity.ugui",),
        root,
    )
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
        ("RuntimeInitializeOnLoadMethod", "RedlineRebuildBootstrap.EnsureRuntime()", "retired from execution"),
        root,
    )
    require(
        "unity/Assets/RedlineRebuild/Scripts/RedlineRebuildBootstrap.cs",
        ("RedlineRebuildGame", "Operation Redline Rebuild Runtime", "EnsureRuntime"),
        root,
    )
    require(
        "unity/Assets/RedlineRebuild/Scripts/RedlineRebuildGame.cs",
        (
            "enum AppState",
            "BeginOperation()",
            "Time.unscaledDeltaTime",
            "EnsureEventSystem",
            "BuildGameplayUi",
            "CreateTouchSurface",
            "SetUiMove",
            "AddUiLook",
            "SetUiFire",
            "SpawnEnemy",
            "TickWaves",
            "PauseOperation",
            "OnApplicationPause",
            "CONTACTS ",
            "UI READY",
        ),
        root,
    )
    require(
        "unity/Assets/RedlineRebuild/Scripts/RedlineRebuildTouchSurface.cs",
        ("IPointerDownHandler", "IDragHandler", "IPointerUpHandler", "ICancelHandler", "activePointer", "SetUiMove", "AddUiLook", "SetUiFire"),
        root,
    )
    require(
        "unity/Assets/RedlineRebuild/Scripts/RedlineRebuildEnemy.cs",
        ("Tick(float deltaTime)", "ApplyDamage", "ApplyEnemyDamage", "EliminateEnemy"),
        root,
    )
    require(
        "unity/Assets/OperationRedline/Scripts/OperationGame.cs",
        (
            "WaveSizes = { 6, 9, 12 }",
            "MP_DS_01 Desert Outpost",
            "MP_RF_02",
            "map.rooftop_highrise",
            "FireActiveWeapon()",
            "CreateShotTracer",
            "DrawDamageNumbers",
            "DrawHudEditor",
            "DrawMobileTouchControls",
            "UpdateMobileActionInput",
            "HandleMobileActionTap",
            "Input.touchCount == 0",
            "Time.unscaledDeltaTime",
            "ResolveMobileActionLayout",
            "bindings.pause",
            "mobileDesertShader",
            "Shaders/OperationRedlineMobile",
            "Textures/desert_outpost_ground",
            "Textures/outpost_corrugated_metal",
            "ApplyWorldMaterial",
            "OnRaiderEliminated",
            "ApplyPlayerDamage",
            "KeyCode.Escape",
            "Application.isMobilePlatform",
            "OperationMode.Endless",
            "Difficulty.Nightmare",
            "settingsTab == SettingsTab.Accessibility",
        ),
        root,
    )
    require(
        "unity/Assets/OperationRedline/Scripts/UnitySettings.cs",
        (
            "CurrentSchema = 2",
            "PlayerPrefs",
            "SetQuality",
            "SetMusicVolume",
            "ToggleLanguage",
            "SetAutoFire",
            "SetReducedMotion",
            "SetScreenEffects",
            "SetGamepadDeadzone",
        ),
        root,
    )
    require(
        "unity/Assets/OperationRedline/Scripts/UnityProgress.cs",
        ("RecordResult", "BestScore", "BestWave", "MP_DS_01"),
        root,
    )
    require(
        "unity/Assets/OperationRedline/Scripts/UnityControls.cs",
        ("MoveForward", "SwapWeapon", "Reload", "ResetDefaults", "HasConflict"),
        root,
    )
    require(
        "unity/Assets/OperationRedline/Scripts/UnityWeaponState.cs",
        ("WeaponKind", "Carbine", "Sidearm", "TryFire", "StartReload"),
        root,
    )
    require(
        "unity/Assets/OperationRedline/Scripts/OutpostPlayerController.cs",
        ("CharacterController", "SprintSpeed", "ToggleCrouch", "ReadTouchInput", "ReadPrimaryPointerFallback", "Input.touchCount == 0", "GamepadDeadzone", "SetMobileUiExclusions", "RequestTouchJump", "IsOverMobileUi"),
        root,
    )
    require(
        "unity/Assets/OperationRedline/Scripts/TacticalRadar.cs",
        ("TacticalRadar", "InverseTransformDirection", "colorblindMode"),
        root,
    )
    require(
        "unity/Assets/OperationRedline/Scripts/UnityHudLayout.cs",
        ("UnityHudLayout", "Resolve", "Store", "Reset", "PlayerPrefs.SetFloat"),
        root,
    )
    require(
        "unity/Assets/OperationRedline/Scripts/UnityTransientEffect.cs",
        ("UnityTransientEffect", "Destroy(gameObject)"),
        root,
    )
    require(
        "unity/Assets/OperationRedline/Scripts/LocalizedCatalog.cs",
        ("OPERATION REDLINE", "অপারেশন রেডলাইন", "Desert Outpost", "ডেজার্ট আউটপোস্ট", "settings.accessibility"),
        root,
    )
    require(
        "unity/Assets/OperationRedline/Scripts/RaiderActor.cs",
        ("TakeDamage", "owner.ApplyPlayerDamage", "owner.OnRaiderEliminated"),
        root,
    )
    require(
        "tools/validate_unity_csharp_syntax.py",
        ("tree_sitter_c_sharp", "UNITY_CSHARP_SYNTAX_PASS", "parser_dependency_not_installed"),
        root,
    )
    require(
        "unity/tools-requirements.txt",
        ("tree-sitter==0.25.2", "tree-sitter-c-sharp==0.23.5"),
        root,
    )
    for asset in (
        "unity/Assets/OperationRedline/Resources/Audio/outpost_watch.wav",
        "unity/Assets/OperationRedline/Resources/Audio/rifle_shot.wav",
        "unity/Assets/OperationRedline/Resources/Fonts/NotoSansBengali-Regular.ttf",
        "unity/Assets/OperationRedline/Resources/UI/menu_desert_outpost.png",
        "unity/Assets/OperationRedline/Resources/Textures/desert_outpost_ground.png",
        "unity/Assets/OperationRedline/Resources/Textures/outpost_concrete.png",
        "unity/Assets/OperationRedline/Resources/Textures/outpost_corrugated_metal.png",
        "unity/Assets/OperationRedline/Resources/Textures/outpost_weathered_crate.png",
        "unity/Assets/OperationRedline/Resources/Shaders/OperationRedlineMobile.shader",
    ):
        if not (root / asset).is_file():
            fail(f"missing migrated Unity resource: {asset}")

    require(
        "unity/Assets/OperationRedline/Resources/Shaders/OperationRedlineMobile.shader",
        ("Shader \"OperationRedline/Mobile Desert\"", "#pragma target 2.0", "tex2D(_MainTex, input.uv) * _Color"),
        root,
    )

    workflow = required_text(".github/workflows/unity-android.yml", root)
    for snippet in (
        "workflow_dispatch:",
        "[build-unity-review-apk]",
        "BUILD_UNITY_REVIEW_APK",
        "game-ci/unity-builder@v6",
        "unityVersion: 2022.3.62f1",
        "targetPlatform: Android",
        "projectPath: unity",
        "UNITY_EMAIL: ${{ secrets.UNITY_EMAIL }}",
        "UNITY_PASSWORD: ${{ secrets.UNITY_PASSWORD }}",
        "Unity credential references are present; values remain masked.",
        "Install isolated Unity source parser",
        "unity/tools-requirements.txt",
        "tools/validate_unity_csharp_syntax.py",
        "find . -path './.git' -prune -o -type f -name '*.apk' -print -quit",
        "unity-review-artifact/OperationRedline-Unity-review.apk",
        "actions/upload-artifact@v4",
        "retention-days: 7",
        "- name: Publish explicitly unvalidated Unity review handoff",
        "tag=\"unity-human-review-${GITHUB_SHA:0:12}\"",
        "gh release create \"$tag\"",
        "apk_sha=\"$(awk '{print $1}' unity-review-artifact/OperationRedline-Unity-review.apk.sha256)\"",
        "SHA-256: \\`${apk_sha}\\`",
        "explicitly unvalidated Unity Android review build",
        "not a release candidate or supported delivery",
        "--prerelease",
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
    print("UNITY_MIGRATION_CONTRACT_PASS project=2022.3.62f1 android=ready gameplay=clean-rebuild-r1")


if __name__ == "__main__":
    main()
