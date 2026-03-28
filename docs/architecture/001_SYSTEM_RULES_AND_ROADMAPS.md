# 001 System Rules And Roadmaps

## I. Constitutional Purpose

The Caris repo is the constitutional authority for governance doctrine, hard-gate policy, machine-readable contracts, and profile rules. Downstream runtimes such as Phoenix may execute or present those rules, but they do not own the constitutional definition.

If prose conflicts with executable policy in `scripts/`, `templates/guardrails/`, `lefthook.yml`, `.github/workflows/caris-hard-gates.yml`, or `scripts/policy_constants.py`, executable truth wins.

## II. Authority Order

The following order is mandatory:

1. Active profile
   - Exactly one profile may be active for a governed runtime.
   - Profile doctrine is selected from:
     - `002_FLUTTER_ARCH_DOCS_CONSOLIDATED.md`
     - `002b_NEXTJS_REACT_ARCH_DOCS.md`
     - `002c_UNIVERSAL_ARCH_BLUEPRINT.md`
2. Whitelist authority
   - `004_EXTERNAL_LIBS_AND_RESOURCES.md` is the canonical dependency authority.
   - `004b_REACT_WHITE_LIST_CORE_STACK.md` applies only when the active profile is `nextjs_react`.
3. Audit routing
   - `scripts/complexity_gate.py` and `scripts/policy_constants.py` determine the routing outcome.
   - Self-certify, standard audit, and Stop-and-Think are routing states, not style preferences.
4. Hard gates
   - Hard gates physically enforce constitutional rules.
   - They include exclusion-zone enforcement, dependency gate, complexity routing, design-token guard, hook policy, and CI policy.
5. Behavioral execution protocols
   - The execution protocols in `003_DEV_SKILLS_AND_PROTOCOLS.md` govern how humans and agents work.
   - They never override the active profile, whitelist authority, audit routing, hard gates, or constitutional profile discipline.

## III. Governance-Controlled Surface

The following paths are constitutional governance surfaces:

- `docs/architecture/000*` through `008*`
- `schemas/*.schema.json`
- `scripts/policy_constants.py`
- `scripts/complexity_gate.py`
- `scripts/dependency_gate.py`
- `scripts/design_token_guard.py`
- `scripts/validate_schema.py`
- `scripts/export_flutter_constitution_surface.py`
- `scripts/enforce_exclusion_zones.ps1`
- `scripts/enforce_exclusion_zones.sh`
- `templates/guardrails/*`
- `templates/runtime/flutter/*`
- `lefthook.yml`
- `.github/workflows/caris-hard-gates.yml`

Interpretation rule:

- Constitutional surface does not automatically mean the path is already enumerated by automated Stop-and-Think routing.
- Current automated routing authority remains whatever is encoded in `scripts/policy_constants.py` and `scripts/complexity_gate.py`.
- If prose names a broader constitutional surface than current automation enforces, executable truth still wins until the executable policy is intentionally updated.

## IV. Machine-Readable Contract Model

Caris owns the required contract surfaces for governed runtimes. These contracts define shape and authority boundaries; they do not prescribe a specific UI, daemon, or orchestration implementation.

Mandatory contract surfaces:

- Governance job manifest
- Governance job registry
- Permissioned action gateway
- Evidence bundle
- Policy snapshot

Gateway interpretation:

- The permissioned action gateway is represented by a typed request contract plus a typed decision contract.
- These contracts are constitutional must-haves for any governed runtime that performs write, apply, execute, release, or publish actions.

Constitutional rules for those contracts:

- All downstream runtimes must validate payloads against the Caris-owned schemas under `schemas/`.
- No contract may authorize an action forbidden by the active profile.
- No contract may approve a dependency absent from whitelist authority.
- No contract may bypass audit routing.
- No contract may waive or replace hard gates.

## V. Downstream Runtime Requirements

Phoenix and any other governed runtime must treat Caris contracts as imported authority.

Minimum downstream obligations:

- Load the active profile before job execution.
- Validate dependency policy against Caris whitelist authority.
- Route work through the current audit policy.
- Enforce hard gates before any side-effectful write, apply, execute, release, or publish action.
- Validate machine-readable governance payloads against the Caris schema set.
- Treat behavioral execution pillars as operator discipline only, never as authority to bypass constitutional controls.

## VI. Roadmap For The Split Model

Phase 1: Constitutional authority
- Keep doctrine, policy, and schemas in Caris.

Phase 2: Import boundary
- Require downstream runtimes to ingest Caris-owned contracts instead of redefining them.

Phase 3: Permissioned execution
- Require typed request and typed decision records for side-effectful actions.

Phase 4: Evidence and policy traceability
- Require downstream evidence bundles to reference gate outcomes, policy snapshots, and provenance artifacts.

Phase 5: Legal and revision alignment
- Keep legal and revision automation subordinate to current executable truth rather than stale prose examples.
