#!/usr/bin/env python3
"""Read-only audit for the bounded legacy GitHub Actions artifact cleanup.

The cleanup workflow itself is the only component allowed to delete artifacts.
This tool never calls a delete endpoint: it reads the Actions artifact inventory,
filters the exact audited artifact name and cutoff rule, and can independently
assert that no active pre-cutoff candidates remain after a manual cleanup run.

It is an infrastructure audit aid, not Android launch, physical-device, APK, or
release evidence.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

AUDITED_ARTIFACT_NAME = "operation-redline-android-debug"


class ArtifactAuditError(ValueError):
    """The artifact inventory or requested audit assertion is invalid."""


@dataclass(frozen=True)
class Artifact:
    artifact_id: int
    name: str
    expired: bool
    created_at: datetime
    size_in_bytes: int


def fail(message: str) -> None:
    raise ArtifactAuditError(message)


def parse_iso8601(value: object, field: str) -> datetime:
    if not isinstance(value, str) or not value:
        fail(f"{field} must be a non-empty ISO-8601 timestamp")
    try:
        timestamp = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        fail(f"{field} is not a valid ISO-8601 timestamp: {value!r}")
        raise AssertionError("unreachable") from exc
    if timestamp.tzinfo is None:
        fail(f"{field} must include a timezone: {value!r}")
    return timestamp.astimezone(timezone.utc)


def parse_nonnegative_int(value: object, field: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        fail(f"{field} must be a non-negative integer")
    return value


def parse_artifact(raw: object) -> Artifact:
    if not isinstance(raw, dict):
        fail("artifact entry must be an object")
    artifact_id = parse_nonnegative_int(raw.get("id"), "artifact.id")
    name = raw.get("name")
    if not isinstance(name, str) or not name:
        fail("artifact.name must be a non-empty string")
    expired = raw.get("expired")
    if not isinstance(expired, bool):
        fail("artifact.expired must be a boolean")
    return Artifact(
        artifact_id=artifact_id,
        name=name,
        expired=expired,
        created_at=parse_iso8601(raw.get("created_at"), "artifact.created_at"),
        size_in_bytes=parse_nonnegative_int(raw.get("size_in_bytes"), "artifact.size_in_bytes"),
    )


def inventory_from_payload(payload: object) -> list[Artifact]:
    """Accept a saved API response, page list, or normalized live inventory."""
    pages: list[object]
    if isinstance(payload, dict):
        pages = [payload]
    elif isinstance(payload, list):
        pages = payload
    else:
        fail("artifact API payload must be an object or an array of page objects")

    artifacts: list[Artifact] = []
    for page_index, page in enumerate(pages, start=1):
        if not isinstance(page, dict):
            fail(f"artifact API page {page_index} must be an object")
        entries = page.get("artifacts")
        if not isinstance(entries, list):
            fail(f"artifact API page {page_index} is missing an artifacts array")
        artifacts.extend(parse_artifact(entry) for entry in entries)
    return artifacts


def collect_live_payload(repo: str) -> object:
    owner, separator, repository = repo.partition("/")
    if not separator or not owner or not repository or "/" in repository:
        fail("--repo must use the owner/repository form")
    # Older GitHub CLI versions do not support `--slurp`. Applying jq to every
    # paginated page yields one compact JSON artifact object per line instead,
    # which is both backwards-compatible and avoids a one-page inventory limit.
    command = [
        "gh",
        "api",
        "--paginate",
        "--jq",
        ".artifacts[]",
        f"repos/{repo}/actions/artifacts?per_page=100",
    ]
    try:
        completed = subprocess.run(command, check=True, text=True, capture_output=True)
    except FileNotFoundError as exc:
        fail("GitHub CLI 'gh' is required for a live artifact audit")
        raise AssertionError("unreachable") from exc
    except subprocess.CalledProcessError as exc:
        detail = exc.stderr.strip() or exc.stdout.strip() or str(exc)
        fail(f"GitHub artifact inventory request failed: {detail}")
        raise AssertionError("unreachable") from exc
    try:
        entries = [json.loads(line) for line in completed.stdout.splitlines() if line.strip()]
    except json.JSONDecodeError as exc:
        fail("GitHub CLI returned invalid JSON for the artifact inventory")
        raise AssertionError("unreachable") from exc
    return {"artifacts": entries}


def summarize(artifacts: list[Artifact], cutoff: datetime) -> tuple[list[Artifact], list[Artifact]]:
    named_active = [
        artifact
        for artifact in artifacts
        if artifact.name == AUDITED_ARTIFACT_NAME and not artifact.expired
    ]
    pre_cutoff = [artifact for artifact in named_active if artifact.created_at < cutoff]
    return named_active, pre_cutoff


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Read-only audit for the bounded operation-redline legacy-artifact cleanup."
    )
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument(
        "--repo",
        help="GitHub repository to read as owner/repository; invokes gh api read-only.",
    )
    source.add_argument(
        "--input",
        type=Path,
        help="Saved JSON response (single API object or page-object array) for offline audit.",
    )
    parser.add_argument(
        "--cutoff",
        required=True,
        help="ISO-8601 cutoff; only active exact-name artifacts older than this time are candidates.",
    )
    parser.add_argument(
        "--verify-cleanup",
        action="store_true",
        help="Fail unless no active exact-name artifact remains before the supplied cutoff.",
    )
    parser.add_argument(
        "--expect-pre-cutoff-count",
        type=int,
        help="Optional exact assertion for the active pre-cutoff candidate count.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> None:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        cutoff = parse_iso8601(args.cutoff, "--cutoff")
        if args.expect_pre_cutoff_count is not None and args.expect_pre_cutoff_count < 0:
            fail("--expect-pre-cutoff-count must be non-negative")
        if args.input is not None:
            try:
                payload = json.loads(args.input.read_text(encoding="utf-8"))
            except OSError as exc:
                fail(f"unable to read --input JSON: {exc}")
                raise AssertionError("unreachable") from exc
            except json.JSONDecodeError as exc:
                fail(f"--input does not contain valid JSON: {exc}")
                raise AssertionError("unreachable") from exc
            source_label = str(args.input)
        else:
            payload = collect_live_payload(args.repo)
            source_label = args.repo
        artifacts = inventory_from_payload(payload)
        named_active, pre_cutoff = summarize(artifacts, cutoff)
        candidate_bytes = sum(artifact.size_in_bytes for artifact in pre_cutoff)
        if args.expect_pre_cutoff_count is not None and len(pre_cutoff) != args.expect_pre_cutoff_count:
            fail(
                "pre-cutoff candidate count mismatch: "
                f"expected {args.expect_pre_cutoff_count}, found {len(pre_cutoff)}"
            )
        print(
            "ARTIFACT_AUDIT "
            f"source={source_label} cutoff={cutoff.isoformat().replace('+00:00', 'Z')} "
            f"active_named={len(named_active)} pre_cutoff={len(pre_cutoff)} "
            f"pre_cutoff_bytes={candidate_bytes}"
        )
        if args.verify_cleanup:
            if pre_cutoff:
                fail(
                    "cleanup verification failed: "
                    f"{len(pre_cutoff)} active {AUDITED_ARTIFACT_NAME} artifact(s) remain before cutoff"
                )
            print(
                "ARTIFACT_CLEANUP_VERIFY_PASS "
                f"cutoff={cutoff.isoformat().replace('+00:00', 'Z')} active_pre_cutoff=0"
            )
    except ArtifactAuditError as exc:
        print(f"ARTIFACT_AUDIT_ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc


if __name__ == "__main__":
    main()
