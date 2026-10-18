#!/usr/bin/env python3
"""Dependency-free regression tests for the Highrise coordinate staging gate.

All staged coordinate values in this file are temporary synthetic test fixtures.
They are never written to project data and must not be interpreted as MP_RF_02
level design.
"""
from __future__ import annotations

import copy
import hashlib
import json
import tempfile
import unittest
from pathlib import Path

import validate_highrise_manifest as highrise

ROOT = Path(__file__).resolve().parents[1]


def source_digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def locked_map_text() -> str:
    return 'unlock_state = "COMING_SOON"\nplayable = false\n'


class HighriseManifestTests(unittest.TestCase):
    def test_committed_waiting_manifest_validates(self) -> None:
        status = highrise.validate_manifest()
        self.assertEqual(status, "awaiting_coordinates")

    def test_waiting_manifest_rejects_coordinate_payload(self) -> None:
        manifest = json.loads((ROOT / "data/highrise/MP_RF_02_graybox_manifest.json").read_text(encoding="utf-8"))
        manifest["coordinates"] = {}
        with tempfile.TemporaryDirectory() as temporary_directory:
            workspace = Path(temporary_directory)
            manifest_path = workspace / "manifest.json"
            map_path = workspace / "MP_RF_02.tres"
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
            map_path.write_text(locked_map_text(), encoding="utf-8")
            with self.assertRaisesRegex(highrise.ManifestValidationError, "must not contain coordinates"):
                highrise.validate_manifest(manifest_path, map_path, workspace)

    def test_staged_packet_requires_traceable_sources_and_feature_anchors(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            workspace = Path(temporary_directory)
            coordinate_path = workspace / "docs/level_design/MP_RF_02_B2_coordinates.txt"
            reference_path = workspace / "docs/level_design/rooftop_highrise_map.png"
            coordinate_path.parent.mkdir(parents=True)
            coordinate_path.write_text("synthetic test coordinate source", encoding="utf-8")
            reference_path.write_bytes(b"synthetic test reference")
            manifest_path = workspace / "manifest.json"
            map_path = workspace / "data/maps/MP_RF_02.tres"
            map_path.parent.mkdir(parents=True)
            map_path.write_text(locked_map_text(), encoding="utf-8")

            manifest = json.loads((ROOT / "data/highrise/MP_RF_02_graybox_manifest.json").read_text(encoding="utf-8"))
            manifest["status"] = "AUTHORITATIVE_B2_COORDINATES_STAGED"
            manifest["authoritative_input"] = {
                "coordinate_spec_available_in_workspace": True,
                "top_down_reference_available_in_workspace": True,
                "source_revision": "synthetic-test-revision",
                "coordinate_spec_path": "docs/level_design/MP_RF_02_B2_coordinates.txt",
                "coordinate_spec_sha256": source_digest(coordinate_path),
                "top_down_reference_path": "docs/level_design/rooftop_highrise_map.png",
                "top_down_reference_sha256": source_digest(reference_path),
            }
            manifest["coordinate_frame"] = {
                "units": "metres",
                "origin_description": "synthetic test origin",
                "x_axis_description": "synthetic test x axis",
                "z_axis_description": "synthetic test z axis",
                "vertical_axis_description": "synthetic test vertical axis",
            }
            manifest["coordinates"] = {
                zone: {
                    "x": 0.0,
                    "z": 0.0,
                    "width": 1.0,
                    "depth": 1.0,
                    "floor_y": 0.0,
                    "source_reference": "synthetic test source",
                }
                for zone in highrise.EXPECTED_ZONES
            }
            manifest["features"] = {
                feature: {
                    "geometry_kind": geometry_kind,
                    "source_reference": "synthetic test source",
                    "anchors": [
                        {"x": float(index), "y": 0.0, "z": 0.0}
                        for index in range(highrise.ANCHOR_MINIMUMS[geometry_kind])
                    ],
                }
                for feature, geometry_kind in highrise.FEATURE_GEOMETRY_KINDS.items()
            }
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

            self.assertEqual(
                highrise.validate_manifest(manifest_path, map_path, workspace),
                "coordinates_staged",
            )

            tampered_manifest = copy.deepcopy(manifest)
            tampered_manifest["features"]["bridge_1"]["anchors"] = [{"x": 0.0, "y": 0.0, "z": 0.0}]
            manifest_path.write_text(json.dumps(tampered_manifest), encoding="utf-8")
            with self.assertRaisesRegex(highrise.ManifestValidationError, "required authoritative anchors"):
                highrise.validate_manifest(manifest_path, map_path, workspace)

            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
            coordinate_path.write_text("tampered source", encoding="utf-8")
            with self.assertRaisesRegex(highrise.ManifestValidationError, "SHA-256 does not match"):
                highrise.validate_manifest(manifest_path, map_path, workspace)


if __name__ == "__main__":
    unittest.main(verbosity=2)
