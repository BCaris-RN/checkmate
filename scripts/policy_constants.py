"""Shared Caris Stack policy constants.

This file is the source of truth for routing thresholds, governance-doc scope,
revision metadata, and token-policy values referenced by docs and automation.
"""

from __future__ import annotations

LOW_COMPLEXITY_THRESHOLD = 5
HIGH_COMPLEXITY_THRESHOLD = 20

GOVERNANCE_DOC_BASENAMES = frozenset(
    {
        "000_quickstart_implementation_manual.md",
        "001_system_rules_and_roadmaps.md",
        "002_flutter_arch_docs_consolidated.md",
        "002b_nextjs_react_arch_docs.md",
        "002c_universal_arch_blueprint.md",
        "003_dev_skills_and_protocols.md",
        "004_external_libs_and_resources.md",
        "004b_react_white_list_core_stack.md",
        "005_toolbox_scripts.md",
        "006_legal_documentation_builder.md",
        "007_revisions_automation.md",
    }
)

HIGH_RISK_EXACT_PATHS = GOVERNANCE_DOC_BASENAMES | frozenset(
    {
        "lefthook.yml",
        ".github/workflows/caris-hard-gates.yml",
    }
)

HIGH_RISK_PREFIXES = (
    "scripts/enforce_exclusion_zones.",
    "templates/guardrails/",
    "schemas/",
)

STACK_VERSION_TAG = "Caris_Stack_v3_Governed"
TOKEN_SCALE_RATIO = 1.5
TOKEN_BASELINE_GRID_PX = 8
SOVEREIGN_SEAL = "[SOVEREIGN SYSTEM CONSTITUTION SEAL]"


def complexity_routing_summary() -> str:
    return (
        f"Fast < {LOW_COMPLEXITY_THRESHOLD}; "
        f"Standard {LOW_COMPLEXITY_THRESHOLD}-{HIGH_COMPLEXITY_THRESHOLD}; "
        f"Stop-and-Think > {HIGH_COMPLEXITY_THRESHOLD} or any high-risk override."
    )


def build_revision_text(human_name: str, scanned_targets: int, revision_identifier: str) -> str:
    return f"""{SOVEREIGN_SEAL}
REVISION IDENTIFIER: {revision_identifier}
VERSIONING: {STACK_VERSION_TAG}
INVENTORSHIP ASSERTION: Architectural selection and arrangement directed solely by human inventor {human_name}.

LOG CONTENT REQUIREMENTS:
- Hard Gate Audit: {complexity_routing_summary()}
- High-Risk Governance Surface: Any numbered governance document, exclusion/guardrail configs, and schema/migration paths force Stop-and-Think.
- Design Token Sync: Confirm the typography scale ratio {TOKEN_SCALE_RATIO} and baseline grid {TOKEN_BASELINE_GRID_PX}px are locked.
- Resilience Check: Verify Active Recovery (DraftStore) and Circuit Breaker policies are compiled.
- DraftStore Compliance Gate: VERIFIED across {scanned_targets} ViewModel/Controller file(s).
"""
