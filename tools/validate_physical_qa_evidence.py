#!/usr/bin/env python3
"""Validate the evidence boundary for a physical Android QA record.

The committed template is intentionally not evidence. A future completed record can
be checked locally before release review so a blank identity, missing install output,
or unsupported PASS claim cannot be mistaken for physical-device validation.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
TEMPLATE_PATH = ROOT / "docs/physical_qa_evidence.template.json"
PACKAGE_ID = "com.operationredline.outpost"
SCHEMA_VERSION = 1
TEMPLATE_STATUS = "TEMPLATE_NOT_EVIDENCE"
EVIDENCE_STATUS = "PHYSICAL_DEVICE_EVIDENCE"
NOT_TESTED_CLASSIFICATION = "NOT_PHYSICAL_DEVICE_TESTED"
TESTED_CLASSIFICATION = "PHYSICAL_DEVICE_TESTED"
EXPECTED_ROWS = (
    "D01_install_update",
    "D02_landscape_boot",
    "D03_touch_movement_look",
    "D04_touch_fire_safety",
    "D05_touch_actions_hud",
    "D06_keyboard_mouse",
    "D07_gamepad",
    "D08_back_focus",
    "D09_settings_language_quality",
    "D10_audio_mix",
    "D11_survival_regression",
    "D12_performance_thermal",
)
COMPLETE_RESULTS = {"PASS", "FAIL", "BLOCKED"}
COMMIT_PATTERN = re.compile(r"^[0-9a-f]{7,64}$")
SHA256_PATTERN = re.compile(r"^[0-9a-f]{64}$")


class PhysicalQaValidationError(ValueError):
    """A QA record violates the evidence/identity contract."""


def fail(message: str) -> None:
    raise PhysicalQaValidationError(message)


def require_string(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        fail(f"{label} must be a non-empty string")
    return value


def require_reference(value: Any, label: str) -> None:
    reference = require_string(value, label)
    if reference.startswith("<") or reference.endswith(">"):
        fail(f"{label} must be a concrete evidence reference, not a placeholder")


def require_object(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        fail(f"{label} must be an object")
    return value


def load_record(path: Path) -> dict[str, Any]:
    if not path.is_file():
        fail(f"missing {path}")
    try:
        record = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON in {path}: {exc}")
    return require_object(record, "record")


def validate_matrix_shape(matrix: Any) -> dict[str, Any]:
    matrix_object = require_object(matrix, "matrix")
    if tuple(matrix_object) != EXPECTED_ROWS:
        fail("matrix rows must exactly match the ordered D01–D12 physical QA contract")
    for row_id, row in matrix_object.items():
        row_object = require_object(row, f"matrix.{row_id}")
        if set(row_object) != {"result", "evidence", "notes"}:
            fail(f"matrix.{row_id} must contain exactly result/evidence/notes")
        if not isinstance(row_object["evidence"], list):
            fail(f"matrix.{row_id}.evidence must be a list")
        if not isinstance(row_object["notes"], str):
            fail(f"matrix.{row_id}.notes must be a string")
    return matrix_object


def validate_template(record: dict[str, Any]) -> str:
    matrix = validate_matrix_shape(record.get("matrix"))
    apk = require_object(record.get("apk"), "apk")
    if apk.get("package_id") != PACKAGE_ID:
        fail(f"template apk.package_id must remain {PACKAGE_ID}")
    if apk.get("install_command") != "adb install -r <exact-apk-path>":
        fail("template install command must remain an explicit non-evidence placeholder")
    if record.get("release_classification") != NOT_TESTED_CLASSIFICATION:
        fail("template must remain classified as not physical-device-tested")
    for row_id, row in matrix.items():
        if row["result"] != "NOT_RUN" or row["evidence"]:
            fail(f"template row {row_id} must remain NOT_RUN without evidence")
    return "template"


def validate_identity(record: dict[str, Any]) -> None:
    for field in ("tester", "timezone", "tested_at", "reviewed_by", "reviewed_at"):
        require_string(record.get(field), field)
    source_commit = require_string(record.get("source_commit"), "source_commit")
    if not COMMIT_PATTERN.fullmatch(source_commit):
        fail("source_commit must be a 7–64 character lowercase Git SHA")

    apk = require_object(record.get("apk"), "apk")
    for field in ("path_or_release_url", "version_code", "version_name", "install_output_path"):
        require_reference(apk.get(field), f"apk.{field}")
    if apk.get("package_id") != PACKAGE_ID:
        fail(f"apk.package_id must remain {PACKAGE_ID}")
    sha256 = require_string(apk.get("sha256"), "apk.sha256")
    if not SHA256_PATTERN.fullmatch(sha256):
        fail("apk.sha256 must be a lowercase SHA-256 digest")
    install_command = require_string(apk.get("install_command"), "apk.install_command")
    if not install_command.startswith("adb install -r ") or "<" in install_command:
        fail("apk.install_command must record the exact non-placeholder adb install -r command")

    device = require_object(record.get("device"), "device")
    for field in (
        "manufacturer",
        "model",
        "codename",
        "android_version",
        "build_fingerprint",
        "display_resolution",
        "refresh_rate_hz",
    ):
        require_string(device.get(field), f"device.{field}")
    hardware = device.get("input_hardware")
    if not isinstance(hardware, list) or not hardware:
        fail("device.input_hardware must record at least the tested touchscreen/input hardware")
    for index, item in enumerate(hardware):
        require_string(item, f"device.input_hardware[{index}]")
    require_reference(record.get("logcat_path"), "logcat_path")


def validate_completed_record(record: dict[str, Any]) -> str:
    validate_identity(record)
    matrix = validate_matrix_shape(record.get("matrix"))
    all_pass = True
    for row_id, row in matrix.items():
        if row["result"] not in COMPLETE_RESULTS:
            fail(f"matrix.{row_id}.result must be PASS, FAIL, or BLOCKED")
        if not row["evidence"]:
            fail(f"matrix.{row_id} must include at least one concrete evidence reference")
        for index, evidence in enumerate(row["evidence"]):
            require_reference(evidence, f"matrix.{row_id}.evidence[{index}]")
        require_string(row["notes"], f"matrix.{row_id}.notes")
        all_pass = all_pass and row["result"] == "PASS"
    expected_classification = TESTED_CLASSIFICATION if all_pass else NOT_TESTED_CLASSIFICATION
    if record.get("release_classification") != expected_classification:
        fail(f"release_classification must be {expected_classification} for the recorded matrix results")
    return "physical_device_evidence"


def validate_record(path: Path = TEMPLATE_PATH) -> str:
    """Validate a template or completed physical QA record and return its status."""
    record = load_record(path)
    if record.get("schema_version") != SCHEMA_VERSION:
        fail(f"schema_version must be {SCHEMA_VERSION}")
    status = record.get("status")
    if status == TEMPLATE_STATUS:
        return validate_template(record)
    if status == EVIDENCE_STATUS:
        return validate_completed_record(record)
    fail(f"unsupported physical QA status {status!r}")


def main() -> None:
    path = Path(sys.argv[1]) if len(sys.argv) == 2 else TEMPLATE_PATH
    if len(sys.argv) > 2:
        print("PHYSICAL_QA_EVIDENCE_ERROR: usage: validate_physical_qa_evidence.py [record.json]", file=sys.stderr)
        raise SystemExit(2)
    try:
        status = validate_record(path)
    except PhysicalQaValidationError as exc:
        print(f"PHYSICAL_QA_EVIDENCE_ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
    print(f"PHYSICAL_QA_EVIDENCE_PASS status={status} rows={len(EXPECTED_ROWS)}")


if __name__ == "__main__":
    main()
