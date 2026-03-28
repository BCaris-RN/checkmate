# 003 Dev Skills And Protocols

## I. Purpose

This document defines the behavioral execution protocols for Caris-governed work. These protocols govern how humans, assistants, and delegated agents operate during implementation, debugging, review, and release preparation.

These protocols do not replace constitutional authority. They are subordinate to:

1. Active profile
2. Whitelist authority
3. Audit routing
4. Hard gates

Constitutional precedence rule:

- The four pillars below are execution discipline only.
- They do not create alternate dependency authority.
- They do not create alternate audit routes.
- They do not relax hard gates.
- They do not suspend constitutional profile discipline.

## II. The Four Execution Pillars

### 1. Systematic Debugging

Systematic debugging is mandatory behavioral protocol, not optional craft style.

Required sequence:

1. Reproduce the failure with concrete inputs or file state.
2. Capture the failing evidence: trace, output, gate result, or artifact mismatch.
3. Trace the execution path to the smallest plausible fault boundary.
4. Form one explicit hypothesis at a time.
5. Apply the smallest change that can falsify or confirm that hypothesis.
6. Re-run the relevant verification surface before declaring the issue resolved.

Execution boundary:

- Debug only inside the currently active profile and approved dependency envelope.
- A debugging shortcut that violates whitelist authority or hard gates is invalid even if it appears to fix the local symptom.

Forbidden shortcuts:

- Guess-driven fixes without a reproduced failure
- Bundling multiple speculative fixes into one unverified change
- Declaring success from intuition alone

### 2. Verification Before Completion

Completion is a verification state, not a writing state.

Required rule:

- No task is complete until the relevant validation surface has been checked and reported.

Examples of valid verification surfaces:

- Targeted tests
- Schema validation
- Hard-gate utilities
- Hook-compatible checks
- Build or packaging checks when the task touches those surfaces

Behavioral rule:

- If validation was not run, the outcome must be reported as unverified rather than complete.

This protocol does not replace hard gates, whitelist checks, audit routing, or profile selection. It is the operator discipline that runs before and after those controls.

### 3. Isolated Code Review

Code review must occur as an isolated evaluation step, separate from implementation momentum.

Required review posture:

- Review the resulting change as if it were written by an untrusted contributor.
- Prioritize bugs, drift, missing validation, and behavioral regressions before style or summarization.
- Compare the change against active profile rules, whitelist authority, audit route, hard-gate expectations, and Caris-owned contract shapes.

Review outputs must lead with findings when findings exist.

Forbidden review shortcuts:

- Reviewing only the happy path
- Treating passing tests as sufficient architectural review
- Using review prose to excuse a hard-gate violation

### 4. Controlled Subagent Execution

Delegated or subagent execution is permitted only as bounded assistance under primary architectural control.

Required rules:

- The primary architect or controlling agent remains accountable for the final result.
- Delegation must be scoped to a concrete subtask with a clear output boundary.
- Delegated work must not redefine policy, authorize dependencies, change the active profile, or bypass audit routing.
- Delegated work must not invent a runtime-local schema that weakens a Caris-owned contract.
- A subagent may not self-approve write, apply, execute, release, or publish authority.
- Any side-effectful action still requires the same permissioned-action flow and hard gates as non-delegated work.

Controlled subagent execution is therefore a behavioral protocol. It is not a substitute for whitelist authority, audit routing, hard-gate enforcement, or constitutional profile discipline.

## III. Supporting Practices

### Test-First Discipline

For production logic, prefer a test-first or failure-first loop whenever the target surface supports it:

1. Make the expected failure concrete.
2. Implement the smallest passing change.
3. Refactor only while the verification surface remains green.

### Spike Sandbox Discipline

Spike work is permitted only inside constitutional sandbox zones:

- `experimental/`
- `*.proto.*`

Containment rules:

- Production paths must not depend on sandbox artifacts.
- Sandbox artifacts must not survive into committed production code.
- Stale spike artifacts remain subject to exclusion-zone enforcement.

### Evidence Discipline

When work affects governance, release, or legal surfaces, preserve machine-readable evidence rather than narrative-only claims.

Examples:

- Policy snapshots
- Evidence bundles
- Permissioned action requests and decisions
- Build records
- Release evidence references

## IV. Audit Routing Tie-In

Before implementation, determine the route through current executable policy:

- `scripts/complexity_gate.py`
- `scripts/policy_constants.py`

Routing states:

- `self_certify`
- `standard_audit`
- `stop_and_think`

Behavioral execution protocols help operators work correctly inside those routes. They do not grant an alternate route and they do not soften any hard gate.
