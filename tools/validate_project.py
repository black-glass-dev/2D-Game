#!/usr/bin/env python3
"""Fast, dependency-free consistency checks for the source-only project.

This is not a replacement for Godot's importer or an Android device test. It catches
broken res:// links and confirms the committed art follows the promised 128x128
texture constraint before an engine is available.
"""
from __future__ import annotations

import re
import struct
import sys
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
            if not candidate.is_file():
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

    for source in (ROOT / "scripts").glob("*.gd"):
        contents = source.read_text(encoding="utf-8")
        if not contents.lstrip().startswith(("extends ", "class_name ")):
            error(f"{source.name} has no Godot script declaration")

    print(f"Project consistency passed: {checked_links} res:// links and {len(textures)} 128x128 textures verified.")


if __name__ == "__main__":
    main()
