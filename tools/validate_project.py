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
        "api-level: 29",
        "target: default",
        "-accel on",
        "disable-linux-hw-accel: false",
        "android-emulator-runner invokes this block with /usr/bin/sh",
        "exec > build/android-emulator-probe.log 2>&1",
        "set -eux",
        "if [ \"$foreground\" != true ]; then",
        "Commit Android emulator diagnostics if probe fails",
        "ci: capture Android emulator probe diagnostics",
        "adb install -r build/OperationRedline-debug.apk | tee build/android-emulator-install.log",
        "mResumedActivity.*com.operationredline.outpost",
    )
    if not all(requirement in workflow_text for requirement in emulator_contract):
        error("Android emulator gate lacks the required acceleration/install/foreground evidence contract")

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
