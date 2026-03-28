================================================================================
WHITELIST AUTHORITY
================================================================================

Rule:
- This file is the canonical dependency whitelist authority for The Caris Stack.

Profile appendix rule:
- `004b_REACT_WHITE_LIST_CORE_STACK.md` is a required React appendix when `002b_NEXTJS_REACT_ARCH_DOCS.md` is active.
- `004b` expands the React subset of this document; if conflict exists, this file wins unless an ADR states otherwise.

Approval tiers:
- Mandatory: required by the active profile or governance model.
- Default: preferred first choice.
- Approved Alternative: acceptable with normal architectural review.
- Reference Only: educational or comparative, not a default install recommendation.

================================================================================
PART 0: CROSS-STACK MANDATORY WHITELISTS
================================================================================

### Resilience and Recovery

| Dependency / Pattern | Tier | Usage |
| --- | --- | --- |
| Resilience4j | Mandatory (Java/Kotlin) | Circuit breaker, retry, bulkhead, rate limiting |
| Polly | Mandatory (.NET/C#) | Retry, circuit breaker, fallback policies |
| p-retry | Default (JavaScript/TypeScript) | Exponential backoff for safe async/HTTP retries |
| Opossum | Default (JavaScript/TypeScript) | Circuit breaker for Node.js and Edge-compatible services |
| `package:http` + repository-owned wrapper | Default (Dart/Flutter) | HTTP client plus repo-owned retry/circuit policy wrapper |

Policy:
- Graceful failure alone is insufficient.
- External calls must use active recovery where safe.
- Client/view-model layers must persist recoverable input before mutation requests.

### Draft Persistence

| Dependency / Pattern | Tier | Usage |
| --- | --- | --- |
| `shared_preferences` behind `DraftStore` | Mandatory (Flutter profile) | Recoverable non-secret form drafts |
| `idb` (IndexedDB) adapter | Mandatory (Next.js/React profile) | Recoverable client-side drafts |

Security rule:
- Passwords, auth tokens, payment card data, and secrets are forbidden in client/local draft stores unless a separately approved secure-storage profile exists.

### Design Tokens and Texture Assets

Policy:
- Production UI code must consume lockfile-backed semantic tokens, not raw literals.
- Approved texture assets must be referenced by semantic token/config aliases.

Required static asset path:
- `assets/textures/` or framework-equivalent static directory

Approved texture assets:
- `grain_soft_01.png`
- `grain_heavy_01.png`
- `noise_film_01.png`
- `paper_fiber_01.png`
- `mesh_shadow_01.png`

================================================================================
PART 1: FLUTTER PROFILE WHITELIST
================================================================================

### Default UI and Design System

| Dependency | Tier | Usage |
| --- | --- | --- |
| Forui | Default | Minimalist UI component baseline |
| google_fonts | Default | Framework adapter for approved font families from the token profile |

### State, Routing, and Persistence

| Dependency | Tier | Usage |
| --- | --- | --- |
| Riverpod | Default | App-wide state management |
| flutter_hooks | Default | Local composable widget state |
| GoRouter | Default | Navigation and deep linking |
| shared_preferences | Mandatory | `DraftStore` backend for recoverable drafts |

### Networking and Testing

| Dependency | Tier | Usage |
| --- | --- | --- |
| `package:http` | Default | HTTP client used behind repo-owned resilience wrapper |
| Patrol | Default | Horror Path and integration testing |
| custom_lint | Default (dev) | Local architecture and token enforcement |

### Approved Alternatives

| Dependency | Tier | Usage |
| --- | --- | --- |
| AutoRoute | Approved Alternative | Codegen-focused routing |
| Beamer | Approved Alternative | Navigator 2.0 routing |
| Bloc | Approved Alternative | Alternate app-wide state model |
| Provider | Approved Alternative | Lightweight inherited-widget wrapper |
| MobX | Approved Alternative | Reactive state model |
| Signals | Approved Alternative | Signal-based reactivity |
| Flutter Animate | Approved Alternative | Motion/effects |
| Rive | Approved Alternative | Interactive vector animation |
| Lottie | Approved Alternative | Imported animation playback |

================================================================================
PART 2: NEXT.JS / REACT PROFILE WHITELIST
================================================================================

### Core UI and Styling

| Dependency | Tier | Usage |
| --- | --- | --- |
| Tailwind CSS | Default | Utility-based styling engine behind semantic token aliases |
| clsx | Default | Conditional class composition |
| tailwind-merge | Default | Tailwind-aware merge helper |
| Radix UI | Default | Accessible headless primitives |
| shadcn/ui | Default | Component architecture built on Radix UI |
| Lucide React | Approved Alternative | Icon system |

### State, Forms, and Validation

| Dependency | Tier | Usage |
| --- | --- | --- |
| Zustand | Default | Global client state |
| TanStack Query | Approved Alternative | Client polling and server-state management |
| React Hook Form | Approved Alternative | Form management |
| Zod | Approved Alternative | Runtime schema validation |
| XState | Approved Alternative | Complex state machines and actors |
| idb | Mandatory | Recoverable draft persistence |

### Backend and Auth

| Dependency | Tier | Usage |
| --- | --- | --- |
| Convex | Default | TypeScript-first realtime backend profile |
| Prisma | Approved Alternative | SQL-heavy relational workflows |
| Drizzle | Approved Alternative | SQL-heavy relational workflows |
| Clerk | Default | Hosted auth profile |
| Better Auth | Default | Framework-agnostic auth profile |

### Testing

| Dependency | Tier | Usage |
| --- | --- | --- |
| Playwright | Default | Horror Path and E2E validation |
| Vitest | Approved Alternative | Unit/integration test runner |
| Testing Library | Approved Alternative | DOM/component tests |

================================================================================
PART 3: CROSS-STACK OPTIONAL ALTERNATIVES
================================================================================

These are approved alternatives or reference technologies. They are not the default install path unless the active profile or an ADR selects them.

| Technology | Tier | Usage |
| --- | --- | --- |
| Remix | Approved Alternative | Web Fetch API-aligned React alternative |
| Astro | Approved Alternative | Content-heavy zero/low-JS sites |
| Expo | Approved Alternative | React Native/mobile velocity stack |
| Supabase | Approved Alternative | Open-source Postgres BaaS |
| Firebase | Approved Alternative | Managed backend platform |
| Appwrite | Approved Alternative | Secure backend platform |
| PocketBase | Approved Alternative | Single-file Go/SQLite backend |
| Serverpod | Approved Alternative | Dart-native backend platform |

================================================================================
PART 4: REFERENCE TOOLS AND LEARNING RESOURCES
================================================================================

Reference only:
- Flutter Website: `https://flutter.dev`
- Flutter Gallery: `https://github.com/flutter/gallery`
- Flutter YouTube: `https://www.youtube.com/flutterdev`
- roadmap.sh Flutter roadmap: `https://roadmap.sh/flutter`
- Ngrok: `https://ngrok.com`

Reference architecture repos:
- AppFlowy
- RustDesk
- Spotube
- History of Everything

Rule:
- Reference entries are for study and comparison only.
- They do not automatically become approved install dependencies.
