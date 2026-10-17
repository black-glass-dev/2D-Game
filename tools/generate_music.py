#!/usr/bin/env python3
"""Generate the small original in-game Outpost Watch music loop.

The output is deliberately simple, deterministic, and source-controlled: it uses
only standard-library synthesis rather than sampled melodies or third-party audio.
Run this script from the repository root to refresh assets/audio/outpost_watch.wav.
"""
from __future__ import annotations

import argparse
import math
import random
import wave
from pathlib import Path

SAMPLE_RATE = 22_050
DURATION_SECONDS = 16
CHANNELS = 1
SAMPLE_WIDTH_BYTES = 2
ROOT = Path(__file__).resolve().parents[1]
OUTPUT_PATH = ROOT / "assets/audio/outpost_watch.wav"

# A restrained D-minor watch pattern. Each value begins a four-second bar; the
# final bar shares the opening root to make the forward loop musically stable.
ROOTS = (146.832, 116.541, 130.813, 146.832)
IS_MINOR = (True, False, False, True)


def sine(frequency: float, time_seconds: float) -> float:
    return math.sin(math.tau * frequency * time_seconds)


def triangle(frequency: float, time_seconds: float) -> float:
    phase = (frequency * time_seconds) % 1.0
    return 1.0 - 4.0 * abs(phase - 0.5)


def raised_edge(value: float, length: float, fade_seconds: float) -> float:
    """Silence the ends so the imported forward loop never clicks."""
    if value < fade_seconds:
        return 0.5 - 0.5 * math.cos(math.pi * value / fade_seconds)
    if value > length - fade_seconds:
        return 0.5 - 0.5 * math.cos(math.pi * (length - value) / fade_seconds)
    return 1.0


def synthesize() -> bytes:
    total_frames = SAMPLE_RATE * DURATION_SECONDS
    rng = random.Random(2000)
    payload = bytearray()

    for frame in range(total_frames):
        time_seconds = frame / SAMPLE_RATE
        bar_index = min(int(time_seconds // 4.0), len(ROOTS) - 1)
        bar_time = time_seconds % 4.0
        root = ROOTS[bar_index]
        third_ratio = 6.0 / 5.0 if IS_MINOR[bar_index] else 5.0 / 4.0

        # Low drone and barely detuned pad deliberately remain below weapon SFX.
        bass = 0.15 * sine(root * 0.5, time_seconds)
        pad = 0.045 * (
            sine(root, time_seconds)
            + 0.78 * sine(root * third_ratio, time_seconds)
            + 0.55 * sine(root * 1.5, time_seconds)
        )
        pad *= 0.88 + 0.12 * sine(0.0625, time_seconds)

        # A sparse, non-sampled arpeggio supplies the retro tactical pulse.
        beat_position = time_seconds % 0.5
        step = int(time_seconds / 0.5) % 8
        ratios = (1.0, third_ratio, 1.5, 2.0, 1.5, third_ratio, 1.0, 1.5)
        arpeggio_envelope = math.exp(-beat_position * 7.0)
        arpeggio = 0.060 * triangle(root * ratios[step] * 2.0, time_seconds) * arpeggio_envelope

        # Minimal kick/tick texture; seeded noise makes the generated file repeatable.
        kick_position = time_seconds % 2.0
        kick_envelope = math.exp(-kick_position * 8.0)
        kick = 0.075 * sine(58.0 - kick_position * 18.0, time_seconds) * kick_envelope
        tick_position = time_seconds % 1.0
        tick = (rng.random() * 2.0 - 1.0) * 0.018 * math.exp(-tick_position * 32.0)

        sample = (bass + pad + arpeggio + kick + tick) * raised_edge(time_seconds, DURATION_SECONDS, 0.025)
        sample = max(-0.92, min(0.92, sample))
        payload.extend(int(sample * 32767.0).to_bytes(2, byteorder="little", signed=True))

    return bytes(payload)


def write_output(output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(output_path), "wb") as output:
        output.setnchannels(CHANNELS)
        output.setsampwidth(SAMPLE_WIDTH_BYTES)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(synthesize())


def check_output(output_path: Path) -> None:
    if not output_path.is_file():
        raise SystemExit(f"Missing generated music file: {output_path}")
    with wave.open(str(output_path), "rb") as output:
        shape = (
            output.getnchannels(),
            output.getsampwidth(),
            output.getframerate(),
            output.getnframes(),
        )
        frames = output.readframes(output.getnframes())
    expected_shape = (CHANNELS, SAMPLE_WIDTH_BYTES, SAMPLE_RATE, SAMPLE_RATE * DURATION_SECONDS)
    if shape != expected_shape or frames != synthesize():
        raise SystemExit(f"Generated music differs from tools/generate_music.py: {output_path}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=OUTPUT_PATH)
    parser.add_argument("--check", action="store_true", help="verify that the committed output matches this generator")
    arguments = parser.parse_args()
    if arguments.check:
        check_output(arguments.output)
        print(f"Verified {arguments.output} ({SAMPLE_RATE} Hz, {CHANNELS} channel, {DURATION_SECONDS} seconds).")
    else:
        write_output(arguments.output)
        print(f"Wrote {arguments.output} ({SAMPLE_RATE} Hz, {CHANNELS} channel, {DURATION_SECONDS} seconds).")


if __name__ == "__main__":
    main()
