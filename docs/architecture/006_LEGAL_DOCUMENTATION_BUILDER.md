# 006 Legal Documentation Builder: Sovereign System Constitution

## I. Purpose

This document governs legal provenance capture for The Caris Stack. It defines when `scripts/build_006.py` must run, what evidence it records, and where the output is stored.

Interpretation rule:

- `scripts/build_006.py` is a post-enforcement provenance builder.
- It does not replace active-profile selection, whitelist enforcement, audit routing, schema validation, or hard-gate execution.
- It records the governed state after those controls, not instead of them.

## II. Trigger Conditions

Run `scripts/build_006.py` when any of the following is true:

- you are preparing a release candidate that needs a legal provenance artifact
- you are generating inventorship evidence
- you are anchoring a forensic revision record in `extras/revision.txt`
- you need a human-authored conception record tied to a specific Git commit

## III. Required Inputs

The operator must provide:

- Human inventor or architect name
- Problem statement for the current build
- Human-led constraints applied to the AI or implementation process

The script must derive:

- UTC timestamp
- Git branch and commit hash
- Active policy snapshot from `scripts/policy_constants.py`
- DraftStore compliance scan results

## IV. Required Outputs

`scripts/build_006.py` must emit:

- `legal/BUILD_RECORD_<timestamp>.json`
- `extras/revision.txt`

The legal build record must include:

- conception metadata
- chain-of-title Git metadata
- routing-policy snapshot
- token-policy snapshot
- DraftStore compliance results

## V. Machine-Readable Contract Alignment

Caris now defines machine-readable contracts for policy snapshots and evidence bundles under `schemas/`.

Alignment rule:

- If a downstream tool or wrapper emits a structured policy snapshot derived from `scripts/build_006.py`, `scripts/policy_constants.py`, or a validated constitutional export surface, that payload must validate against `schemas/policy_snapshot.schema.json`.
- If a downstream tool packages legal, gate, provenance, and release references into a single evidence artifact, that payload must validate against `schemas/evidence_bundle.schema.json`.

These schemas define normalized contract shape only. They do not replace the current executable authority or current output structure of `scripts/build_006.py`.

## VI. Current Source Of Truth

The following files define the legal-build policy surface:

- `scripts/build_006.py`
- `scripts/policy_constants.py`
- `docs/architecture/007_REVISIONS_AUTOMATION.md`

If these files disagree, executable policy constants and executable script behavior win over prose examples.

## VII. Operating Procedure

1. Run `scripts/build_006.py` from the repository root.
2. Enter the inventor name, problem statement, and human constraints when prompted.
3. Preserve the generated JSON record in `legal/`.
4. Preserve the generated revision anchor in `extras/`.
5. Commit both outputs only when your legal or release workflow requires them.

## VIII. Disclosure Statement

"Artificial Intelligence was utilized as a subordinate mechanical instrument for clerical drafting. The selection, arrangement, and enforcement of all architectural invariants were directed solely by the human inventor."
