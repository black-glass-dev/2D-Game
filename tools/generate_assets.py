#!/usr/bin/env python3
"""Generate original seamless PBR-style texture maps for Operation Redline.

No third-party images are used.  The maps are generated from deterministic math
and standard-library PNG writing, so the visual asset set stays reproducible and
small enough for mobile distribution.
"""
from __future__ import annotations

import math
import random
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "textures"
SIZE = 512


def clamp(v: float) -> int:
    return max(0, min(255, int(v)))


def chunk(kind: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)


def png(path: Path, pixels: list[list[tuple[int, int, int, int]]]) -> None:
    raw = b"".join(b"\0" + b"".join(bytes(pixel) for pixel in row) for row in pixels)
    data = b"\x89PNG\r\n\x1a\n"
    data += chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0))
    data += chunk(b"IDAT", zlib.compress(raw, 8))
    data += chunk(b"IEND", b"")
    path.write_bytes(data)


def seamless_noise(x: float, y: float, seed: int = 0) -> float:
    """A periodic layered field, avoiding a hard edge at tile seams."""
    n = 0.0
    for octave, weight in ((1, 1.0), (2, 0.5), (4, 0.25), (8, 0.12), (16, 0.06)):
        a = (x * octave + seed * 0.173) * math.tau
        b = (y * octave - seed * 0.119) * math.tau
        n += (math.sin(a + math.sin(b * 1.71)) + math.cos(b * 1.37 - math.sin(a))) * weight
    return n / 3.86


def pixels_for(kind: str) -> list[list[tuple[int, int, int, int]]]:
    palette = {
        "sand": (155, 88, 48), "concrete": (87, 96, 93), "metal": (54, 72, 70),
        "crate": (107, 61, 38), "rock": (92, 60, 52), "asphalt": (50, 55, 54),
    }
    base = palette[kind]
    image: list[list[tuple[int, int, int, int]]] = []
    for iy in range(SIZE):
        row = []
        y = iy / SIZE
        for ix in range(SIZE):
            x = ix / SIZE
            n = seamless_noise(x, y, len(kind) * 11)
            detail = seamless_noise(x * 2.3 % 1.0, y * 2.3 % 1.0, 19)
            value = n * 19.0 + detail * 9.0
            r, g, b = base
            if kind == "sand":
                ripple = math.sin((x * 19.0 + math.sin(y * 8.0)) * math.tau) * 5.0
                pebble = 17.0 if (int(x * 87) * 19 + int(y * 83) * 31) % 97 == 0 else 0.0
                row.append((clamp(r + value + ripple - pebble), clamp(g + value * .72 + ripple - pebble), clamp(b + value * .42 - pebble), 255))
            elif kind == "concrete":
                seam = 0.0
                if min(abs((x * 4) % 1 - .5), abs((y * 4) % 1 - .5)) < .012:
                    seam = -31.0
                crack = -34.0 if abs(math.sin((x * 11 + y * 5) * math.tau)) < .014 and (ix + iy) % 3 == 0 else 0.0
                row.append((clamp(r + value + seam + crack), clamp(g + value + seam + crack), clamp(b + value + seam + crack), 255))
            elif kind == "metal":
                rib = math.sin(y * math.tau * 22.0) * 13.0
                rust = max(0.0, seamless_noise(x * 1.7 % 1.0, y * 1.7 % 1.0, 43) - .32) * 62
                row.append((clamp(r + value + rust), clamp(g + value + rib - rust * .42), clamp(b + value + rib - rust * .66), 255))
            elif kind == "crate":
                slat = -28 if abs((y * 7) % 1 - .5) < .017 else 0
                wear = max(0.0, n - .25) * 54
                row.append((clamp(r + value - wear + slat), clamp(g + value * .6 - wear + slat), clamp(b + value * .35 - wear + slat), 255))
            elif kind == "rock":
                strata = math.sin((y * 13 + x * 1.6) * math.tau) * 18.0
                row.append((clamp(r + value + strata), clamp(g + value * .58 + strata * .50), clamp(b + value * .42 + strata * .45), 255))
            else:
                aggregate = 23.0 if (int(x * 103) * 47 + int(y * 101) * 23) % 127 == 0 else 0.0
                row.append((clamp(r + value + aggregate), clamp(g + value + aggregate), clamp(b + value + aggregate), 255))
        image.append(row)
    return image


def make_normal() -> list[list[tuple[int, int, int, int]]]:
    image = []
    for iy in range(SIZE):
        row = []
        y = iy / SIZE
        for ix in range(SIZE):
            x = ix / SIZE
            left = seamless_noise((x - 1 / SIZE) % 1, y, 17)
            right = seamless_noise((x + 1 / SIZE) % 1, y, 17)
            up = seamless_noise(x, (y - 1 / SIZE) % 1, 17)
            down = seamless_noise(x, (y + 1 / SIZE) % 1, 17)
            nx, ny, nz = (left - right) * 5.0, (up - down) * 5.0, 1.0
            length = math.sqrt(nx * nx + ny * ny + nz * nz)
            row.append((clamp((nx / length * .5 + .5) * 255), clamp((ny / length * .5 + .5) * 255), clamp((nz / length * .5 + .5) * 255), 255))
        image.append(row)
    return image


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    aliases = {
        # Existing 128x128 pixel-art maps remain untouched for legacy/UI use.
        # The new 512 maps are terrain/building PBR detail maps with mipmaps.
        "sand": ["sand_pbr_512.png"],
        "concrete": ["concrete_pbr_512.png"],
        "metal": ["corrugated_metal_512.png"],
        "crate": ["weathered_crate_512.png"],
        "rock": ["rock_strata_512.png"],
        "asphalt": ["asphalt_512.png"],
    }
    for kind, names in aliases.items():
        image = pixels_for(kind)
        for name in names:
            png(OUT / name, image)
            print(f"wrote {name}")
    png(OUT / "terrain_detail_normal_512.png", make_normal())
    print("wrote terrain_detail_normal_512.png")


if __name__ == "__main__":
    main()
