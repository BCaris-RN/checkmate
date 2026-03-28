#!/usr/bin/env python3
"""Supply-chain dependency whitelist enforcement for Flutter projects."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


DEFAULT_ALLOWLIST = Path("templates/guardrails/dependency_allowlist.json")
TOP_LEVEL_SECTIONS = ("dependencies", "dev_dependencies", "dependency_overrides")
SDK_PACKAGES = {"flutter", "flutter_localizations", "flutter_test"}
COMMENT_PATTERN = re.compile(r"\s+#.*$")
ENTRY_PATTERN = re.compile(r"^([A-Za-z0-9_.-]+):(?:\s*(.+))?$")


class DependencyGateViolation(RuntimeError):
    """Raised when pubspec dependencies are not on the approved whitelist."""


def normalize_name(value: str) -> str:
    return value.strip().lower()


def default_allowlist_path() -> Path:
    return (Path(__file__).resolve().parents[1] / DEFAULT_ALLOWLIST).resolve()


def load_allowlist(path: Path) -> dict[str, set[str]]:
    if not path.exists():
        raise FileNotFoundError(
            f"[DEPENDENCY_VIOLATION] Allowlist not found: {path.as_posix()}"
        )

    raw = json.loads(path.read_text(encoding="utf-8"))
    approved = raw.get("approved_dependencies")
    if not isinstance(approved, dict):
        raise ValueError(
            "[DEPENDENCY_VIOLATION] dependency_allowlist.json is missing `approved_dependencies`."
        )

    normalized: dict[str, set[str]] = {}
    for ecosystem, names in approved.items():
        if not isinstance(names, list):
            raise ValueError(
                f"[DEPENDENCY_VIOLATION] Allowlist entry `{ecosystem}` must be a list."
            )
        normalized[ecosystem] = {
            normalize_name(name)
            for name in names
            if isinstance(name, str) and name.strip()
        }
    return normalized


def _strip_comment(line: str) -> str:
    if "#" not in line:
        return line.rstrip()
    return COMMENT_PATTERN.sub("", line).rstrip()


def parse_pubspec_dependencies(text: str) -> dict[str, dict[str, object]]:
    sections = {section: {} for section in TOP_LEVEL_SECTIONS}
    current_section: str | None = None
    section_indent = 0
    current_package: str | None = None
    package_indent = 0

    for raw_line in text.splitlines():
        line = _strip_comment(raw_line)
        if not line.strip():
            continue

        indent = len(line) - len(line.lstrip(" "))
        stripped = line.strip()

        if stripped in {f"{section}:" for section in TOP_LEVEL_SECTIONS}:
            current_section = stripped[:-1]
            section_indent = indent
            current_package = None
            package_indent = 0
            continue

        if current_section is None:
            continue

        if indent <= section_indent:
            current_section = None
            current_package = None
            package_indent = 0
            continue

        match = ENTRY_PATTERN.match(stripped)
        if not match:
            raise DependencyGateViolation(
                f"[DEPENDENCY_VIOLATION] Failed to parse pubspec.yaml near line: {raw_line.rstrip()}"
            )

        key, value = match.groups()
        if indent == section_indent + 2:
            current_package = key
            package_indent = indent
            sections[current_section][key] = value.strip() if value else {}
            continue

        if current_package is None or indent <= package_indent:
            raise DependencyGateViolation(
                f"[DEPENDENCY_VIOLATION] Failed to parse pubspec.yaml near line: {raw_line.rstrip()}"
            )

        package_spec = sections[current_section][current_package]
        if not isinstance(package_spec, dict):
            raise DependencyGateViolation(
                f"[DEPENDENCY_VIOLATION] Invalid nested dependency block for `{current_package}`."
            )
        package_spec[key] = value.strip() if value else {}

    return sections


def _iter_dependency_entries(parsed: dict[str, dict[str, object]]) -> list[tuple[str, object]]:
    entries: list[tuple[str, object]] = []
    for section in TOP_LEVEL_SECTIONS:
        entries.extend(parsed[section].items())
    return entries


def _validate_dependency(
    name: str,
    spec: object,
    approved_dart_packages: set[str],
) -> str | None:
    normalized_name = normalize_name(name)
    if isinstance(spec, dict):
        if "path" in spec:
            return None
        if "sdk" in spec:
            if normalized_name in SDK_PACKAGES:
                return None
            return f"{name} uses an unapproved SDK source"
        if "git" in spec:
            return f"{name} uses a git source, which is not whitelisted"
        if normalized_name not in approved_dart_packages:
            return f"{name} is not on the approved whitelist"
        return None

    if normalized_name not in approved_dart_packages:
        return f"{name} is not on the approved whitelist"
    return None


def check_dependencies(
    project_root: Path,
    allowlist_path: Path | None = None,
) -> None:
    pubspec_path = project_root / "pubspec.yaml"
    if not pubspec_path.exists():
        return

    resolved_allowlist = (
        allowlist_path.resolve()
        if allowlist_path is not None
        else default_allowlist_path()
    )
    try:
        approved_dart_packages = load_allowlist(resolved_allowlist).get("dart", set())
    except (FileNotFoundError, ValueError, json.JSONDecodeError) as error:
        raise DependencyGateViolation(str(error)) from error

    parsed = parse_pubspec_dependencies(pubspec_path.read_text(encoding="utf-8"))
    issues = []
    for name, spec in _iter_dependency_entries(parsed):
        problem = _validate_dependency(name, spec, approved_dart_packages)
        if problem:
            issues.append(problem)

    if issues:
        joined = "; ".join(issues)
        raise DependencyGateViolation(
            "[DEPENDENCY_VIOLATION] "
            f"Unvetted dependencies found in {pubspec_path.name}: {joined}. "
            "Document approvals in docs/architecture/004_EXTERNAL_LIBS_AND_RESOURCES.md before use."
        )


def build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Run the Caris Stack Flutter dependency gate."
    )
    parser.add_argument(
        "project_root",
        nargs="?",
        default=".",
        help="Project root containing pubspec.yaml",
    )
    parser.add_argument(
        "--allowlist",
        default=None,
        help="Optional path to dependency_allowlist.json.",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_argument_parser()
    args = parser.parse_args(argv)
    project_root = Path(args.project_root).resolve()
    allowlist_path = Path(args.allowlist) if args.allowlist else None

    try:
        check_dependencies(project_root, allowlist_path=allowlist_path)
    except DependencyGateViolation as exc:
        print(str(exc), file=sys.stderr)
        return 1

    print("[OK] Dependency gate passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
