# 008 Two-Repo Split And Runtime Ingestion

## I. Purpose

This document defines the constitutional split between Caris and Phoenix.

Caris is the constitutional authority repo.
Phoenix is the governed runtime repo.

The split exists so doctrine, policy, guardrails, export contracts, and constitutional templates remain authored in one place while runtime execution, UI, platform runners, and runtime-local evidence remain authored in another.

## II. Ownership Boundary

Caris owns:

- doctrine under `docs/architecture/`
- routing authority and hard-gate policy
- policy and hard-gate scripts under `scripts/`
- guardrail templates under `templates/guardrails/`
- constitutional runtime templates under `templates/runtime/`
- machine-readable export contracts and schema contracts
- hook and CI governance templates
- the maintained dependency allowlist authority
- the maintained `phoenix_governance` template authority

Phoenix owns:

- runtime orchestration
- UI
- platform runners
- runtime-only helpers
- runtime-local evidence surfaces
- runtime-local copies or projections of Caris exports after ingestion

Phoenix therefore consumes Caris exports and must not be the authoring home for doctrine.

Downstream interpretation rule:

- Phoenix and any other governed runtime validate against Caris-owned exports and Caris-owned contracts.
- They do not re-author those constitutional surfaces locally.

## III. Active Profile Rule For This Split Path

For the Caris to Phoenix split path, Flutter is the only active Phoenix runtime profile.

Implications:

- `002_FLUTTER_ARCH_DOCS_CONSOLIDATED.md` is active profile doctrine for Phoenix ingestion.
- React and Universal doctrine may remain in Caris for other governed runtimes.
- React and Universal doctrine must be excluded from Phoenix active ingestion.
- Presence of React or Universal doctrine in Caris does not activate those profiles for Phoenix.

## IV. Constitutional Runtime Ingestion Rules

Downstream runtime ingestion must obey all of the following:

- ingestion is read-only with respect to Caris source files
- runtime-local copies are imported authority, not maintained authority
- the runtime must fail closed when Caris source is missing
- the runtime must fail closed when the export manifest is malformed
- the runtime must fail closed when referenced export paths do not exist
- the runtime must fail closed when excluded profile docs are referenced as active Phoenix law

No runtime may silently fall back to a drifted local doctrine source once Caris export ingestion is the declared constitutional path.

## V. Caris-Owned Runtime Authorities

The following authorities are explicitly Caris-owned for Phoenix ingestion:

- dependency allowlist authority
- `phoenix_governance` template authority
- export manifest authority for the Flutter ingestion surface

Phoenix may hold runtime-local instances of imported files, but it may not become the authoring home for those authorities.

## VI. Export Surface Requirements

The first machine-readable Caris export surface for Phoenix must be:

- runtime target: `phoenix`
- active profile: `flutter`
- doctrine and policy only
- read-only constitutional ingestion
- fail-closed on missing or malformed source
- explicit required schema references for the downstream validation set

The export surface must include only files that actually exist in Caris and are approved for Phoenix runtime use.

The export surface must not treat the following as active Phoenix runtime law:

- `002b_NEXTJS_REACT_ARCH_DOCS.md`
- `002c_UNIVERSAL_ARCH_BLUEPRINT.md`
- `004b_REACT_WHITE_LIST_CORE_STACK.md`

## VII. Dependency Allowlist Authority

The dependency allowlist authority is maintained in Caris under `templates/guardrails/dependency_allowlist.json`.

Interpretation rule:

- the allowlist may include runtime helper or release tooling dependencies needed by Phoenix
- those entries do not activate React or Universal doctrine
- the active profile remains Flutter unless constitutional doctrine changes explicitly

## VIII. Phoenix Governance Template Authority

The maintained Phoenix governance template lives in Caris under `templates/runtime/flutter/phoenix_governance.template.yaml`.

Interpretation rule:

- the Caris file is the template authority
- the Phoenix repo may materialize a local runtime instance from that template
- the local instance does not become the constitutional source

## IX. Validation Rule

Phoenix and any other governed runtime must validate:

- exported constitutional files against the Caris export manifest
- governance payloads against the Caris schema set
- excluded profile doctrine as inactive for the Phoenix Flutter split path

Validation must be fail-closed when Caris source, manifest, schema references, or exported files are missing or malformed.

## X. Enforcement Posture

This split is contract-first and additive.

Nothing in this document authorizes:

- bypassing whitelist authority
- bypassing audit routing
- bypassing hard gates
- activating non-Flutter profile doctrine in Phoenix
- turning runtime-local doctrine copies into maintained constitutional sources
