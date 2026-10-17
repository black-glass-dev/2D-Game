# Asset Import Log

## Logging policy

Every external asset acquisition must record:

- asset identifier and intended in-game use
- creator, source URL, source revision or release version
- license and copied license-file path
- retrieval date, SHA-256, size, target path, and import result
- each failed fallback attempt and the procedural fallback selected

## Existing verified assets

| Asset family | Creator | License | Source/provenance | Import status |
| --- | --- | --- | --- | --- |
| Conventional weapons, outpost modules, barriers, drums, panels, rocks | Kenney | CC0 1.0 | `assets/third_party/kenney_cc0/README.md` | Existing and referenced by runtime |
| Trimmed human Raider base | KayKit / Kay Lousberg | CC0 1.0 | `assets/third_party/kaykit_cc0/README.md` | Existing and referenced by runtime |

## M1 menu and localization assets

| Asset | Creator | License | Source/revision | Retrieval and integrity | Target / use | Result |
| --- | --- | --- | --- | --- | --- | --- |
| Noto Sans Bengali Regular + SemiBold | The Noto Project Authors | SIL OFL 1.1 | `https://github.com/notofonts/noto-fonts` at `ffebf8c1ee449e544955a7e813c54f9b73848eac` | Retrieved 2026-10-15 with sparse Git checkout. Regular SHA-256 `6300c5370cd688b0641343de4c786de6d412bb6c578d129dae75e93a0322dcab` (200,048 bytes); SemiBold SHA-256 `7e6f757050d9c407b215e1ac4069fe12bd76761069d2f77755b8c918b4b3c92a` (206,040 bytes). | `assets/third_party/noto_sans_bengali_ofl/`; shared player-facing Bengali/English UI theme | Imported as unmodified binary copies. License: `assets/third_party/noto_sans_bengali_ofl/OFL.txt`. |

The GitHub release ZIP alternative was intentionally not used because the redirect target was unavailable in the restricted build network. The sparse Git source checkout retrieved the exact font files and license directly from the pinned repository revision.

## M3 original music asset

| Asset | Creator | License | Source/revision | Generation and integrity | Target / use | Result |
| --- | --- | --- | --- | --- | --- | --- |
| Outpost Watch tactical loop | Operation Redline project | Original project asset | `tools/generate_music.py`; deterministic standard-library synthesis, no downloaded/sample audio | Generated 2026-10-17. `assets/audio/outpost_watch.wav`: 705,644 bytes, SHA-256 `9611694ac92cea9ae4c0801c8d8c44ee52931dfd0e90b08075bccb40f54edbe9`; PCM WAV mono, 22,050 Hz, 16-bit, 16 seconds. `python3 tools/generate_music.py --check` reconstructs and verifies its PCM frames. | Global `AudioService` player on `Music`, looped at -16 dB before the player's Music slider; user value zero stops decoding/playback. | Imported as an original, non-lyrical tactical loop. No external audio acquisition was used because the available inspected CC0 jingle candidates were 1.55–1.76-second one-shots, unsuitable as background music. |

## Future Highrise assets

Highrise art acquisition begins only after Gate 2 and only after each required asset is decomposed into versioned `assets_manifest.json` entries.
