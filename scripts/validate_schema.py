#!/usr/bin/env python3
"""Validate JSON payloads against targeted Caris contract schemas."""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


SUPPORTED_SCHEMA_KEYS = {
    "$schema",
    "title",
    "description",
    "type",
    "properties",
    "required",
    "items",
    "enum",
    "additionalProperties",
    "minItems",
    "uniqueItems",
    "minLength",
    "pattern",
    "minimum",
}
SUPPORTED_TYPES = {"object", "array", "string", "integer", "number", "boolean", "null"}


@dataclass(frozen=True)
class ValidationError:
    path: str
    message: str

    def __str__(self) -> str:
        return f"{self.path}: {self.message}"


class SchemaContractError(RuntimeError):
    """Raised when a schema uses unsupported or malformed keywords."""


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def validate_payload(payload: Any, schema: dict[str, Any]) -> list[ValidationError]:
    ensure_supported_schema(schema)
    return _validate_instance(payload, schema, path="$")


def validate_json_file(schema_path: Path, payload_path: Path) -> list[ValidationError]:
    schema = load_json(schema_path)
    payload = load_json(payload_path)
    return validate_payload(payload, schema)


def ensure_supported_schema(schema: Any, path: str = "$schema") -> None:
    if not isinstance(schema, dict):
        raise SchemaContractError(f"{path}: schema node must be an object.")

    for key in schema:
        if key not in SUPPORTED_SCHEMA_KEYS:
            raise SchemaContractError(f"{path}: unsupported schema keyword `{key}`.")

    declared_type = schema.get("type")
    if declared_type is not None and declared_type not in SUPPORTED_TYPES:
        raise SchemaContractError(f"{path}: unsupported type `{declared_type}`.")

    required = schema.get("required")
    if required is not None:
        if not isinstance(required, list) or not all(isinstance(item, str) for item in required):
            raise SchemaContractError(f"{path}: `required` must be a list of strings.")

    enum = schema.get("enum")
    if enum is not None and not isinstance(enum, list):
        raise SchemaContractError(f"{path}: `enum` must be a list.")

    additional_properties = schema.get("additionalProperties")
    if additional_properties is not None and not isinstance(additional_properties, bool):
        raise SchemaContractError(f"{path}: `additionalProperties` must be a boolean.")

    min_items = schema.get("minItems")
    if min_items is not None and (not isinstance(min_items, int) or isinstance(min_items, bool) or min_items < 0):
        raise SchemaContractError(f"{path}: `minItems` must be a non-negative integer.")

    min_length = schema.get("minLength")
    if min_length is not None and (not isinstance(min_length, int) or isinstance(min_length, bool) or min_length < 0):
        raise SchemaContractError(f"{path}: `minLength` must be a non-negative integer.")

    minimum = schema.get("minimum")
    if minimum is not None and not isinstance(minimum, (int, float)):
        raise SchemaContractError(f"{path}: `minimum` must be numeric.")

    pattern = schema.get("pattern")
    if pattern is not None:
        if not isinstance(pattern, str):
            raise SchemaContractError(f"{path}: `pattern` must be a string.")
        try:
            re.compile(pattern)
        except re.error as exc:  # pragma: no cover - defensive branch
            raise SchemaContractError(f"{path}: invalid regex `{pattern}` ({exc}).") from exc

    properties = schema.get("properties")
    if properties is not None:
        if not isinstance(properties, dict):
            raise SchemaContractError(f"{path}: `properties` must be an object.")
        for key, subschema in properties.items():
            ensure_supported_schema(subschema, f"{path}.properties.{key}")

    items = schema.get("items")
    if items is not None:
        ensure_supported_schema(items, f"{path}.items")


def _validate_instance(instance: Any, schema: dict[str, Any], path: str) -> list[ValidationError]:
    errors: list[ValidationError] = []

    declared_type = schema.get("type")
    if declared_type is not None and not _matches_type(instance, declared_type):
        errors.append(
            ValidationError(path=path, message=f"expected type `{declared_type}`.")
        )
        return errors

    enum = schema.get("enum")
    if enum is not None and instance not in enum:
        errors.append(
            ValidationError(path=path, message=f"value must be one of {enum}.")
        )

    if declared_type == "object":
        errors.extend(_validate_object(instance, schema, path))
    elif declared_type == "array":
        errors.extend(_validate_array(instance, schema, path))
    elif declared_type == "string":
        errors.extend(_validate_string(instance, schema, path))
    elif declared_type in {"integer", "number"}:
        errors.extend(_validate_number(instance, schema, path))

    return errors


def _validate_object(instance: dict[str, Any], schema: dict[str, Any], path: str) -> list[ValidationError]:
    errors: list[ValidationError] = []
    properties = schema.get("properties", {})
    required = schema.get("required", [])

    for key in required:
        if key not in instance:
            errors.append(
                ValidationError(path=path, message=f"missing required property `{key}`.")
            )

    if schema.get("additionalProperties", True) is False:
        for key in instance:
            if key not in properties:
                errors.append(
                    ValidationError(path=f"{path}.{key}", message="additional properties are not allowed.")
                )

    for key, subschema in properties.items():
        if key not in instance:
            continue
        errors.extend(_validate_instance(instance[key], subschema, f"{path}.{key}"))

    return errors


def _validate_array(instance: list[Any], schema: dict[str, Any], path: str) -> list[ValidationError]:
    errors: list[ValidationError] = []
    min_items = schema.get("minItems")
    if min_items is not None and len(instance) < min_items:
        errors.append(
            ValidationError(path=path, message=f"must contain at least {min_items} item(s).")
        )

    if schema.get("uniqueItems"):
        seen: set[str] = set()
        for index, item in enumerate(instance):
            fingerprint = json.dumps(item, sort_keys=True, separators=(",", ":"))
            if fingerprint in seen:
                errors.append(
                    ValidationError(path=f"{path}[{index}]", message="array items must be unique.")
                )
            seen.add(fingerprint)

    item_schema = schema.get("items")
    if item_schema is not None:
        for index, item in enumerate(instance):
            errors.extend(_validate_instance(item, item_schema, f"{path}[{index}]"))

    return errors


def _validate_string(instance: str, schema: dict[str, Any], path: str) -> list[ValidationError]:
    errors: list[ValidationError] = []
    min_length = schema.get("minLength")
    if min_length is not None and len(instance) < min_length:
        errors.append(
            ValidationError(path=path, message=f"string must be at least {min_length} character(s).")
        )

    pattern = schema.get("pattern")
    if pattern is not None and re.search(pattern, instance) is None:
        errors.append(
            ValidationError(path=path, message=f"string does not match pattern `{pattern}`.")
        )

    return errors


def _validate_number(instance: Any, schema: dict[str, Any], path: str) -> list[ValidationError]:
    errors: list[ValidationError] = []
    minimum = schema.get("minimum")
    if minimum is not None and instance < minimum:
        errors.append(
            ValidationError(path=path, message=f"value must be greater than or equal to {minimum}.")
        )
    return errors


def _matches_type(instance: Any, declared_type: str) -> bool:
    if declared_type == "object":
        return isinstance(instance, dict)
    if declared_type == "array":
        return isinstance(instance, list)
    if declared_type == "string":
        return isinstance(instance, str)
    if declared_type == "integer":
        return isinstance(instance, int) and not isinstance(instance, bool)
    if declared_type == "number":
        return isinstance(instance, (int, float)) and not isinstance(instance, bool)
    if declared_type == "boolean":
        return isinstance(instance, bool)
    if declared_type == "null":
        return instance is None
    return False


def build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Validate JSON payloads against the targeted Caris schema subset. "
            "This is not a full generic JSON Schema engine."
        )
    )
    parser.add_argument("schema", help="Path to a schema JSON file.")
    parser.add_argument("payloads", nargs="+", help="One or more JSON payload files.")
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_argument_parser()
    args = parser.parse_args(argv)

    schema_path = Path(args.schema)
    payload_paths = [Path(path) for path in args.payloads]

    try:
        schema = load_json(schema_path)
        ensure_supported_schema(schema)
    except FileNotFoundError:
        print(f"[ERROR] Schema not found: {schema_path}", file=sys.stderr)
        return 2
    except json.JSONDecodeError as exc:
        print(f"[ERROR] Schema JSON is invalid: {schema_path} ({exc})", file=sys.stderr)
        return 2
    except SchemaContractError as exc:
        print(f"[ERROR] Unsupported schema contract: {exc}", file=sys.stderr)
        return 2

    has_invalid_payload = False

    for payload_path in payload_paths:
        try:
            payload = load_json(payload_path)
        except FileNotFoundError:
            print(f"[ERROR] Payload not found: {payload_path}", file=sys.stderr)
            return 2
        except json.JSONDecodeError as exc:
            print(f"[ERROR] Payload JSON is invalid: {payload_path} ({exc})", file=sys.stderr)
            return 2

        errors = _validate_instance(payload, schema, path="$")
        if errors:
            has_invalid_payload = True
            print(f"[INVALID] {payload_path}", file=sys.stderr)
            for error in errors:
                print(f"  - {error}", file=sys.stderr)
            continue

        print(f"[OK] {payload_path}")

    return 1 if has_invalid_payload else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
