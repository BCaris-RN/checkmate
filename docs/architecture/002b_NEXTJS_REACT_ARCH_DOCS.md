================================================================================
PART 1: THE DESIGN SYSTEM ("THE UNFORGETTABLE AESTHETIC")
================================================================================

1. ACTIVE TOKEN PROFILE
   - Active font pair: `technical`
   - Display font: `Space Mono`
   - Body font: `IBM Plex Sans`
   - The selected profile must be written to a lockfile-backed token source before UI code is written.

2. NEXT.JS TOKEN PROJECTION MAP

| Universal schema key | Web token alias | Example usage |
| --- | --- | --- |
| `fontPairs.technical.display` | `--font-display` / `font-display` | headings and hero hooks |
| `fontPairs.technical.body` | `--font-body` / `font-sans` | body copy and form UI |
| `typography.scaleRatio` | `text-display-xl`, `text-display-md`, `text-body-md` | semantic text classes |
| `spacing.baselineGridPx` | `px-grid-*`, `gap-grid-*`, `py-grid-*` | rhythm and layout spacing |
| `textureAssets.grain_soft_01` | `bg-texture-grain-soft` | atmospheric surface treatment |

3. UI RULES
   - Use semantic aliases such as `bg-surface`, `text-fg-primary`, `border-line-subtle`, and `text-display-xl`.
   - Do not use raw palette utilities as the source of truth.
   - Do not introduce fonts outside the active token profile without sign-off.

================================================================================
PART 2: APP ARCHITECTURE (NEXT.JS APP ROUTER)
================================================================================

1. DEPENDENCY STACK
   - Framework: Next.js App Router
   - UI primitives: Radix UI + shadcn/ui
   - Styling: Tailwind CSS + clsx + tailwind-merge
   - State management: Zustand (global), local React state where sufficient
   - Draft persistence: IndexedDB via `idb`
   - Backend profiles:
     * Default: Convex
     * Approved alternatives: Prisma or Drizzle with PostgreSQL
   - Auth profiles:
     * Default: Clerk or Better Auth
   - Whitelist authority:
     * canonical: `004_EXTERNAL_LIBS_AND_RESOURCES.md`
     * required React appendix: `004b_REACT_WHITE_LIST_CORE_STACK.md`

2. SERVER / CLIENT BOUNDARY
   - Server Components:
     * own data fetching and sensitive logic
     * do not use interactive hooks
   - Client Components:
     * sit at leaf nodes
     * own browser APIs, local state, and recoverable interaction flows

3. DIRECTORY STRUCTURE
   /src
     /app
     /components
       /ui
       /shared
     /lib
       /design
       /drafts
     /server
     /store

================================================================================
PART 3: IMPLEMENTATION REFERENCE
================================================================================

/// Lockfile-projected token module consumed by Tailwind/theme config.
export const designTokens = {
  fonts: {
    displayClass: 'font-display',
    bodyClass: 'font-sans',
  },
  type: {
    displayXL: 'text-display-xl',
    displayMD: 'text-display-md',
    bodyMD: 'text-body-md',
  },
  spacing: {
    pageX: 'px-grid-8',
    pageY: 'py-grid-8',
    sectionGap: 'gap-grid-4',
  },
  textures: {
    grainSoft: 'bg-texture-grain-soft',
  },
} as const;

import { fetchUserData } from '@/server/actions/user';
import { designTokens } from '@/lib/design/tokens';

export default async function DashboardPage() {
  const user = await fetchUserData();

  return (
    <main className={`min-h-screen bg-surface text-fg-primary ${designTokens.spacing.pageX} ${designTokens.spacing.pageY}`}>
      <section className={`grid ${designTokens.spacing.sectionGap} ${designTokens.textures.grainSoft}`}>
        <h1 className={`${designTokens.fonts.displayClass} ${designTokens.type.displayXL} leading-display tracking-display-tight`}>
          Welcome Back.
        </h1>
        <UserProfileCard initialData={user} />
      </section>
    </main>
  );
}

/// Recoverable draft flow using IndexedDB before mutation.
export async function submitProfileDraft(draft: ProfileDraft) {
  await draftStore.saveDraft(draft.key, draft);
  try {
    await updateProfileAction(draft);
    await draftStore.clearDraft(draft.key);
  } catch (error) {
    await draftStore.restoreDraft(draft.key);
    throw error;
  }
}

================================================================================
PART 4: DATA LAYER AND PERFORMANCE
================================================================================

1. PAGINATION
   - Requirement: keyset/cursor pagination for large lists.
   - Convex pattern: cursor-token pagination.
   - Prisma/Drizzle pattern: cursor-based or `WHERE id > last_seen_id LIMIT 20`.

2. CACHING
   - Cache stable reads with the appropriate Next.js primitives.
   - Revalidate deliberately after mutation.

3. QUERY OPTIMIZATION
   - Avoid N+1 reads and chatty client fetch loops.
   - Index by access pattern.

================================================================================
PART 5: PRODUCTION HARDENING AND QA
================================================================================

1. HORROR PATH
   - Handle Server Action failure and upstream dependency collapse explicitly.
   - Use `p-retry` for safe retries and `Opossum` where circuit breaking is required.
   - Persist recoverable drafts to IndexedDB via `idb` before mutation dispatch.
   - Do not expose raw stack traces.

2. ACCESSIBILITY
   - Prefer Radix primitives over custom accessibility re-implementation.
   - Keep visible focus states on interactive controls.
   - Verify semantic token combinations meet WCAG contrast.

3. FINAL REVIEW GATES
   - [ ] Is `"use client"` pushed to leaf nodes?
   - [ ] Does the UI consume semantic token aliases instead of raw utility literals as the source of truth?
   - [ ] Does the active font pair match the lockfile?
   - [ ] Are recoverable drafts persisted via `idb` before mutation?
   - [ ] Are retry/circuit breaker decisions explicit and safe?

4. IDE GUARDRAILS
   - ESLint must enforce architectural boundaries and token discipline.
   - Token drift must fail locally and in CI.
