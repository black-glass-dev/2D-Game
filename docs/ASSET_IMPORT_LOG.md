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

## New Highrise/menu assets

No new external asset download has been attempted in M0. Acquisition begins only when M5 asset needs have been decomposed into the versioned `assets_manifest.json` entries.
