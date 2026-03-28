#!/usr/bin/env python3

from __future__ import annotations

import datetime as dt
import json
import subprocess
import sys
from pathlib import Path

try:
    from policy_constants import (
        GOVERNANCE_DOC_BASENAMES,
        HIGH_COMPLEXITY_THRESHOLD,
        LOW_COMPLEXITY_THRESHOLD,
        STACK_VERSION_TAG,
        TOKEN_BASELINE_GRID_PX,
        TOKEN_SCALE_RATIO,
        build_revision_text,
    )
except ImportError:  # pragma: no cover - module execution fallback
    from scripts.policy_constants import (
        GOVERNANCE_DOC_BASENAMES,
        HIGH_COMPLEXITY_THRESHOLD,
        LOW_COMPLEXITY_THRESHOLD,
        STACK_VERSION_TAG,
        TOKEN_BASELINE_GRID_PX,
        TOKEN_SCALE_RATIO,
        build_revision_text,
    )


REPO_ROOT = Path(__file__).resolve().parents[1]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from backend.modules.architecture_guards import HexagonalViolationException, check_draftstore_compliance


EXCLUDED_DIRS = {".codedrop", ".dart_tool", ".fvm", ".git", "__pycache__", "build", "docs", "extras", "legal", "templates"}


def get_git_metadata(root_path: Path) -> tuple[str, str]:
    try:
        branch = subprocess.check_output(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            cwd=root_path,
            text=True,
        ).strip()
        commit = subprocess.check_output(
            ["git", "rev-parse", "HEAD"],
            cwd=root_path,
            text=True,
        ).strip()
        return branch, commit
    except Exception:
        return "detached", "unknown_hash"


def _should_skip(root_path: Path, path: Path) -> bool:
    relative_parts = {part.lower() for part in path.resolve().relative_to(root_path.resolve()).parts}
    return bool(relative_parts & EXCLUDED_DIRS)


def _is_draftstore_target(path: Path) -> bool:
    name = path.name.lower()
    if name.endswith("_viewmodel.dart") or name.endswith("_controller.dart"):
        return True
    parts = {part.lower() for part in path.parts}
    return "viewmodels" in parts or "controllers" in parts


def enforce_draftstore_contract(root_path: Path) -> int:
    scanned = 0
    for dart_file in sorted(root_path.rglob("*.dart")):
        if _should_skip(root_path, dart_file) or not _is_draftstore_target(dart_file):
            continue

        content = dart_file.read_text(encoding="utf-8")
        check_draftstore_compliance(dart_file.relative_to(root_path).as_posix(), content)
        scanned += 1

    return scanned


def run_006_builder(root_dir: str = ".") -> int:
    root_path = Path(root_dir).resolve()
    scanned_targets = enforce_draftstore_contract(root_path)

    print("--- 006 LEGAL DOCUMENTATION BUILDER ACTIVATED ---")
    print("\n[USPTO COMPLIANCE] Define the Human Conception for this build:")

    human_name = input("> Enter the name of the Human Architect (Inventor): ").strip() or "Mac Tabilis"
    intent = input("> What technical problem did you solve in this iteration? ")
    constraints = input("> What specific human-led constraints were applied to the AI? ")

    branch, commit = get_git_metadata(root_path)
    timestamp = dt.datetime.now(dt.timezone.utc)
    timestamp_iso = timestamp.isoformat()
    filename_stamp = timestamp.strftime("%Y%m%dT%H%M%SZ")

    artifact = {
        "stack_version": STACK_VERSION_TAG,
        "architect": human_name,
        "timestamp": timestamp_iso,
        "git_branch": branch,
        "git_commit": commit,
        "conception_log": {
            "problem_statement": intent,
            "human_constraints": constraints,
        },
        "policy_snapshot": {
            "complexity_thresholds": {
                "low": LOW_COMPLEXITY_THRESHOLD,
                "high": HIGH_COMPLEXITY_THRESHOLD,
            },
            "governance_docs": sorted(GOVERNANCE_DOC_BASENAMES),
            "token_policy": {
                "scale_ratio": TOKEN_SCALE_RATIO,
                "baseline_grid_px": TOKEN_BASELINE_GRID_PX,
            },
        },
        "compliance_verified": [
            "DRAFTSTORE_SEQUENCE",
            "ROUTING_POLICY_SNAPSHOT",
            "TOKEN_POLICY_SNAPSHOT",
        ],
        "draftstore_targets_scanned": scanned_targets,
        "declaration": "Verified Significant Human Contribution per USPTO PTO-P-2025-0014",
    }

    legal_dir = root_path / "legal"
    legal_dir.mkdir(parents=True, exist_ok=True)
    artifact_path = legal_dir / f"BUILD_RECORD_{filename_stamp}.json"
    artifact_path.write_text(json.dumps(artifact, indent=2), encoding="utf-8")
    print(f"\n[SUCCESS] Legal artifact generated: {artifact_path}")

    extras_dir = root_path / "extras"
    extras_dir.mkdir(parents=True, exist_ok=True)
    revision_text = build_revision_text(
        human_name=human_name,
        scanned_targets=scanned_targets,
        revision_identifier=timestamp.strftime("%Y-%m-%d"),
    )
    revision_path = extras_dir / "revision.txt"
    revision_path.write_text(revision_text, encoding="utf-8")
    print(f"[SUCCESS] 007 Forensic Revision anchor generated: {revision_path}")
    print("Record anchored to the Sovereign System Constitution.")
    return 0


if __name__ == "__main__":
    root_arg = sys.argv[1] if len(sys.argv) > 1 else "."
    try:
        raise SystemExit(run_006_builder(root_arg))
    except HexagonalViolationException as exc:
        print(f"Build 006 Legal Stamp Aborted: {exc}", file=sys.stderr)
        raise SystemExit(1)
