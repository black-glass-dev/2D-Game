# MP_RF_02 Highrise Graybox Input Ledger

## Batch 16 status

M4 remains in technical preparation. No Highrise scene, collision, navigation mesh, spawn profile, cover point, art geometry, or launch route is created in this batch. The map remains an honest `COMING_SOON` card and cannot launch.

The director's B2 coordinate appendix and top-down reference—not an inferred image—remain the authority for the eventual graybox. Neither source is present in this checkout. The repository records that absence and validates the future staging path instead of replacing the missing inputs with guessed positions.

## Confirmed contract

| Item | Status | Source / boundary |
| --- | --- | --- |
| Map ID | Confirmed | `MP_RF_02` in `data/maps/MP_RF_02.tres` |
| Card footprint | Confirmed metadata | 120 m × 90 m; this is not a substitute for individual zone coordinates |
| Required zones | Confirmed topology | Roof A/B/C, office, lobby, helipad, safe room, breach |
| Required connective/system features | Confirmed topology | Two lightwell gaps, two bridges, rappel, lift-shaft, zipline, supply nodes, wave routes |
| Exact coordinates/heights/gaps | Missing from workspace | Do not infer or substitute them |
| Top-down diagram binary | Missing from workspace | Expected path: `docs/level_design/rooftop_highrise_map.png` |
| M4 playable scene | Intentionally absent | `MP_RF_02` stays non-launchable until graybox/nav/Gate 2 |

## Enforced waiting gate

`data/highrise/MP_RF_02_graybox_manifest.json` is schema version 2 and is the source-controlled M4 input contract. Its current status is `AWAITING_AUTHORITATIVE_B2_COORDINATES`.

`tools/validate_highrise_manifest.py`, called by `tools/validate_project.py`, requires all of the following while that status is active:

1. the reviewed 120 m × 90 m card footprint and complete zone/feature lists remain intact;
2. the source-absence note and expected reference location remain explicit;
3. no `coordinate_frame`, zone `coordinates`, or feature placement data exists in the waiting manifest; and
4. the Highrise card remains `COMING_SOON` with `playable = false`.

The validator regression suite at `tools/test_validate_highrise_manifest.py` is also run by project validation. Its coordinate values are temporary synthetic test fixtures only; they are never stored as MP_RF_02 design data.

## Auditable coordinate packet required before graybox work

When the authoritative B2 input becomes available, a later batch must change the manifest to `AUTHORITATIVE_B2_COORDINATES_STAGED` and satisfy every item below. Passing this gate still does **not** unlock the map or authorize art.

### 1. Provenance and immutable source files

Stage two distinct, workspace-relative files:

- the B2 coordinate appendix; and
- the top-down reference binary at `docs/level_design/rooftop_highrise_map.png`.

The manifest must identify both paths, a non-empty source revision, and lowercase SHA-256 hashes that exactly match the staged files. The validator rejects absolute/traversing paths, missing files, duplicate files, and mismatched hashes.

### 2. Coordinate frame

Record the B2 frame verbatim: units (`metres`), origin description, X-axis description, Z-axis description, and vertical-axis description. This stops a later scene from silently treating local coordinates or vertical values as something else.

### 3. Zone records

Every required zone must receive an exact `x`, `z`, `width`, `depth`, and `floor_y` value plus a non-empty source reference back to the authoritative appendix. The validator requires exactly the recorded Roof A/B/C, office, lobby, helipad, safe-room, and breach keys—no missing or renamed zone may proceed.

### 4. Feature placement records

Every recorded feature must be traceable to the B2 source and include authoritative 3D anchors. The contract intentionally distinguishes semantics without supplying a single placement itself:

| Feature | Required packet geometry |
| --- | --- |
| `lightwell_gap_1`, `lightwell_gap_2` | area, at least three anchors |
| `bridge_1`, `bridge_2`, `rappel_link`, `lift_shaft_link`, `zipline_link` | link, at least two anchors |
| `supply_nodes` | point collection, at least one anchor |
| `wave_routes` | path collection, at least two anchors |

Every anchor is an exact finite `x`/`y`/`z` triplet copied from the authoritative packet. These are schema requirements, not placeholder positions.

## Follow-on sequence after a valid packet

1. retain the map lock and create the graybox strictly from the validated packet;
2. populate the coordinate-free C++ `RouteTopology` only with the validated zone/link endpoints, then add map-specific route tests;
3. resolve `NavigationRegion3D`, floor links, collision, spawns, wave routes, and at least twelve cover hotspots;
4. capture roof corners, top-down, office/lobby walkthrough, and navigation evidence;
5. attach those artifacts to QA; and
6. request Gate 2 before any art pass or map unlock.

This ledger and its tests are preparation artifacts only. They are not proof that Highrise gameplay, navigation, captures, Gate 2, or physical-device testing has completed.
