# MP_RF_02 Highrise Graybox Input Ledger

## Batch 15 status

M4 technical preparation has started, but no graybox scene, collision, navigation mesh, spawn profile, cover point, or art geometry is created in this batch. The map remains an honest `COMING_SOON` card and cannot launch.

The task brief, not an inferred image, remains the authority for the eventual B2 layout. The original coordinate appendix and top-down attachment are not available in this checkout. The repository records that absence rather than replacing it with guessed positions.

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

## Enforced input gate

`data/highrise/MP_RF_02_graybox_manifest.json` is the source-controlled M4 input contract. Its current status is `AWAITING_AUTHORITATIVE_B2_COORDINATES`.

`tools/validate_highrise_manifest.py`, called by `tools/validate_project.py`, enforces all of the following:

1. the declared 120 m × 90 m card footprint and required zone/feature lists remain intact;
2. waiting status cannot contain fabricated coordinate records;
3. the Highrise card remains `COMING_SOON` and `playable = false` while authoritative inputs are absent; and
4. later staged-coordinate status must provide `x`, `z`, `width`, `depth`, and `floor_y` for every required zone before graybox creation begins.

## Coordinate staging protocol

When the authoritative B2 coordinate appendix becomes available, the next M4 batch must:

1. record its source location/revision in the manifest's `authoritative_input` block;
2. set the input-availability fields truthfully;
3. replace waiting status with `AUTHORITATIVE_B2_COORDINATES_STAGED` and add each required zone's exact coordinate record;
4. retain the map lock while a root scene, collision, navigation, floor links, cover/spawn data, and capture harness are built;
5. attach navigation/capture evidence to QA; and
6. request Gate 2 only after the required graybox evidence exists.

This ledger is deliberately a preparation artifact, not proof that Highrise gameplay, art, navigation, or Gate 2 has been completed.
