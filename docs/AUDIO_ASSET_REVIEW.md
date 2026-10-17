# Background Music Provenance, Mix, and Mobile-Memory Review

## Scope and decision

This review covers one background-music asset only: `assets/audio/outpost_watch.wav`. It is an original, non-lyrical, 16-second tactical loop for the realistic year-2000 Desert Outpost. It is deliberately restrained rather than cinematic, orchestral, futuristic, or associated with any commercial game.

The inspected CC0 Kenney Music Jingles candidates were legally usable but only 1.55–1.76-second stingers, so they were rejected for this purpose. Looping a jingle behind a survival match would be repetitive and would not meet the requested background-music role. No external audio binary is included in this batch.

## Provenance and reproducibility

- **Creator:** Operation Redline project
- **Asset:** `assets/audio/outpost_watch.wav`
- **Generator:** `tools/generate_music.py`
- **License:** Original project asset
- **Source material:** Standard-library mathematical synthesis only; no samples, vocals, melodies from recordings, commercial-IP material, or third-party audio data
- **Reproducibility check:** `python3 tools/generate_music.py --check`
- **SHA-256:** `9611694ac92cea9ae4c0801c8d8c44ee52931dfd0e90b08075bccb40f54edbe9`

The generator's fixed seed and source-controlled synthesis parameters reproduce every PCM frame. `tools/validate_project.py` runs the check as part of source validation.

## Mobile-memory and package review

| Property | Reviewed value | Rationale |
| --- | --- | --- |
| Container | PCM WAV | Godot's built-in import route; no decoder dependency or streaming ambiguity for one small loop. |
| Channels / sample rate / width | Mono / 22,050 Hz / 16-bit | Suitable for the intentionally retro, non-vocal bed while avoiding stereo duplication. |
| Duration | 16 seconds | Four four-second bars permit a musically stable forward loop. |
| Source payload | 705,600 PCM bytes | Approximately 0.67 MiB before engine/resource overhead; far below the 200 MiB package policy. |
| File size | 705,644 bytes | Header plus payload; committed checksum is in `assets_manifest.json`. |
| Runtime ownership | One global `AudioStreamPlayer` in `AudioService` | Prevents duplicate Boot/Main players and preserves a single Music-bus authority. |

The loop is held by one player, not by the Desert world builder or a menu scene. Explicit Music volume zero stops the player; non-zero resumes it. This is a small source/memory review, not a measured physical-device memory profile.

## Mix review

- The player routes exclusively to the existing `Music` bus.
- The player gain is `-16 dB`; at the existing default Music slider value of `0.75` (about `-2.5 dB` linear conversion), the effective bed is about `-18.5 dB` before Master volume.
- Existing rifle/pistol effects are approximately `-5 dB`, reload effects `-8/-9 dB`, and landing effects vary from `-19` to `-8 dB`. The bed therefore leaves transient combat feedback materially ahead of the music.
- Master focus muting remains the final focus-loss policy, so Music resumes at the saved player mix after focus returns.

The normal-Boot audio contract verifies Music-bus routing, forward-loop metadata, zero-volume stop, and non-zero resume. A human headphone/speaker and physical-Android loudness check remains open; no subjective listening or physical-device mix result is claimed here.
