#!/usr/bin/env python3
"""Validate the authoritative-input contract for the future Highrise graybox.

No M4 geometry belongs in this repository until the director's B2 appendix and
reference are staged. This dependency-free validator distinguishes that truthful
waiting state from a traceable, schema-complete coordinate packet while keeping the
map card locked in both states.
"""
from __future__ import annotations

import hashlib
import json
import math
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "data/highrise/MP_RF_02_graybox_manifest.json"
MAP_RESOURCE_PATH = ROOT / "data/maps/MP_RF_02.tres"
EXPECTED_REFERENCE_PATH = "docs/level_design/rooftop_highrise_map.png"
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
FEATURE_GEOMETRY_KINDS = {
    "lightwell_gap_1": "area",
    "lightwell_gap_2": "area",
    "bridge_1": "link",
    "bridge_2": "link",
    "rappel_link": "link",
    "lift_shaft_link": "link",
    "zipline_link": "link",
    "supply_nodes": "point_collection",
    "wave_routes": "path_collection",
}
ANCHOR_MINIMUMS = {
    "area": 3,
    "link": 2,
    "point_collection": 1,
    "path_collection": 2,
}
REQUIRED_FRAME_FIELDS = {
    "units",
    "origin_description",
    "x_axis_description",
    "z_axis_description",
    "vertical_axis_description",
}
REQUIRED_ZONE_FIELDS = {"x", "z", "width", "depth", "floor_y", "source_reference"}
REQUIRED_STAGING_CONTRACT = {
    "coordinate_frame_fields": sorted(REQUIRED_FRAME_FIELDS),
    "zone_record_fields": sorted(REQUIRED_ZONE_FIELDS),
    "feature_record_fields": ["geometry_kind", "anchors", "source_reference"],
    "feature_geometry_kinds": FEATURE_GEOMETRY_KINDS,
}
SHA256_PATTERN = re.compile(r"^[0-9a-f]{64}$")


class ManifestValidationError(ValueError):
    """A Highrise manifest violates the coordinate-staging contract."""


def fail(message: str) -> None:
    raise ManifestValidationError(message)


def require_nonempty_string(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        fail(f"{label} must be a non-empty string")
    return value


def require_finite_number(value: Any, label: str) -> None:
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
        fail(f"{label} must be a finite number")


def load_json(path: Path) -> dict[str, Any]:
    if not path.is_file():
        fail(f"missing {path}")
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON in {path}: {exc}")
    if not isinstance(data, dict):
        fail("manifest root must be an object")
    return data


def read_locked_map(map_resource_path: Path) -> None:
    if not map_resource_path.is_file():
        fail(f"missing {map_resource_path}")
    resource = map_resource_path.read_text(encoding="utf-8")
    if 'unlock_state = "COMING_SOON"' not in resource or "playable = false" not in resource:
        fail("MP_RF_02 must remain a non-launchable coming-soon card until Gate 2 approval")


def checked_source_file(repository_root: Path, value: Any, label: str, expected_hash: Any) -> Path:
    relative_path = Path(require_nonempty_string(value, label))
    if relative_path.is_absolute() or ".." in relative_path.parts:
        fail(f"{label} must be a safe workspace-relative path")
    resolved = (repository_root / relative_path).resolve()
    try:
        resolved.relative_to(repository_root.resolve())
    except ValueError:
        fail(f"{label} escapes the workspace")
    if not resolved.is_file():
        fail(f"{label} does not resolve to a staged file: {relative_path.as_posix()}")
    if not isinstance(expected_hash, str) or not SHA256_PATTERN.fullmatch(expected_hash):
        fail(f"{label}_sha256 must be a lowercase SHA-256 digest")
    actual_hash = hashlib.sha256(resolved.read_bytes()).hexdigest()
    if actual_hash != expected_hash:
        fail(f"{label} SHA-256 does not match its staged source file")
    return resolved


def validate_waiting_manifest(manifest: dict[str, Any]) -> str:
    source = manifest.get("authoritative_input")
    if not isinstance(source, dict):
        fail("authoritative_input must be an object")
    if source.get("coordinate_spec_available_in_workspace") is not False or source.get("top_down_reference_available_in_workspace") is not False:
        fail("waiting status must explicitly mark both authoritative inputs unavailable")
    if source.get("expected_reference_path") != EXPECTED_REFERENCE_PATH:
        fail(f"authoritative_input.expected_reference_path must remain {EXPECTED_REFERENCE_PATH}")
    require_nonempty_string(source.get("source_note"), "authoritative_input.source_note")
    for forbidden_key in ("coordinate_frame", "coordinates", "features"):
        if forbidden_key in manifest:
            fail(f"waiting manifest must not contain {forbidden_key} data")
    return "awaiting_coordinates"


def validate_coordinate_frame(frame: Any) -> None:
    if not isinstance(frame, dict) or set(frame) != REQUIRED_FRAME_FIELDS:
        fail("coordinate_frame must declare the complete approved frame field set")
    if frame.get("units") != "metres":
        fail("coordinate_frame.units must be metres")
    for key in REQUIRED_FRAME_FIELDS - {"units"}:
        require_nonempty_string(frame.get(key), f"coordinate_frame.{key}")


def validate_zone_records(coordinates: Any) -> None:
    if not isinstance(coordinates, dict) or set(coordinates) != EXPECTED_ZONES:
        fail("staged manifest must provide one coordinate record per required zone")
    for zone, region in coordinates.items():
        if not isinstance(region, dict) or not REQUIRED_ZONE_FIELDS.issubset(region):
            fail(f"staged zone {zone} is missing required coordinate/source fields")
        for field in ("x", "z", "width", "depth", "floor_y"):
            require_finite_number(region[field], f"staged zone {zone}.{field}")
        require_nonempty_string(region["source_reference"], f"staged zone {zone}.source_reference")


def validate_feature_records(features: Any) -> None:
    if not isinstance(features, dict) or set(features) != EXPECTED_FEATURES:
        fail("staged manifest must provide one placement record per required feature")
    for feature, record in features.items():
        if not isinstance(record, dict):
            fail(f"staged feature {feature} must be an object")
        expected_kind = FEATURE_GEOMETRY_KINDS[feature]
        if record.get("geometry_kind") != expected_kind:
            fail(f"staged feature {feature} must use geometry_kind {expected_kind}")
        require_nonempty_string(record.get("source_reference"), f"staged feature {feature}.source_reference")
        anchors = record.get("anchors")
        if not isinstance(anchors, list) or len(anchors) < ANCHOR_MINIMUMS[expected_kind]:
            fail(f"staged feature {feature} lacks the required authoritative anchors")
        for index, anchor in enumerate(anchors):
            if not isinstance(anchor, dict) or set(anchor) != {"x", "y", "z"}:
                fail(f"staged feature {feature} anchor {index} must contain exactly x/y/z")
            for axis in ("x", "y", "z"):
                require_finite_number(anchor[axis], f"staged feature {feature} anchor {index}.{axis}")


def validate_staged_manifest(manifest: dict[str, Any], repository_root: Path) -> str:
    source = manifest.get("authoritative_input")
    if not isinstance(source, dict):
        fail("authoritative_input must be an object")
    if source.get("coordinate_spec_available_in_workspace") is not True:
        fail("staged manifest must truthfully mark its coordinate appendix available")
    if source.get("top_down_reference_available_in_workspace") is not True:
        fail("staged manifest must truthfully mark its top-down reference available")
    require_nonempty_string(source.get("source_revision"), "authoritative_input.source_revision")
    coordinate_file = checked_source_file(
        repository_root,
        source.get("coordinate_spec_path"),
        "authoritative_input.coordinate_spec_path",
        source.get("coordinate_spec_sha256"),
    )
    if source.get("top_down_reference_path") != EXPECTED_REFERENCE_PATH:
        fail(f"authoritative_input.top_down_reference_path must remain {EXPECTED_REFERENCE_PATH}")
    reference_file = checked_source_file(
        repository_root,
        source.get("top_down_reference_path"),
        "authoritative_input.top_down_reference_path",
        source.get("top_down_reference_sha256"),
    )
    if coordinate_file == reference_file:
        fail("coordinate appendix and top-down reference must be distinct staged files")
    validate_coordinate_frame(manifest.get("coordinate_frame"))
    validate_zone_records(manifest.get("coordinates"))
    validate_feature_records(manifest.get("features"))
    return "coordinates_staged"


def validate_manifest(
    manifest_path: Path = MANIFEST_PATH,
    map_resource_path: Path = MAP_RESOURCE_PATH,
    repository_root: Path = ROOT,
) -> str:
    """Validate a manifest and return its concise, reportable status."""
    manifest = load_json(manifest_path)
    if manifest.get("schema_version") != 2 or manifest.get("map_id") != "MP_RF_02":
        fail("schema_version and map_id must identify MP_RF_02 schema 2")
    if manifest.get("declared_footprint_m") != {"width": 120, "depth": 90}:
        fail("declared footprint must remain the reviewed 120 m by 90 m card value")
    if set(manifest.get("required_zones", [])) != EXPECTED_ZONES:
        fail("required zones do not match the recorded Highrise zone contract")
    if set(manifest.get("required_features", [])) != EXPECTED_FEATURES:
        fail("required features do not match the recorded Highrise feature contract")
    if manifest.get("coordinate_staging_contract") != REQUIRED_STAGING_CONTRACT:
        fail("coordinate_staging_contract no longer matches the auditable B2 packet contract")
    read_locked_map(map_resource_path)

    status = manifest.get("status")
    if status == "AWAITING_AUTHORITATIVE_B2_COORDINATES":
        return validate_waiting_manifest(manifest)
    if status == "AUTHORITATIVE_B2_COORDINATES_STAGED":
        return validate_staged_manifest(manifest, repository_root)
    fail(f"unsupported status {status!r}")


def main() -> None:
    try:
        status = validate_manifest()
    except ManifestValidationError as exc:
        print(f"HIGHRISE_MANIFEST_ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
    print(f"HIGHRISE_MANIFEST_PASS status={status} map_locked=true")


if __name__ == "__main__":
    main()
