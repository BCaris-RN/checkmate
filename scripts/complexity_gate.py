#!/usr/bin/env python3
"""Caris Stack complexity routing gate.

- Computes max cyclomatic complexity on changed source files using lizard.
- Emits both a complexity route and an audit route.
- Fails CI when max complexity exceeds the high threshold or high-risk paths are touched.
"""

from __future__ import annotations

import argparse
import csv
import io
import json
import os
import re
import subprocess
import sys
from pathlib import Path

try:
    from policy_constants import (
        HIGH_COMPLEXITY_THRESHOLD,
        HIGH_RISK_EXACT_PATHS,
        HIGH_RISK_PREFIXES,
        LOW_COMPLEXITY_THRESHOLD,
    )
except ImportError:  # pragma: no cover - module execution fallback
    from scripts.policy_constants import (
        HIGH_COMPLEXITY_THRESHOLD,
        HIGH_RISK_EXACT_PATHS,
        HIGH_RISK_PREFIXES,
        LOW_COMPLEXITY_THRESHOLD,
    )

SUPPORTED_EXTENSIONS = {
    ".py",
    ".js",
    ".jsx",
    ".ts",
    ".tsx",
    ".dart",
    ".go",
    ".rs",
    ".java",
    ".kt",
    ".swift",
}

DEFAULT_SEMANTIC_RISK_CONFIG = "templates/guardrails/semantic_risk_keywords.json"

DEFAULT_SEMANTIC_RISK_RULES = (
    {
        "id": "payments_billing",
        "pattern": r"\b(payment|billing|invoice|refund|charge|checkout)\b",
    },
    {
        "id": "auth_credentials",
        "pattern": r"\b(auth|oauth|login|password|credential|jwt|bearer|access[_-]?token|refresh[_-]?token|api[_-]?key|secret)\b",
    },
    {
        "id": "encryption_crypto",
        "pattern": r"\b(encrypt(?:ion|ed)?|decrypt(?:ion|ed)?|encryption)\b",
    },
)

SEMANTIC_SCAN_EXTENSIONS = SUPPORTED_EXTENSIONS | {
    ".sql",
    ".prisma",
    ".yml",
    ".yaml",
    ".json",
    ".toml",
    ".env",
}

MAX_SEMANTIC_SCAN_BYTES = 512_000


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run cyclomatic complexity routing gate.")
    parser.add_argument("--file-list", required=True, help="Path to newline-delimited changed files list.")
    parser.add_argument(
        "--low",
        type=int,
        default=LOW_COMPLEXITY_THRESHOLD,
        help=f"Low/medium threshold (default: {LOW_COMPLEXITY_THRESHOLD}).",
    )
    parser.add_argument(
        "--high",
        type=int,
        default=HIGH_COMPLEXITY_THRESHOLD,
        help=f"Medium/high threshold (default: {HIGH_COMPLEXITY_THRESHOLD}).",
    )
    parser.add_argument(
        "--semantic-risk-config",
        default=None,
        help=(
            "Optional JSON file defining semantic risk regex rules. "
            f"Defaults to `{DEFAULT_SEMANTIC_RISK_CONFIG}` when present."
        ),
    )
    return parser.parse_args()


def load_changed_paths(file_list_path: str) -> list[str]:
    lines = Path(file_list_path).read_text(encoding="utf-8").splitlines()
    files: list[str] = []
    for raw in lines:
        path = raw.strip().lstrip("\ufeff")
        if not path:
            continue
        files.append(path)
    return files


def filter_supported_source_files(paths: list[str]) -> list[str]:
    files: list[str] = []
    for path in paths:
        p = Path(path)
        if p.suffix.lower() not in SUPPORTED_EXTENSIONS:
            continue
        if not p.exists() or not p.is_file():
            continue
        files.append(path)
    return files


def normalize_path(path: str) -> str:
    return path.replace("\\", "/").lstrip("./").lower()


def detect_high_risk_changes(paths: list[str]) -> list[str]:
    matches: list[str] = []
    seen: set[str] = set()

    for path in paths:
        norm = normalize_path(path)
        if not norm:
            continue
        basename = Path(norm).name

        high_risk = False
        if norm in HIGH_RISK_EXACT_PATHS or basename in HIGH_RISK_EXACT_PATHS:
            high_risk = True
        elif norm.startswith(HIGH_RISK_PREFIXES):
            high_risk = True
        elif norm.endswith(".sql") or norm.endswith(".prisma"):
            high_risk = True
        elif "/migrations/" in f"/{norm}":
            high_risk = True

        if high_risk and norm not in seen:
            matches.append(path)
            seen.add(norm)

    return matches


def resolve_semantic_risk_config_path(cli_value: str | None) -> Path | None:
    if cli_value:
        path = Path(cli_value)
        return path if path.is_absolute() else (Path.cwd() / path)

    env_path = os.environ.get("CARIS_SEMANTIC_RISK_CONFIG")
    if env_path:
        path = Path(env_path)
        return path if path.is_absolute() else (Path.cwd() / path)

    default_path = Path.cwd() / DEFAULT_SEMANTIC_RISK_CONFIG
    if default_path.exists():
        return default_path
    return None


def load_semantic_risk_rules(config_path: str | None) -> list[tuple[str, re.Pattern[str]]]:
    path = resolve_semantic_risk_config_path(config_path)
    raw_rules: list[dict[str, str]]

    if path is None:
        raw_rules = [dict(rule) for rule in DEFAULT_SEMANTIC_RISK_RULES]
    else:
        if not path.exists():
            print(f"[ERROR] Semantic risk config not found: {path}")
            raise SystemExit(2)
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            print(f"[ERROR] Failed to parse semantic risk config ({path}): {exc}")
            raise SystemExit(2)

        section = payload.get("semanticRiskRules", payload)
        if not isinstance(section, list):
            print(f"[ERROR] semantic risk config must contain a list at `semanticRiskRules`: {path}")
            raise SystemExit(2)

        raw_rules = []
        for item in section:
            if not isinstance(item, dict):
                continue
            rule_id = str(item.get("id", "")).strip()
            pattern = str(item.get("pattern", "")).strip()
            if not rule_id or not pattern:
                continue
            raw_rules.append({"id": rule_id, "pattern": pattern})

        if not raw_rules:
            print(f"[ERROR] semantic risk config contains no valid rules: {path}")
            raise SystemExit(2)

    compiled: list[tuple[str, re.Pattern[str]]] = []
    for rule in raw_rules:
        rule_id = rule["id"]
        pattern = rule["pattern"]
        try:
            compiled.append((rule_id, re.compile(pattern, re.IGNORECASE)))
        except re.error as exc:
            print(f"[ERROR] Invalid semantic risk regex in rule `{rule_id}`: {exc}")
            raise SystemExit(2)

    return compiled


def should_semantic_scan(path: str) -> bool:
    p = Path(path)
    suffix = p.suffix.lower()
    if suffix in SEMANTIC_SCAN_EXTENSIONS:
        return True
    name = p.name.lower()
    if name in {".env", ".env.local", ".env.production"}:
        return True
    return False


def read_text_for_semantic_scan(path: str) -> str | None:
    file_path = Path(path)
    try:
        if not file_path.exists() or not file_path.is_file():
            return None
        if file_path.stat().st_size > MAX_SEMANTIC_SCAN_BYTES:
            return None
        return file_path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return None


def detect_semantic_risk_changes(
    paths: list[str], semantic_rules: list[tuple[str, re.Pattern[str]]]
) -> dict[str, list[str]]:
    hits: dict[str, list[str]] = {}

    for path in paths:
        if not should_semantic_scan(path):
            continue

        text = read_text_for_semantic_scan(path)
        if not text:
            continue

        matched_rule_ids = [rule_id for rule_id, pattern in semantic_rules if pattern.search(text)]
        if matched_rule_ids:
            hits[path] = sorted(set(matched_rule_ids))

    return hits


def run_lizard(files: list[str]) -> tuple[int, str, str]:
    cmd = ["lizard", "--csv", *files]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True)
        return proc.returncode, proc.stdout, proc.stderr
    except FileNotFoundError:
        return 127, "", "lizard executable not found. Install with: python -m pip install lizard"


def parse_max_complexity(csv_output: str) -> tuple[int, str]:
    max_ccn = 0
    worst = "n/a"

    reader = list(csv.reader(io.StringIO(csv_output)))
    if not reader:
        return max_ccn, worst

    header_map: dict[str, int] | None = None
    start_index = 0
    first_row = [cell.strip().lower() for cell in reader[0]]
    if first_row and not first_row[0].replace(".", "", 1).isdigit():
        header_map = {cell.strip().lower(): index for index, cell in enumerate(reader[0])}
        start_index = 1

    for row in reader[start_index:]:
        if not row:
            continue

        if header_map is not None:
            def cell(*names: str, default: str = "") -> str:
                for name in names:
                    index = header_map.get(name)
                    if index is not None and index < len(row):
                        value = row[index].strip()
                        if value:
                            return value
                return default

            ccn_raw = cell("ccn", "cyclomatic_complexity", default="0")
            function = cell("function", "name", "longname", "signature", default="<unknown>")
            file_name = cell("file", "filename", default="<unknown>")
        else:
            if len(row) < 9:
                continue
            ccn_raw = row[1].strip() if len(row) > 1 else "0"
            file_name = row[6].strip() if len(row) > 6 else "<unknown>"
            function = row[8].strip() if len(row) > 8 and row[8].strip() else (
                row[7].strip() if len(row) > 7 else "<unknown>"
            )

        try:
            ccn = int(float(ccn_raw))
        except ValueError:
            ccn = 0

        if ccn > max_ccn:
            max_ccn = ccn
            worst = f"{file_name}:{function}"

    return max_ccn, worst


def main() -> int:
    args = parse_args()
    changed_paths = load_changed_paths(args.file_list)
    files = filter_supported_source_files(changed_paths)
    high_risk_paths = detect_high_risk_changes(changed_paths)
    semantic_rules = load_semantic_risk_rules(args.semantic_risk_config)
    semantic_risk_hits = detect_semantic_risk_changes(changed_paths, semantic_rules)
    has_high_risk_override = bool(high_risk_paths) or bool(semantic_risk_hits)

    if high_risk_paths:
        print("[AUDIT ROUTE] Stop-and-Think (high-risk override).")
        print("[AUDIT] High-risk paths detected:")
        for path in high_risk_paths:
            print(f"  - {path}")

    if semantic_risk_hits:
        print("[AUDIT ROUTE] Stop-and-Think (semantic risk override).")
        print("[AUDIT] Semantic risk triggers detected:")
        for path, keywords in sorted(semantic_risk_hits.items()):
            joined = ", ".join(keywords)
            print(f"  - {path} [keywords: {joined}]")

    if not files:
        print("[INFO] No supported source files changed. Complexity score = 0 (Fast Model route).")
        if has_high_risk_override:
            print("[ERROR] Manual Stop-and-Think audit required for high-risk or semantic-risk changes.")
            return 1
        print("[AUDIT ROUTE] Self-Certify (low complexity, no high-risk paths).")
        return 0

    code, stdout, stderr = run_lizard(files)
    if code != 0 and not stdout.strip():
        print("[ERROR] lizard failed to analyze files.")
        if stderr.strip():
            print(stderr.strip())
        return 2

    max_ccn, worst = parse_max_complexity(stdout)
    print(f"[INFO] Max cyclomatic complexity = {max_ccn}")
    print(f"[INFO] Worst function = {worst}")

    if max_ccn < args.low:
        print("[ROUTE] Fast Model (syntax/format checks).")
        if has_high_risk_override:
            print("[ERROR] High-risk/semantic-risk override requires manual Stop-and-Think audit.")
            return 1
        print("[AUDIT ROUTE] Self-Certify (low complexity, no high-risk paths).")
        return 0

    if max_ccn <= args.high:
        print("[ROUTE] Standard Model (logic verification).")
        if has_high_risk_override:
            print("[ERROR] High-risk/semantic-risk override requires manual Stop-and-Think audit.")
            return 1
        print("[AUDIT ROUTE] Standard Audit (no high-risk override).")
        return 0

    print("[ERROR] Score > high threshold. Senior Architect + reasoning audit required.")
    print("[AUDIT ROUTE] Stop-and-Think (high complexity).")
    return 1


if __name__ == "__main__":
    sys.exit(main())
