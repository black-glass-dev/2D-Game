#!/usr/bin/env python3
"""Regression tests for the Unity migration source contract."""
from __future__ import annotations

import shutil
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import validate_unity_migration as unity_validator  # noqa: E402


class UnityMigrationTests(unittest.TestCase):
    def copied_workspace(self) -> tempfile.TemporaryDirectory[str]:
        temporary_directory = tempfile.TemporaryDirectory()
        workspace = Path(temporary_directory.name)
        shutil.copytree(ROOT, workspace, dirs_exist_ok=True, ignore=shutil.ignore_patterns(".git", "node_modules"))
        return temporary_directory

    def test_committed_migration_contract_validates(self) -> None:
        unity_validator.validate(ROOT)

    def test_rejects_changed_android_identity(self) -> None:
        with self.copied_workspace() as directory:
            workspace = Path(directory)
            settings = workspace / "unity/ProjectSettings/ProjectSettings.asset"
            settings.write_text(settings.read_text(encoding="utf-8").replace("Android: com.operationredline.outpost", "Android: com.example.changed", 1), encoding="utf-8")
            with self.assertRaisesRegex(unity_validator.UnityMigrationError, "Android: com.operationredline.outpost"):
                unity_validator.validate(workspace)

    def test_rejects_missing_playable_desert_wave_profile(self) -> None:
        with self.copied_workspace() as directory:
            workspace = Path(directory)
            game = workspace / "unity/Assets/OperationRedline/Scripts/OperationGame.cs"
            game.write_text(game.read_text(encoding="utf-8").replace("WaveSizes = { 6, 9, 12 }", "WaveSizes = { 4, 8, 12 }", 1), encoding="utf-8")
            with self.assertRaisesRegex(unity_validator.UnityMigrationError, "WaveSizes"):
                unity_validator.validate(workspace)

    def test_rejects_secret_echo(self) -> None:
        with self.copied_workspace() as directory:
            workspace = Path(directory)
            workflow = workspace / ".github/workflows/unity-android.yml"
            workflow.write_text(workflow.read_text(encoding="utf-8") + "\n          echo \"$UNITY_EMAIL\"\n", encoding="utf-8")
            with self.assertRaisesRegex(unity_validator.UnityMigrationError, "must not print credential values"):
                unity_validator.validate(workspace)

    def test_rejects_missing_first_build_marker(self) -> None:
        with self.copied_workspace() as directory:
            workspace = Path(directory)
            workflow = workspace / ".github/workflows/unity-android.yml"
            workflow.write_text(workflow.read_text(encoding="utf-8").replace("[build-unity-review-apk]", "[removed-marker]"), encoding="utf-8")
            with self.assertRaisesRegex(unity_validator.UnityMigrationError, "build-unity-review-apk"):
                unity_validator.validate(workspace)

    def test_rejects_missing_unity_control_contract(self) -> None:
        with self.copied_workspace() as directory:
            workspace = Path(directory)
            controls = workspace / "unity/Assets/OperationRedline/Scripts/UnityControls.cs"
            controls.write_text(controls.read_text(encoding="utf-8").replace("SwapWeapon", "RemovedWeaponBinding"), encoding="utf-8")
            with self.assertRaisesRegex(unity_validator.UnityMigrationError, "SwapWeapon"):
                unity_validator.validate(workspace)

    def test_rejects_changed_confirmed_secret_reference(self) -> None:
        with self.copied_workspace() as directory:
            workspace = Path(directory)
            workflow = workspace / ".github/workflows/unity-android.yml"
            workflow.write_text(workflow.read_text(encoding="utf-8").replace("secrets.UNITY_PASSWORD", "secrets.REMOVED_PASSWORD", 1), encoding="utf-8")
            with self.assertRaisesRegex(unity_validator.UnityMigrationError, "UNITY_PASSWORD"):
                unity_validator.validate(workspace)

    def test_rejects_missing_tactical_radar_projection(self) -> None:
        with self.copied_workspace() as directory:
            workspace = Path(directory)
            radar = workspace / "unity/Assets/OperationRedline/Scripts/TacticalRadar.cs"
            radar.write_text(radar.read_text(encoding="utf-8").replace("InverseTransformDirection", "RemovedProjection", 1), encoding="utf-8")
            with self.assertRaisesRegex(unity_validator.UnityMigrationError, "InverseTransformDirection"):
                unity_validator.validate(workspace)

    def test_rejects_missing_persisted_hud_layout(self) -> None:
        with self.copied_workspace() as directory:
            workspace = Path(directory)
            layout = workspace / "unity/Assets/OperationRedline/Scripts/UnityHudLayout.cs"
            layout.write_text(layout.read_text(encoding="utf-8").replace("PlayerPrefs.SetFloat", "RemovedLayoutPersistence"), encoding="utf-8")
            with self.assertRaisesRegex(unity_validator.UnityMigrationError, "UnityHudLayout"):
                unity_validator.validate(workspace)

    def test_rejects_missing_mobile_safe_desert_shader(self) -> None:
        with self.copied_workspace() as directory:
            workspace = Path(directory)
            shader = workspace / "unity/Assets/OperationRedline/Resources/Shaders/OperationRedlineMobile.shader"
            shader.write_text(shader.read_text(encoding="utf-8").replace("#pragma target 2.0", "#pragma target removed", 1), encoding="utf-8")
            with self.assertRaisesRegex(unity_validator.UnityMigrationError, "OperationRedlineMobile.shader"):
                unity_validator.validate(workspace)

    def test_rejects_missing_desert_ground_presentation_image(self) -> None:
        with self.copied_workspace() as directory:
            workspace = Path(directory)
            (workspace / "unity/Assets/OperationRedline/Resources/Textures/desert_outpost_ground.png").unlink()
            with self.assertRaisesRegex(unity_validator.UnityMigrationError, "desert_outpost_ground.png"):
                unity_validator.validate(workspace)

    def test_rejects_mobile_controls_that_leak_into_camera_look(self) -> None:
        with self.copied_workspace() as directory:
            workspace = Path(directory)
            controller = workspace / "unity/Assets/OperationRedline/Scripts/OutpostPlayerController.cs"
            controller.write_text(controller.read_text(encoding="utf-8").replace("SetMobileUiExclusions", "RemovedMobileUiExclusions"), encoding="utf-8")
            with self.assertRaisesRegex(unity_validator.UnityMigrationError, "SetMobileUiExclusions"):
                unity_validator.validate(workspace)

    def test_rejects_missing_textured_outpost_presentation_asset(self) -> None:
        with self.copied_workspace() as directory:
            workspace = Path(directory)
            (workspace / "unity/Assets/OperationRedline/Resources/Textures/outpost_corrugated_metal.png").unlink()
            with self.assertRaisesRegex(unity_validator.UnityMigrationError, "outpost_corrugated_metal.png"):
                unity_validator.validate(workspace)

    def test_rejects_missing_primary_pointer_mobile_fallback(self) -> None:
        with self.copied_workspace() as directory:
            workspace = Path(directory)
            controller = workspace / "unity/Assets/OperationRedline/Scripts/OutpostPlayerController.cs"
            controller.write_text(controller.read_text(encoding="utf-8").replace("ReadPrimaryPointerFallback", "RemovedPointerFallback"), encoding="utf-8")
            with self.assertRaisesRegex(unity_validator.UnityMigrationError, "ReadPrimaryPointerFallback"):
                unity_validator.validate(workspace)

    def test_rejects_unscaled_gameplay_clock_removal(self) -> None:
        with self.copied_workspace() as directory:
            workspace = Path(directory)
            game = workspace / "unity/Assets/OperationRedline/Scripts/OperationGame.cs"
            game.write_text(game.read_text(encoding="utf-8").replace("Time.unscaledDeltaTime", "Time.deltaTime"), encoding="utf-8")
            with self.assertRaisesRegex(unity_validator.UnityMigrationError, "Time.unscaledDeltaTime"):
                unity_validator.validate(workspace)

    def test_rejects_missing_rebuild_eventsystem_touch_routing(self) -> None:
        with self.copied_workspace() as directory:
            workspace = Path(directory)
            surface = workspace / "unity/Assets/RedlineRebuild/Scripts/RedlineRebuildTouchSurface.cs"
            surface.write_text(surface.read_text(encoding="utf-8").replace("IPointerDownHandler", "RemovedPointerDown"), encoding="utf-8")
            with self.assertRaisesRegex(unity_validator.UnityMigrationError, "IPointerDownHandler"):
                unity_validator.validate(workspace)

    def test_rejects_rebuild_scaled_simulation_clock(self) -> None:
        with self.copied_workspace() as directory:
            workspace = Path(directory)
            game = workspace / "unity/Assets/RedlineRebuild/Scripts/RedlineRebuildGame.cs"
            game.write_text(game.read_text(encoding="utf-8").replace("Time.unscaledDeltaTime", "Time.deltaTime"), encoding="utf-8")
            with self.assertRaisesRegex(unity_validator.UnityMigrationError, "Time.unscaledDeltaTime"):
                unity_validator.validate(workspace)

    def test_rejects_rebuild_without_direct_start_recovery(self) -> None:
        with self.copied_workspace() as directory:
            workspace = Path(directory)
            game = workspace / "unity/Assets/RedlineRebuild/Scripts/RedlineRebuildGame.cs"
            game.write_text(game.read_text(encoding="utf-8").replace("ShowStartupFailure", "RemovedStartupFailure"), encoding="utf-8")
            with self.assertRaisesRegex(unity_validator.UnityMigrationError, "ShowStartupFailure"):
                unity_validator.validate(workspace)

    def test_rejects_rebuild_without_player_asset_handoff_seam(self) -> None:
        with self.copied_workspace() as directory:
            workspace = Path(directory)
            (workspace / "unity/Assets/RedlineRebuild/Resources/Rebuild/asset_manifest.json").unlink()
            with self.assertRaisesRegex(unity_validator.UnityMigrationError, "asset_manifest.json"):
                unity_validator.validate(workspace)

    def test_rejects_ambiguous_paused_mobile_label(self) -> None:
        with self.copied_workspace() as directory:
            workspace = Path(directory)
            game = workspace / "unity/Assets/OperationRedline/Scripts/OperationGame.cs"
            game.write_text(game.read_text(encoding="utf-8").replace("bindings.pause", "pause.title"), encoding="utf-8")
            with self.assertRaisesRegex(unity_validator.UnityMigrationError, "bindings.pause"):
                unity_validator.validate(workspace)

    def test_rejects_nondeterministic_apk_artifact_handoff(self) -> None:
        with self.copied_workspace() as directory:
            workspace = Path(directory)
            workflow = workspace / ".github/workflows/unity-android.yml"
            workflow.write_text(workflow.read_text(encoding="utf-8").replace("unity-review-artifact/OperationRedline-Unity-review.apk", "removed-apk-handoff"), encoding="utf-8")
            with self.assertRaisesRegex(unity_validator.UnityMigrationError, "unity-review-artifact"):
                unity_validator.validate(workspace)

    def test_rejects_missing_explicit_unvalidated_release_handoff(self) -> None:
        with self.copied_workspace() as directory:
            workspace = Path(directory)
            workflow = workspace / ".github/workflows/unity-android.yml"
            workflow.write_text(workflow.read_text(encoding="utf-8").replace("gh release create \"$tag\"", "removed-release-handoff", 1), encoding="utf-8")
            with self.assertRaisesRegex(unity_validator.UnityMigrationError, "gh release create"):
                unity_validator.validate(workspace)

    def test_rejects_release_handoff_without_visible_sha256(self) -> None:
        with self.copied_workspace() as directory:
            workspace = Path(directory)
            workflow = workspace / ".github/workflows/unity-android.yml"
            workflow.write_text(workflow.read_text(encoding="utf-8").replace("SHA-256: \\`${apk_sha}\\`", "removed-visible-sha", 1), encoding="utf-8")
            with self.assertRaisesRegex(unity_validator.UnityMigrationError, "SHA-256"):
                unity_validator.validate(workspace)


if __name__ == "__main__":
    unittest.main(verbosity=2)
