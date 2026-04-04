#!/usr/bin/env python3
"""Build lean release zips for the Caris Stack toolkit."""

from __future__ import annotations

import argparse
import zipfile
from pathlib import Path

try:
    from policy_constants import STACK_VERSION_TAG
except ImportError:  # pragma: no cover - module execution fallback
    from scripts.policy_constants import STACK_VERSION_TAG


REQUIRED_ROOT_FILES = (
    "README.md",
    "pubspec.yaml",
    "pubspec.lock",
    "analysis_options.yaml",
    ".gitignore",
    ".github/workflows/github-delivery.yml",
)

CORE_DIRS = (
    ".caris_stack/architecture",
    "scripts",
    "templates/guardrails",
    "backend/modules",
    "backend/tests",
)

OPTIONAL_GITHUB_WORKFLOW = ".github/workflows/caris-hard-gates.yml"

OPTIONAL_LEGAL_FILES = frozenset(
    {
        ".caris_stack/architecture/006_LEGAL_DOCUMENTATION_BUILDER.md",
        ".caris_stack/architecture/007_REVISIONS_AUTOMATION.md",
        "scripts/build_006.py",
    }
)

ALWAYS_EXCLUDED_FILE_NAMES = frozenset(
    {
        "README (1).md",
        "SEMANTIC_BUNDLE_TCS0.txt",
        "recommend.txt",
        "update.txt",
    }
)

SKIP_DIR_NAMES = frozenset(
    {
        ".git",
        ".pytest_cache",
        "__pycache__",
        "extras",
        "legal",
    }
)

SKIP_SUFFIXES = frozenset({".pyc"})
TRAINING_ROOT = "START HERE"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build Caris Stack release zip artifacts.")
    parser.add_argument("--root", default=".", help="Repository root to package. Defaults to the current directory.")
    parser.add_argument("--output-dir", default="dist", help="Directory where zip files are written. Defaults to `dist`.")
    parser.add_argument(
        "--include-github-workflow",
        action="store_true",
        help="Include the optional GitHub Actions starter workflow in the core zip.",
    )
    parser.add_argument(
        "--include-legal-docs",
        action="store_true",
        help="Include the optional 006/007 legal provenance docs and `scripts/build_006.py` in the core zip.",
    )
    parser.add_argument(
        "--include-training-zip",
        action="store_true",
        help="Create a separate training/media zip from `START HERE/`.",
    )
    parser.add_argument("--dry-run", action="store_true", help="Print the selected files without writing zip files.")
    return parser.parse_args()


def normalize_relative(root: Path, path: Path) -> str:
    return path.resolve().relative_to(root.resolve()).as_posix()


def should_skip_relative(relative_path: str) -> bool:
    path = Path(relative_path)
    if any(part in SKIP_DIR_NAMES for part in path.parts):
        return True
    if path.suffix.lower() in SKIP_SUFFIXES:
        return True
    if path.name in ALWAYS_EXCLUDED_FILE_NAMES:
        return True
    return False


def iter_tree_files(root: Path, relative_dir: str) -> list[str]:
    base = root / relative_dir
    if not base.exists():
        return []

    files: list[str] = []
    for path in sorted(base.rglob("*")):
        if not path.is_file():
            continue
        files.append(normalize_relative(root, path))
    return files


def collect_core_release_files(
    root: Path,
    *,
    include_github_workflow: bool = False,
    include_legal_docs: bool = False,
) -> list[str]:
    selected: set[str] = set()
    missing: list[str] = []

    for relative_path in REQUIRED_ROOT_FILES:
        file_path = root / relative_path
        if not file_path.is_file():
            missing.append(relative_path)
            continue
        selected.add(relative_path)

    for relative_dir in CORE_DIRS:
        for relative_path in iter_tree_files(root, relative_dir):
            if should_skip_relative(relative_path):
                continue
            if relative_path in OPTIONAL_LEGAL_FILES and not include_legal_docs:
                continue
            selected.add(relative_path)

    if include_github_workflow:
        workflow_path = root / OPTIONAL_GITHUB_WORKFLOW
        if workflow_path.is_file():
            selected.add(OPTIONAL_GITHUB_WORKFLOW)

    if missing:
        joined = ", ".join(sorted(missing))
        raise FileNotFoundError(f"Missing required release file(s): {joined}")

    return sorted(selected)


def collect_training_release_files(root: Path) -> list[str]:
    selected: set[str] = set()
    for relative_path in iter_tree_files(root, TRAINING_ROOT):
        if should_skip_relative(relative_path):
            continue
        selected.add(relative_path)
    return sorted(selected)


def write_release_zip(root: Path, relative_paths: list[str], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for relative_path in relative_paths:
            archive.write(root / relative_path, arcname=relative_path)


def version_slug() -> str:
    slug_chars = [char.lower() if char.isalnum() else "_" for char in STACK_VERSION_TAG]
    return "".join(slug_chars).strip("_")


def output_dir_for(root: Path, output_dir: str) -> Path:
    path = Path(output_dir)
    if path.is_absolute():
        return path
    return root / path


def print_file_list(title: str, relative_paths: list[str]) -> None:
    print(title)
    for relative_path in relative_paths:
        print(f"  - {relative_path}")
    print(f"[COUNT] {len(relative_paths)} file(s)")


def main() -> int:
    args = parse_args()
    root = Path(args.root).resolve()
    output_dir = output_dir_for(root, args.output_dir)
    prefix = version_slug()

    core_files = collect_core_release_files(
        root,
        include_github_workflow=args.include_github_workflow,
        include_legal_docs=args.include_legal_docs,
    )

    if args.dry_run:
        print_file_list("[CORE RELEASE CONTENTS]", core_files)
    else:
        core_zip = output_dir / f"{prefix}_core_release.zip"
        write_release_zip(root, core_files, core_zip)
        print(f"[SUCCESS] Core release zip written: {core_zip}")
        print(f"[COUNT] {len(core_files)} file(s)")

    if args.include_training_zip:
        training_files = collect_training_release_files(root)
        if args.dry_run:
            print_file_list("[TRAINING / MEDIA CONTENTS]", training_files)
        else:
            training_zip = output_dir / f"{prefix}_training_media.zip"
            write_release_zip(root, training_files, training_zip)
            print(f"[SUCCESS] Training/media zip written: {training_zip}")
            print(f"[COUNT] {len(training_files)} file(s)")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
