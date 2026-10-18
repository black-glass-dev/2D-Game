#!/usr/bin/env python3
"""Validate the coordinate gate for the future Rooftop Highrise graybox.

The repository intentionally has no fabricated M4 geometry. This guard keeps the
MP_RF_02 card non-launchable until the director's authoritative B2 coordinates are
actually staged, then gives later graybox work a deterministic input contract.
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "data/highrise/MP_RF_02_graybox_manifest.json"
MAP_RESOURCE_PATH = ROOT / "data/maps/MP_RF_02.tres"
EXPECTED_ZONES = {
    "roof_a",
    "roof_b",
    "roof_c",
    "office",
    "lobby",
    "helipad",
    "safe_room",
    "breach",
}
EXPECTED_FEATURES = {
    "lightwell_gap_1",
    "lightwell_gap_2",
    "bridge_1",
    "bridge_2",
    "rappel_link",
    "lift_shaft_link",
    "zipline_link",
    "supply_nodes",
    "wave_routes",
}


def fail(message: str) -> None:
    raise SystemExit(f"HIGHRISE_MANIFEST_ERROR: {message}")


def main() -> None:
    if not MANIFEST_PATH.is_file():
        fail(f"missing {MANIFEST_PATH.relative_to(ROOT)}")
    if not MAP_RESOURCE_PATH.is_file():
        fail(f"missing {MAP_RESOURCE_PATH.relative_to(ROOT)}")
    try:
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON: {exc}")

    if manifest.get("schema_version") != 1 or manifest.get("map_id") != "MP_RF_02":
        fail("schema_version and map_id must identify MP_RF_02 schema 1")
    footprint = manifest.get("declared_footprint_m")
    if footprint != {"width": 120, "depth": 90}:
        fail("declared footprint must remain the reviewed 120 m by 90 m card value")
    if set(manifest.get("required_zones", [])) != EXPECTED_ZONES:
        fail("required zones do not match the recorded Highrise zone contract")
    if set(manifest.get("required_features", [])) != EXPECTED_FEATURES:
        fail("required features do not match the recorded Highrise feature contract")

    status = manifest.get("status")
    map_resource = MAP_RESOURCE_PATH.read_text(encoding="utf-8")
    if status == "AWAITING_AUTHORITATIVE_B2_COORDINATES":
        source = manifest.get("authoritative_input", {})
        if source.get("coordinate_spec_available_in_workspace") or source.get("top_down_reference_available_in_workspace"):
            fail("available source inputs require a staged-coordinate manifest, not waiting status")
        if "coordinates" in manifest:
            fail("waiting manifest must not contain invented coordinate data")
        if 'unlock_state = "COMING_SOON"' not in map_resource or "playable = false" not in map_resource:
            fail("MP_RF_02 must remain a non-launchable coming-soon card while inputs are absent")
        print("HIGHRISE_MANIFEST_PASS status=awaiting_coordinates map_locked=true")
        return

    if status == "AUTHORITATIVE_B2_COORDINATES_STAGED":
        coordinates = manifest.get("coordinates")
        if not isinstance(coordinates, dict) or set(coordinates) != EXPECTED_ZONES:
            fail("staged manifest must provide one coordinate record per required zone")
        for zone, region in coordinates.items():
            if not isinstance(region, dict) or not {"x", "z", "width", "depth", "floor_y"}.issubset(region):
                fail(f"staged zone {zone} is missing x/z/width/depth/floor_y")
        print("HIGHRISE_MANIFEST_PASS status=coordinates_staged map_locked=true")
        return

    fail(f"unsupported status {status!r}")


if __name__ == "__main__":
    main()
