#!/usr/bin/env python3
"""Fast, dependency-free consistency checks for the source-only project.

This is not a replacement for Godot's importer or an Android device test. It catches
broken res:// links and confirms the committed art follows the promised 128x128
texture constraint before an engine is available.
"""
from __future__ import annotations

import re
import struct
import subprocess
import sys
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEXT_EXTENSIONS = {".gd", ".tscn", ".godot", ".cfg", ".md"}


def error(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    if not (ROOT / "project.godot").is_file():
        error("project.godot is missing")
    scene = ROOT / "scenes/Main.tscn"
    if not scene.is_file():
        error("startup scene is missing")

    workflow = ROOT / ".github/workflows/android-apk.yml"
    if not workflow.is_file():
        error("Android workflow is missing")
    workflow_text = workflow.read_text(encoding="utf-8")
    release_gate = "steps.android_emulator.outcome == 'success'"
    if "id: android_emulator" not in workflow_text or release_gate not in workflow_text:
        error("downloadable APK publishing is not gated on Android emulator success")
    emulator_contract = (
        "Enable KVM acceleration for Android emulator",
        "99-kvm4all.rules",
        "test -e /dev/kvm",
        "sudo chmod 666 /dev/kvm",
        "Install Android emulator runtime dependency",
        "sudo apt-get install --yes libpulse0",
        "libpulse\\.so\\.0",
        "api-level: 29",
        "target: default",
        "disable-linux-hw-accel: false",
        "pre-emulator-launch-script: sh \"$GITHUB_WORKSPACE/scripts/android_emulator_prelaunch_probe.sh\"",
        "The action parses YAML block lines into independent `sh -c` commands.",
        "script: sh \"$GITHUB_WORKSPACE/scripts/android_emulator_probe.sh\"",
        "Commit Android emulator diagnostics if probe fails",
        "ci: capture Android emulator probe diagnostics",
    )
    if not all(requirement in workflow_text for requirement in emulator_contract):
        error("Android emulator gate lacks the required acceleration/install/foreground evidence contract")
    emulator_probe = ROOT / "scripts/android_emulator_probe.sh"
    if not emulator_probe.is_file():
        error("Android emulator probe script is missing")
    emulator_probe_text = emulator_probe.read_text(encoding="utf-8")
    probe_contract = (
        "#!/usr/bin/env sh",
        "workspace=${GITHUB_WORKSPACE:?GITHUB_WORKSPACE must be set}",
        "exec > \"$build_dir/android-emulator-probe.log\" 2>&1",
        "set -x",
        "adb install -r \"$build_dir/OperationRedline-debug.apk\" | tee \"$build_dir/android-emulator-install.log\"",
        "mResumedActivity.*com.operationredline.outpost",
        "if [ \"$foreground\" != true ]; then",
    )
    if not all(requirement in emulator_probe_text for requirement in probe_contract):
        error("Android emulator probe lacks the required POSIX install/foreground evidence contract")
    subprocess.run(["/usr/bin/sh", "-n", str(emulator_probe)], check=True)
    emulator_prelaunch_probe = ROOT / "scripts/android_emulator_prelaunch_probe.sh"
    if not emulator_prelaunch_probe.is_file():
        error("Android emulator prelaunch probe script is missing")
    prelaunch_contract = (
        "#!/usr/bin/env sh",
        "ANDROID_EMULATOR_PRELAUNCH_REACHED",
        "\"$ANDROID_HOME/emulator/emulator\" -version",
        "android-emulator-prelaunch.log",
    )
    prelaunch_text = emulator_prelaunch_probe.read_text(encoding="utf-8")
    if not all(requirement in prelaunch_text for requirement in prelaunch_contract):
        error("Android emulator prelaunch probe lacks the required launch-boundary evidence contract")
    subprocess.run(["/usr/bin/sh", "-n", str(emulator_prelaunch_probe)], check=True)

    subprocess.run([sys.executable, str(ROOT / "tools/validate_physical_qa_evidence.py")], check=True)
    subprocess.run([sys.executable, str(ROOT / "tools/test_validate_physical_qa_evidence.py")], check=True)
    subprocess.run([sys.executable, str(ROOT / "tools/validate_highrise_manifest.py")], check=True)
    subprocess.run([sys.executable, str(ROOT / "tools/test_validate_highrise_manifest.py")], check=True)

    checked_links = 0
    for source in ROOT.rglob("*"):
        relative_source = source.relative_to(ROOT)
        if any(part.startswith(".") or part == "node_modules" for part in relative_source.parts):
            continue
        if source.suffix not in TEXT_EXTENSIONS or not source.is_file():
            continue
        content = source.read_text(encoding="utf-8")
        for resource in re.findall(r"res://([A-Za-z0-9_./-]+)", content):
            checked_links += 1
            candidate = ROOT / resource
            # Godot accepts both files and packed-resource directories in APIs
            # such as DirAccess.open(). A path must exist, but need not be a file.
            if not candidate.exists():
                error(f"{source.relative_to(ROOT)} refers to missing resource res://{resource}")

    textures = sorted((ROOT / "assets/textures").glob("*_128.png"))
    if len(textures) < 4:
        error("expected at least four authored 128x128 textures")
    for texture in textures:
        header = texture.read_bytes()[:24]
        if header[:8] != b"\x89PNG\r\n\x1a\n":
            error(f"{texture.name} is not a PNG")
        width, height = struct.unpack(">II", header[16:24])
        if (width, height) != (128, 128):
            error(f"{texture.name} is {width}x{height}, expected 128x128")

    music = ROOT / "assets/audio/outpost_watch.wav"
    if music.exists():
        with wave.open(str(music), "rb") as stream:
            audio_shape = (
                stream.getnchannels(),
                stream.getsampwidth(),
                stream.getframerate(),
                stream.getnframes(),
            )
        expected_audio_shape = (1, 2, 22050, 352800)
        if audio_shape != expected_audio_shape:
            error(f"{music.name} has {audio_shape}, expected {expected_audio_shape}")
        subprocess.run([sys.executable, str(ROOT / "tools/generate_music.py"), "--check"], check=True)

    for source in (ROOT / "scripts").glob("*.gd"):
        contents = source.read_text(encoding="utf-8")
        if not contents.lstrip().startswith(("extends ", "class_name ")):
            error(f"{source.name} has no Godot script declaration")

    print(f"Project consistency passed: {checked_links} res:// links and {len(textures)} 128x128 textures verified.")


if __name__ == "__main__":
    main()
