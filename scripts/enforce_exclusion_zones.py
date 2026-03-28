#!/usr/bin/env python3
"""Fail-closed exclusion-zone scan used by the shell and PowerShell wrappers."""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

SUPPORTED_EXTENSIONS = {
    ".dart",
    ".go",
    ".java",
    ".js",
    ".jsx",
    ".kt",
    ".py",
    ".rs",
    ".swift",
    ".ts",
    ".tsx",
    ".yaml",
    ".yml",
}

BAN_IGNORE_DIR_NAMES = {
    ".git",
    ".next",
    "__pycache__",
    "build",
    "coverage",
    "dist",
    "experimental",
    "node_modules",
}

STALE_IGNORE_DIR_NAMES = {
    ".git",
    ".next",
    "__pycache__",
    "build",
    "coverage",
    "dist",
    "node_modules",
}

IGNORE_PATH_PREFIXES = (
    ("templates", "guardrails"),
)

EXACT_SKIP_PATHS = {
    ("scripts", "enforce_exclusion_zones.py"),
    ("scripts", "enforce_exclusion_zones.ps1"),
    ("scripts", "enforce_exclusion_zones.sh"),
}

BANNED_PATTERN = re.compile(r"legacy_api_folder|deprecated_utils")
PROTO_PATTERN = re.compile(r"\.proto\.[^\\/\.]+$", re.IGNORECASE)


class ExclusionScanError(RuntimeError):
    """Raised when the scan cannot complete safely."""


@dataclass(frozen=True)
class StaleArtifact:
    path: Path
    age_hours: int
    last_write_time: datetime


def build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Run the Caris Stack exclusion-zone scan."
    )
    parser.add_argument(
        "root_path",
        nargs="?",
        default=None,
        help="Optional positional project root to scan.",
    )
    parser.add_argument(
        "--root",
        dest="root_flag",
        default=None,
        help="Project root to scan.",
    )
    parser.add_argument(
        "--spike-stale-hours",
        type=int,
        default=48,
        help="Age threshold for stale spike artifacts.",
    )
    parser.add_argument(
        "--fail-on-stale-spikes",
        action="store_true",
        help="Exit non-zero when stale spike artifacts are found.",
    )
    return parser


def normalize_relative(path: Path, root: Path) -> Path:
    return path.resolve().relative_to(root.resolve())


def should_skip(path: Path, root: Path, ignore_dir_names: set[str]) -> bool:
    try:
        relative = normalize_relative(path, root)
    except ValueError:
        return True

    parts = relative.parts
    if parts in EXACT_SKIP_PATHS:
        return True
    if any(part in ignore_dir_names for part in parts):
        return True

    for prefix in IGNORE_PATH_PREFIXES:
        if len(parts) >= len(prefix) and parts[: len(prefix)] == prefix:
            return True

    return False


def is_supported_source(path: Path) -> bool:
    return path.is_file() and path.suffix.lower() in SUPPORTED_EXTENSIONS


def iter_supported_files(root: Path) -> list[Path]:
    candidates: list[Path] = []
    for path in root.rglob("*"):
        if not is_supported_source(path):
            continue
        if should_skip(path, root, BAN_IGNORE_DIR_NAMES):
            continue
        candidates.append(path)
    return candidates


def iter_stale_spike_files(root: Path) -> list[Path]:
    candidates: list[Path] = []
    for path in root.rglob("*"):
        if not path.is_file() or should_skip(path, root, STALE_IGNORE_DIR_NAMES):
            continue
        try:
            relative = normalize_relative(path, root)
        except ValueError:
            continue

        if "experimental" in relative.parts or PROTO_PATTERN.search(path.name):
            candidates.append(path)
    return candidates


def read_text_file(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError as error:
        raise ExclusionScanError(
            f"[ERROR] Failed to read UTF-8 text from {path.as_posix()}: {error}"
        ) from error
    except OSError as error:
        raise ExclusionScanError(
            f"[ERROR] Failed to access {path.as_posix()}: {error}"
        ) from error


def scan_for_banned_references(root: Path) -> list[str]:
    matches: list[str] = []
    for path in iter_supported_files(root):
        text = read_text_file(path)
        relative = normalize_relative(path, root).as_posix()
        for line_number, line in enumerate(text.splitlines(), start=1):
            if BANNED_PATTERN.search(line):
                matches.append(f"{relative}:{line_number}:{line}")
    return matches


def scan_for_stale_spikes(root: Path, spike_stale_hours: int) -> list[StaleArtifact]:
    stale: list[StaleArtifact] = []
    now = datetime.now(timezone.utc).timestamp()
    for path in iter_stale_spike_files(root):
        try:
            modified = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc)
        except OSError as error:
            raise ExclusionScanError(
                f"[ERROR] Failed to inspect {path.as_posix()}: {error}"
            ) from error

        age_hours = int((now - modified.timestamp()) // 3600)
        if age_hours >= spike_stale_hours:
            stale.append(
                StaleArtifact(
                    path=path,
                    age_hours=age_hours,
                    last_write_time=modified,
                )
            )
    return stale


def display_path(path: Path, root: Path) -> str:
    return normalize_relative(path, root).as_posix()


def run_scan(root: Path, spike_stale_hours: int, fail_on_stale_spikes: bool) -> int:
    if not root.exists():
        raise ExclusionScanError(f"[ERROR] Root directory '{root}' was not found.")
    if not root.is_dir():
        raise ExclusionScanError(f"[ERROR] Root directory '{root}' is not a directory.")

    matches = scan_for_banned_references(root)
    stale_artifacts = scan_for_stale_spikes(root, spike_stale_hours)

    if matches:
        print("[ERROR] Exclusion zone violation detected.", file=sys.stderr)
        print(
            "[ERROR] Remove deprecated imports/references before commit or merge.",
            file=sys.stderr,
        )
        for match in matches:
            print(match)
        if stale_artifacts:
            print(
                f"[STALE_SPIKE] Spike Protocol staleness detected (older than {spike_stale_hours}h):"
            )
            for artifact in stale_artifacts:
                print(
                    f"[STALE_SPIKE] {display_path(artifact.path, root)} "
                    f"(age: {artifact.age_hours}h, last touch: "
                    f"{artifact.last_write_time.strftime('%Y-%m-%d %H:%M:%S %Z')})"
                )
        return 1

    if stale_artifacts:
        print(
            f"[STALE_SPIKE] Spike Protocol staleness detected (older than {spike_stale_hours}h)."
        )
        print(
            "[STALE_SPIKE] Refactor or delete stale prototypes before they become shadow code."
        )
        print(
            "[STALE_SPIKE] Suggested next step: extract core logic, write failing tests, migrate to production path, then delete spike."
        )
        for artifact in stale_artifacts:
            print(
                f"[STALE_SPIKE] {display_path(artifact.path, root)} "
                f"(age: {artifact.age_hours}h, last touch: "
                f"{artifact.last_write_time.strftime('%Y-%m-%d %H:%M:%S %Z')})"
            )
        if fail_on_stale_spikes:
            print(
                "[STALE_SPIKE] Stale Spike Protocol artifacts found and fail mode is enabled (CARIS_FAIL_ON_STALE_SPIKES=1 or --fail-on-stale-spikes).",
                file=sys.stderr,
            )
            return 1

    print("[OK] No exclusion zone violations detected.")
    if not stale_artifacts:
        print(
            f"[OK] No stale Spike Protocol artifacts older than {spike_stale_hours} hours detected."
        )
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = build_argument_parser()
    args = parser.parse_args(argv)
    root_value = args.root_flag or args.root_path or "."
    root = Path(root_value).resolve()

    try:
        return run_scan(root, args.spike_stale_hours, args.fail_on_stale_spikes)
    except ExclusionScanError as error:
        print(str(error), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
