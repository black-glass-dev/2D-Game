#!/usr/bin/env python3
"""Generate original, deliberately low-resolution textures for Operation Redline.

The script uses only Python's standard library so every checked-in PNG is reproducible.
"""
from __future__ import annotations

import random
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "textures"
SIZE = 128


def png(path: Path, pixels: list[list[tuple[int, int, int, int]]]) -> None:
    raw = b"".join(b"\0" + b"".join(bytes(pixel) for pixel in row) for row in pixels)
    def chunk(kind: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
    data = b"\x89PNG\r\n\x1a\n"
    data += chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0))
    data += chunk(b"IDAT", zlib.compress(raw, 9))
    data += chunk(b"IEND", b"")
    path.write_bytes(data)


def new(color: tuple[int, int, int]) -> list[list[tuple[int, int, int, int]]]:
    return [[(*color, 255) for _ in range(SIZE)] for _ in range(SIZE)]


def rect(img, x, y, w, h, color):
    for yy in range(max(0, y), min(SIZE, y + h)):
        for xx in range(max(0, x), min(SIZE, x + w)):
            img[yy][xx] = (*color, 255)


def make_sand() -> list[list[tuple[int, int, int, int]]]:
    random.seed(12801)
    image = new((183, 127, 71))
    for y in range(SIZE):
        for x in range(SIZE):
            grain = random.choice([-8, -4, 0, 0, 2, 5])
            image[y][x] = (max(0, 183 + grain), max(0, 127 + grain), max(0, 71 + grain), 255)
    for _ in range(85):
        x, y = random.randrange(SIZE), random.randrange(SIZE)
        rect(image, x, y, random.randrange(1, 4), 1, random.choice([(117, 76, 43), (218, 161, 92), (143, 94, 50)]))
    for offset in (18, 66, 108):
        for step in range(0, 96, 5):
            x = (step + offset) % SIZE
            y = (step * 2 + offset) % SIZE
            rect(image, x, y, 4, 1, (155, 99, 52))
    return image


def make_concrete() -> list[list[tuple[int, int, int, int]]]:
    random.seed(12802)
    image = new((116, 111, 98))
    for y in range(SIZE):
        for x in range(SIZE):
            v = random.choice([-8, -4, 0, 0, 0, 3, 5])
            base = 116 + v
            image[y][x] = (base, base - 5, base - 14, 255)
    for x in range(0, SIZE, 32):
        rect(image, x, 0, 2, SIZE, (82, 79, 72))
        rect(image, x + 2, 0, 1, SIZE, (151, 143, 126))
    for y in range(0, SIZE, 32):
        rect(image, 0, y, SIZE, 2, (82, 79, 72))
        rect(image, 0, y + 2, SIZE, 1, (151, 143, 126))
    for _ in range(26):
        x, y = random.randrange(SIZE), random.randrange(SIZE)
        for step in range(random.randrange(5, 18)):
            if x + step < SIZE and y + step // 3 < SIZE:
                image[y + step // 3][x + step] = (61, 60, 56, 255)
    return image


def make_metal() -> list[list[tuple[int, int, int, int]]]:
    random.seed(12803)
    image = new((92, 109, 101))
    for y in range(SIZE):
        for x in range(SIZE):
            scan = 8 if (y % 8 in (0, 1)) else 0
            n = random.choice([-3, 0, 1, 2])
            image[y][x] = (92 + n + scan, 109 + n + scan, 101 + n + scan, 255)
    for x in range(0, SIZE, 32):
        rect(image, x, 0, 2, SIZE, (47, 62, 58))
        for y in range(8, SIZE, 16):
            rect(image, x + 4, y, 3, 3, (170, 163, 125))
    for _ in range(20):
        x, y = random.randrange(SIZE), random.randrange(SIZE)
        rect(image, x, y, random.randrange(5, 17), 1, (54, 74, 67))
    return image


def make_crate() -> list[list[tuple[int, int, int, int]]]:
    random.seed(12804)
    image = new((143, 91, 48))
    for y in range(SIZE):
        for x in range(SIZE):
            v = random.choice([-10, -4, 0, 3, 5])
            image[y][x] = (143 + v, 91 + v, 48 + v, 255)
    for y in range(0, SIZE, 31):
        rect(image, 0, y, SIZE, 3, (72, 46, 29))
    for x in range(0, SIZE, 29):
        rect(image, x, 0, 3, SIZE, (75, 47, 29))
    for offset in range(-32, 160, 48):
        for s in range(32):
            x, y = offset + s, s
            if 0 <= x < SIZE and 0 <= y < SIZE:
                rect(image, x, y, 4, 4, (63, 42, 28))
    return image


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, image in {
        "sand_128.png": make_sand(),
        "concrete_128.png": make_concrete(),
        "painted_metal_128.png": make_metal(),
        "crate_128.png": make_crate(),
    }.items():
        png(OUT / name, image)
        print(f"wrote {name}")


if __name__ == "__main__":
    main()
