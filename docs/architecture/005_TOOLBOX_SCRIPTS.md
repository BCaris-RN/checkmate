# 005 Toolbox Scripts

## I. Purpose

This document maps the constitutional automation surfaces owned by Caris. It defines which scripts and schemas are authoritative, what they govern, and how downstream runtimes must consume them.

This is a doctrine index, not an implementation dump. Live script behavior remains the executable source of truth, and this document must not claim stronger enforcement than the current executable surfaces actually implement.

## II. Constitutional Script Surfaces

### Routing and hard-gate authority

- `scripts/complexity_gate.py`
  - Computes audit routing using live thresholds and high-risk overrides.
- `scripts/dependency_gate.py`
  - Enforces whitelist authority.
- `scripts/design_token_guard.py`
  - Enforces token-first UI policy from lockfile-backed constraints.
- `scripts/enforce_exclusion_zones.ps1`
- `scripts/enforce_exclusion_zones.sh`
  - Enforce deprecated-zone and spike-zone boundaries.

### Semantic and packaging support

- `scripts/generate_semantic_bundle.py`
  - Produces condensed review context; it does not replace audit routing.
- `scripts/package_release.py`
  - Packages the constitutional toolkit release.

### Legal and forensic support

- `scripts/build_006.py`
  - Generates legal build records and revision anchors.
  - Its generated outputs remain subordinate to executable truth and current policy constants.

### Constitutional export support

- `scripts/export_flutter_constitution_surface.py`
  - Validates the Flutter-only export manifest for downstream Phoenix ingestion.
  - Fails closed on missing paths or profile-scope conflicts.

### Schema validation support

- `scripts/validate_schema.py`
  - Validates JSON payloads against the Caris-owned schema subset using the Python standard library.
  - The utility implements targeted validation for the exact Caris contract vocabulary; it is not a full generic JSON Schema engine.
  - It validates contract shape only. It does not authorize actions by itself.

## III. Constitutional Schema Surfaces

Caris owns the machine-readable contracts under `schemas/`.

Required schemas:

- `schemas/governance_job_manifest.schema.json`
  - Contract for a single governance job definition with `id`, `runtime`, `activeProfile`, dependency requirements, outputs, gate expectations, and parser/archive flags
- `schemas/governance_job_registry.schema.json`
  - Contract for a curated Caris-owned registry of governance job descriptors that reference job manifests and remain marketplace-closed
- `schemas/evidence_bundle.schema.json`
  - Contract for machine-readable audit, provenance, and release evidence keyed by route, runtime, and active profile
- `schemas/policy_snapshot.schema.json`
  - Contract for policy state derived from executable constants and validated export surfaces
- `schemas/permissioned_action_request.schema.json`
  - Contract for typed side-effect requests across write, apply, execute, release, and publish
- `schemas/permissioned_action_decision.schema.json`
  - Contract for typed approval or rejection decisions in the permissioned action gateway

Mandatory downstream rule:

- Phoenix or any other governed runtime must validate its governance payloads against these Caris-owned schemas before accepting them as executable inputs.

## IV. Contract Model Rules

The contract model is mandatory doctrine, not runtime implementation detail.

Required constitutional interfaces:

- Governance job manifest
- Governance job registry
- Permissioned action gateway
- Evidence bundle
- Policy snapshot

Interpretation rules:

- A schema defines required shape, naming, and machine-readable accountability.
- A runtime may choose its own UI or orchestration flow.
- A runtime may not use a local contract that weakens or contradicts a Caris schema.
- A contract payload may never override the active profile, whitelist authority, audit route, or hard gates.
- The four behavioral pillars remain operator protocol layered beneath those authorities, not replacements for them.

## V. Validation Utility Usage

Run from the Caris repo root:

```bash
python scripts/validate_schema.py schemas/governance_job_manifest.schema.json path/to/job.json
python scripts/validate_schema.py schemas/evidence_bundle.schema.json path/to/evidence_a.json path/to/evidence_b.json
```

Validation rules:

- Exit code `0`: all payloads valid
- Exit code `1`: one or more payloads invalid
- Exit code `2`: schema or input loading error

## VI. Alignment With Executable Truth

The following alignment rules are mandatory:

- Policy snapshot fields must be sourced from executable policy constants rather than hand-authored prose.
- Legal and revision artifacts may reference machine-readable policy or evidence contracts, but they do not outrank `scripts/build_006.py` or `scripts/policy_constants.py`.
- A doctrine file may describe a broader constitutional surface than current automated enforcement, but executable hard-gate and routing scope still comes only from the live scripts.
- Tooling docs must not embed stale revision dates, stale thresholds, or frozen version examples as if they were live authority.

## VII. Practical Adoption Order

1. Select the active profile.
2. Apply whitelist authority.
3. Determine the audit route.
4. Enforce hard gates.
5. Validate contract payloads against Caris schemas.
6. Execute side effects only through permissioned action flow.
7. Apply the four behavioral execution pillars inside that authority stack, never instead of it.
