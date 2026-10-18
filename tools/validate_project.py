#!/usr/bin/env python3
"""Fast, dependency-free consistency checks for the source-only project.

This is not a replacement for Godot's importer or an Android device test. It catches
broken res:// links and confirms the committed art follows the promised 128x128
texture constraint before an engine is available.
"""
from __future__ import annotations

import json
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

    physical_qa_template = ROOT / "docs/physical_qa_evidence.template.json"
    if not physical_qa_template.is_file():
        error("physical-device QA evidence template is missing")
    try:
        physical_qa = json.loads(physical_qa_template.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        error(f"physical-device QA evidence template is invalid JSON: {exc}")
    required_device_rows = {f"D{number:02d}_" for number in range(1, 13)}
    actual_device_rows = {key[:4] for key in physical_qa.get("matrix", {})}
    if physical_qa.get("status") != "TEMPLATE_NOT_EVIDENCE" or not required_device_rows.issubset(actual_device_rows):
        error("physical-device QA template is incomplete or misclassified")

    subprocess.run([sys.executable, str(ROOT / "tools/validate_highrise_manifest.py")], check=True)

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
