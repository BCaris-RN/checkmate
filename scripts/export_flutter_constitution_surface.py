#!/usr/bin/env python3
"""Validate the Flutter constitutional export surface for Phoenix ingestion."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MANIFEST = Path("templates/runtime/flutter/caris_flutter_export_manifest.json")
REQUIRED_EXCLUDED_DOCS = {
    ".caris_stack/architecture/002b_NEXTJS_REACT_ARCH_DOCS.md",
    ".caris_stack/architecture/002c_UNIVERSAL_ARCH_BLUEPRINT.md",
    ".caris_stack/architecture/004b_REACT_WHITE_LIST_CORE_STACK.md",
}
REQUIRED_SCHEMA_EXPORTS = {
    "schemas/evidence_bundle.schema.json",
    "schemas/governance_job_manifest.schema.json",
    "schemas/governance_job_registry.schema.json",
    "schemas/permissioned_action_decision.schema.json",
    "schemas/permissioned_action_request.schema.json",
    "schemas/policy_snapshot.schema.json",
}


def normalize_relative_path(raw_path: str) -> str:
    candidate = raw_path.replace("\\", "/").strip()
    if not candidate:
        raise ValueError("path must not be empty")

    parts = [part for part in candidate.split("/") if part not in {"", "."}]
    if not parts:
        raise ValueError("path must not be empty")
    if any(part == ".." for part in parts):
        raise ValueError("parent traversal is not allowed")
    if Path(candidate).is_absolute():
        raise ValueError("absolute paths are not allowed")

    return "/".join(parts)


def load_manifest(manifest_path: Path) -> dict[str, Any]:
    return json.loads(manifest_path.read_text(encoding="utf-8"))


def validate_manifest(manifest: dict[str, Any], repo_root: Path) -> list[str]:
    errors: list[str] = []

    if manifest.get("manifestVersion") != 1:
        errors.append("manifestVersion must be `1`.")

    if manifest.get("targetRuntime") != "phoenix":
        errors.append("targetRuntime must be `phoenix`.")

    if manifest.get("activeProfile") != "flutter":
        errors.append("activeProfile must be `flutter`.")

    required_schemas = manifest.get("requiredSchemas")
    if not isinstance(required_schemas, list) or not required_schemas:
        errors.append("requiredSchemas must be a non-empty list.")
        required_schemas = []

    exported_files = manifest.get("exportedFiles")
    if not isinstance(exported_files, list) or not exported_files:
        errors.append("exportedFiles must be a non-empty list.")
        exported_files = []

    excluded_docs = manifest.get("excludedProfileDocs")
    if not isinstance(excluded_docs, list) or not excluded_docs:
        errors.append("excludedProfileDocs must be a non-empty list.")
        excluded_docs = []

    notes = manifest.get("notes")
    if not isinstance(notes, list) or not notes or not all(isinstance(note, str) and note.strip() for note in notes):
        errors.append("notes must be a non-empty list of non-empty strings.")

    normalized_required_schemas = _validate_path_collection(
        required_schemas,
        field_name="requiredSchemas",
        repo_root=repo_root,
        errors=errors,
    )
    normalized_exports = _validate_path_collection(
        exported_files,
        field_name="exportedFiles",
        repo_root=repo_root,
        errors=errors,
    )
    normalized_excluded = _validate_path_collection(
        excluded_docs,
        field_name="excludedProfileDocs",
        repo_root=repo_root,
        errors=errors,
    )

    missing_required_schema_exports = REQUIRED_SCHEMA_EXPORTS - set(normalized_required_schemas)
    if missing_required_schema_exports:
        errors.append(
            "requiredSchemas must include the downstream Caris schema set: "
            + ", ".join(sorted(missing_required_schema_exports))
        )

    undeclared_exported_required_schemas = set(normalized_required_schemas) - set(normalized_exports)
    if undeclared_exported_required_schemas:
        errors.append(
            "requiredSchemas must also appear in exportedFiles: "
            + ", ".join(sorted(undeclared_exported_required_schemas))
        )

    missing_required_excluded = REQUIRED_EXCLUDED_DOCS - set(normalized_excluded)
    if missing_required_excluded:
        errors.append(
            "excludedProfileDocs must include the non-Flutter profile doctrine set: "
            + ", ".join(sorted(missing_required_excluded))
        )

    excluded_intersection = set(normalized_exports) & set(normalized_excluded)
    if excluded_intersection:
        errors.append(
            "excludedProfileDocs may not appear in exportedFiles: "
            + ", ".join(sorted(excluded_intersection))
        )

    return errors


def _validate_path_collection(
    raw_items: list[Any],
    *,
    field_name: str,
    repo_root: Path,
    errors: list[str],
) -> list[str]:
    normalized_paths: list[str] = []
    seen: set[str] = set()

    for index, raw_item in enumerate(raw_items):
        if not isinstance(raw_item, str):
            errors.append(f"{field_name}[{index}] must be a string.")
            continue

        try:
            normalized = normalize_relative_path(raw_item)
        except ValueError as exc:
            errors.append(f"{field_name}[{index}] is invalid: {exc}.")
            continue

        if normalized in seen:
            errors.append(f"{field_name}[{index}] duplicates `{normalized}`.")
            continue
        seen.add(normalized)

        target = repo_root / Path(normalized)
        if not target.is_file():
            errors.append(f"{field_name}[{index}] references a missing file: `{normalized}`.")
            continue

        normalized_paths.append(normalized)

    return normalized_paths


def render_summary(manifest: dict[str, Any]) -> str:
    exported_files = manifest.get("exportedFiles", [])
    required_schemas = manifest.get("requiredSchemas", [])
    excluded_docs = manifest.get("excludedProfileDocs", [])
    return "\n".join(
        [
            "[OK] Flutter constitutional export surface is valid.",
            f"- Target runtime: {manifest.get('targetRuntime')}",
            f"- Active profile: {manifest.get('activeProfile')}",
            f"- Exported files: {len(exported_files)}",
            f"- Required schemas: {len(required_schemas)}",
            f"- Excluded profile docs: {len(excluded_docs)}",
        ]
    )


def build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Validate the Flutter constitutional export manifest for Phoenix ingestion."
    )
    parser.add_argument(
        "manifest",
        nargs="?",
        default=str(DEFAULT_MANIFEST),
        help="Path to the export manifest. Defaults to templates/runtime/flutter/caris_flutter_export_manifest.json.",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_argument_parser()
    args = parser.parse_args(argv)
    manifest_path = Path(args.manifest)

    try:
        manifest = load_manifest(manifest_path)
    except FileNotFoundError:
        print(f"[ERROR] Manifest not found: {manifest_path}", file=sys.stderr)
        return 2
    except json.JSONDecodeError as exc:
        print(f"[ERROR] Manifest JSON is invalid: {manifest_path} ({exc})", file=sys.stderr)
        return 2

    if not isinstance(manifest, dict):
        print("[ERROR] Manifest root must be a JSON object.", file=sys.stderr)
        return 2

    errors = validate_manifest(manifest, REPO_ROOT)
    if errors:
        print("[INVALID] Flutter constitutional export manifest failed validation.", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(render_summary(manifest))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
