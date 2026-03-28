# Guardrail Templates

Use these templates as a starting point for local IDE enforcement.

## Flutter

1. Install `custom_lint` in your app project.
2. Copy `templates/guardrails/analysis_options.caris.yaml` to `analysis_options.yaml`.
3. Merge with any existing analyzer rules.

## Next.js / React

1. Copy `templates/guardrails/.eslintrc.caris.json` to `.eslintrc.json`.
2. Merge with existing project rules if needed.
3. Keep `no-restricted-imports` as `error`.

## Governance

- Never weaken these rules without explicit documented sign-off.
- Unvetted dependencies remain banned unless approved in `004_EXTERNAL_LIBS_AND_RESOURCES.md`.
