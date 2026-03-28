# WHITELIST AUTHORITY: REACT CORE STACK APPENDIX

Purpose:
- This appendix expands the Next.js/React subset of `004_EXTERNAL_LIBS_AND_RESOURCES.md`.
- It is required whenever `002b_NEXTJS_REACT_ARCH_DOCS.md` is the active profile.

Authority rule:
- `004_EXTERNAL_LIBS_AND_RESOURCES.md` remains the canonical whitelist authority.
- This file is a profile-specific appendix for faster React review.

## PART 0: CORE UI AND RESILIENCE

| Dependency | Tier | Purpose |
| --- | --- | --- |
| Tailwind CSS | Default | Token-projected utility styling |
| clsx | Default | Conditional class composition |
| tailwind-merge | Default | Tailwind-aware class merging |
| Radix UI | Default | Accessible headless primitives |
| shadcn/ui | Default | Component architecture built on Radix |
| Lucide React | Approved Alternative | SVG icon system |
| p-retry | Default | Exponential backoff for safe retries |
| Opossum | Default | Circuit breaker for backend/service boundaries |

## PART 1: STATE, FORMS, AND DATA FLOW

| Dependency | Tier | Purpose |
| --- | --- | --- |
| Zustand | Default | Global client state |
| TanStack Query | Approved Alternative | Client polling and server-state caching |
| React Hook Form | Approved Alternative | Form state management |
| Zod | Approved Alternative | Runtime validation |
| XState | Approved Alternative | Complex state machines |
| idb | Mandatory | IndexedDB adapter for recoverable drafts |

## PART 2: BACKEND AND AUTH PROFILES

| Dependency | Tier | Purpose |
| --- | --- | --- |
| Convex | Default | TypeScript-first realtime backend |
| Prisma | Approved Alternative | SQL-heavy relational workflows |
| Drizzle | Approved Alternative | SQL-heavy relational workflows |
| Clerk | Default | Hosted auth profile |
| Better Auth | Default | Framework-agnostic auth profile |
| Supabase | Approved Alternative | Postgres BaaS alternative |
| PocketBase | Approved Alternative | Lightweight Go/SQLite backend |

## PART 3: TESTING

| Dependency | Tier | Purpose |
| --- | --- | --- |
| Playwright | Default | Horror Path and E2E automation |
| Vitest | Approved Alternative | Unit/integration runner |
| Testing Library | Approved Alternative | DOM/component tests |

## PART 4: REVIEW CHECKPOINTS

- If a package is missing from both `004_EXTERNAL_LIBS_AND_RESOURCES.md` and this appendix, it is not pre-approved.
- If this appendix conflicts with `004_EXTERNAL_LIBS_AND_RESOURCES.md`, `004` wins unless an ADR states otherwise.
- All React examples must still obey the token lockfile rules defined in `002c_UNIVERSAL_ARCH_BLUEPRINT.md`.
