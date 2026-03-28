ENTERPRISE AI & DEVOPS PROTOCOL: IMPLEMENTATION MANUAL
Welcome to The Caris Stack, a hardened architecture protocol for AI-assisted software engineering. This manual explains which documents are mandatory, when they apply, and how the shipped automation enforces them.

STEP 1: ESTABLISH THE GOVERNANCE SURFACE
The numbered files in `docs/architecture/` are not all used the same way. Adopt them intentionally.

Required in every governed repository:
- `001_SYSTEM_RULES_AND_ROADMAPS.md`
- `003_DEV_SKILLS_AND_PROTOCOLS.md`
- `004_EXTERNAL_LIBS_AND_RESOURCES.md`
- `005_TOOLBOX_SCRIPTS.md` when you are using the bundled local/CI automation

Profile-specific requirements:
- Select exactly one active architecture profile:
  - Flutter profile: `002_FLUTTER_ARCH_DOCS_CONSOLIDATED.md`
  - Next.js/React profile: `002b_NEXTJS_REACT_ARCH_DOCS.md`
  - Universal fallback profile: `002c_UNIVERSAL_ARCH_BLUEPRINT.md`
- If the Next.js/React profile is active, also include `004b_REACT_WHITE_LIST_CORE_STACK.md` as the required React appendix.

Operational and legal governance:
- `006_LEGAL_DOCUMENTATION_BUILDER.md` governs legal provenance capture for release/legal builds.
- `007_REVISIONS_AUTOMATION.md` governs generation of `extras/revision.txt`.

AI session loadout:
- Load `001`, `003`, `004`, and the active profile into the AI context.
- If the active profile is `002b`, load `004b` as well.
- `000`, `005`, `006`, and `007` are operator-facing documents unless the current task is onboarding, automation, or legal provenance.

Governance risk rule:
- Any numbered file under `docs/architecture/` is governance-controlled.
- Changes to those files force the Stop-and-Think route in `scripts/complexity_gate.py`.

STEP 2: USE THE RIGHT DOCUMENT AT THE RIGHT TIME
Session start:
- Confirm the active profile.
- Confirm which whitelist authority applies (`004` for all profiles; `004b` additionally for Next.js/React).

Before coding:
- Run the audit-routing check first.
- Use the active profile plus `004` and, when applicable, `004b`.

Before commit:
- Run local lint/guardrail hooks.
- Block stale spike artifacts, exclusion-zone violations, dependency drift, and token drift.

Before merge:
- Run CI hard gates.
- Complexity routing is handled by `scripts/complexity_gate.py` using `lizard`.
- CodeQL remains a separate security-analysis job, not the complexity engine.

Release or legal build:
- Run `scripts/build_006.py` when you need a legal provenance artifact or a forensic revision anchor.
- Outputs:
  - `legal/BUILD_RECORD_<timestamp>.json`
  - `extras/revision.txt`

STEP 3: DEPLOY THE SEMANTIC BUNDLER
Do not copy Python from documentation into a repo that already ships the script.

Use the included file:
- `scripts/generate_semantic_bundle.py`

Reference documentation:
- `005_TOOLBOX_SCRIPTS.md` documents the script internals and operating model.

Usage:
- Before asking the AI to refactor or build a feature, run `uv run scripts/generate_semantic_bundle.py`.
- Upload the resulting `SEMANTIC_BUNDLE.txt` only when you need dense static context.

Modern alternative:
- Cursor, Windsurf, Aider, and Cline are approved for automatic context indexing.
- They do not bypass audit routing.

STEP 4: LOCK DOWN LOCAL GUARDRAILS
Local lint rules are required but not sufficient. Commits must be physically blocked when policy is violated.

Required local hook policy:
- Install `lefthook.yml` or equivalent Husky scripts.
- Run framework linting:
  - Flutter: `custom_lint`
  - Next.js/React: `eslint`
- Run exclusion-zone enforcement before every commit.
- Run the Spike Protocol stabilization gate to reject staged `.proto.*` files and `experimental/` artifacts.
- Run design-token enforcement where UI code exists.
- Treat all violations as commit-blocking failures.

Bundled assets:
- `scripts/enforce_exclusion_zones.sh`
- `scripts/enforce_exclusion_zones.ps1`
- `scripts/design_token_guard.py`
- `scripts/dependency_gate.py`
- Guardrail templates under `templates/guardrails/`

STEP 5: WIRE THE CI/CD HARD GATES
The CI pipeline is the authoritative enforcement layer.

Complexity and audit routing:
- Use `scripts/complexity_gate.py` as the routing engine.
- The live thresholds and governance-doc set are sourced from `scripts/policy_constants.py`.
- Default routing bands:
  - Score `< 5`: Fast route / Self-Certify if no high-risk override
  - Score `5-20`: Standard route / Standard Audit if no high-risk override
  - Score `> 20`: Stop-and-Think
- Any high-risk path or semantic-risk trigger forces Stop-and-Think regardless of score.

Security and exclusion enforcement:
- Keep `scripts/enforce_exclusion_zones.*` in CI as fail-fast gates.
- Keep dependency and design-token gates in CI where relevant.
- Keep CodeQL as a dedicated security-analysis stage.

Bundled workflow:
- `.github/workflows/caris-hard-gates.yml`

STEP 6: SHIFT-LEFT THREAT MODELING
Do not assume validation logic works. Prove it.

Use the Stress-Test prompt from `005_TOOLBOX_SCRIPTS.md` to generate malicious payloads, then execute them in the active UI test framework:
- Flutter: Patrol
- Next.js/React: Playwright

Verify the Horror Path end to end:
- graceful failure
- active recovery where safe
- persisted draft restoration
- no raw stack traces in the user-facing surface

STEP 7: LEGAL AND RELEASE ANCHORING
When the build needs inventorship or release-lineage evidence:
- Run `scripts/build_006.py`
- Record the human inventor, problem statement, and human constraints
- Preserve the generated build record in `legal/`
- Preserve the generated revision anchor in `extras/`

If you are adopting only the architecture rules and not the legal lineage flow:
- `006` and `007` may remain operator documentation only
- but the rest of the governance surface still applies
