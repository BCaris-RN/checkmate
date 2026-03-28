================================================================================
PART 1: THE DESIGN SYSTEM ("THE UNFORGETTABLE AESTHETIC")
================================================================================
[INSTRUCTION: This protocol applies regardless of frontend framework.]

1. CORE PHILOSOPHY
   - Reject generic default component libraries that look like internal admin dashboards.
   - Anti-slop is enforced as data, not adjectives.
   - Every UI implementation must declare a token profile selected from the locked schema before code generation begins.

2. LOCKED DESIGN TOKEN SCHEMA (MANDATORY)
   [Constraint: The AI must select from these exact values. Hallucinated fonts/tokens are prohibited.]
   ```json
   {
     "schemaVersion": 1,
     "fontPairs": {
       "editorial": { "display": "DM Serif Display", "body": "IBM Plex Sans" },
       "industrial": { "display": "Bebas Neue", "body": "IBM Plex Sans" },
       "technical": { "display": "Space Mono", "body": "IBM Plex Sans" }
     },
     "typography": {
       "bodyBaseRem": 1.0,
       "scaleRatio": 1.5,
       "displayLineHeight": 1.0,
       "bodyLineHeight": 1.6
     },
     "spacing": {
       "baselineGridPx": 8,
       "minimumTouchTargetPx": 44
     },
     "textureAssets": [
       "grain_soft_01",
       "grain_heavy_01",
       "noise_film_01",
       "paper_fiber_01"
     ]
   }
   ```
   - Source of truth for `textureAssets`: `004_EXTERNAL_LIBS_AND_RESOURCES.md`.
   - Implementation rule: serialize chosen values into config/constants, not prose.
   - Machine-enforcement rule: write the selected profile to a JSON lockfile and validate it with `scripts/design_token_guard.py`.
   - Hard-fail rule: raw hex colors and off-scale font sizes in production UI code are build/lint failures.

3. FRAMEWORK PROJECTION RULE (MANDATORY)
   The active profile must map the universal schema to framework-specific token aliases.

   | Universal schema key | Flutter projection | Web projection |
   | --- | --- | --- |
   | `fontPairs.<profile>.display` | generated `AppFonts.displayFamily` | `--font-display` / `font-display` |
   | `fontPairs.<profile>.body` | generated `AppFonts.bodyFamily` | `--font-body` / `font-sans` |
   | `typography.scaleRatio` | generated `AppTypeScale.*` | semantic classes such as `text-display-xl` |
   | `spacing.baselineGridPx` | `AppSpacing.grid*` constants | semantic spacing aliases such as `px-grid-4` |
   | `textureAssets[]` | named asset constants | semantic classes such as `bg-texture-paper-fiber` |

4. TYPOGRAPHY: EXPONENTIAL SCALING
   - Required ratio: `scaleRatio = 1.5`.
   - Headers: derive from the selected display font and the same scale.
   - Body: base `1rem`, line height `1.6`, selected body font.
   - Implement via generated tokens, CSS variables, or theme config.

5. WHITESPACE AND LAYOUT
   - Use the locked `baselineGridPx = 8` spacing system.
   - Minimum touch target: `44px`.
   - Express spacing through semantic tokens or utility aliases, not hard-coded one-off values.

================================================================================
PART 2: CORE ARCHITECTURE AND DEPENDENCIES
================================================================================
[INSTRUCTION: AI assistants must adhere to the active stack and whitelist authority.]

1. DEPENDENCY AUTHORITY
   - `004_EXTERNAL_LIBS_AND_RESOURCES.md` is the canonical whitelist for all profiles.
   - If `002b_NEXTJS_REACT_ARCH_DOCS.md` is active, `004b_REACT_WHITE_LIST_CORE_STACK.md` is also required.
   - Any package outside the active whitelist requires explicit documented sign-off.

2. THE TECH STACK
   - Primary language: [ENTER LANGUAGE]
   - Web/API framework: [ENTER FRAMEWORK]
   - Database and ORM: [ENTER DB/ORM]
   - Frontend/UI: [ENTER FRONTEND]
   - Activation rule: this profile is invalid until placeholders are replaced and committed.
   - Governance rule: once activated, add a short ADR documenting the chosen stack and approved package set.

3. SEPARATION OF CONCERNS
   - Presentation layer: handles HTTP/UI boundaries only.
   - Service layer: owns business rules and orchestration.
   - Data layer: owns persistence and external integrations.

4. DIRECTORY STRUCTURE (UNIVERSAL PATTERN)
   /src
     /api
     /core
     /domain
     /infrastructure

================================================================================
PART 3: IMPLEMENTATION REFERENCE
================================================================================

/// Inversion of Control pattern
Interface IUserRepository {
    Function GetUserById(id) -> User
}

Class PostgresUserRepository implements IUserRepository {
    Function GetUserById(id) {
        return DB.Query("SELECT * FROM users WHERE id = ?", id)
    }
}

Class UserService {
    Dependency repo: IUserRepository

    Function FetchAndFormatUser(id) {
        user = repo.GetUserById(id)
        if (!user) throw NotFoundError()
        return Formatter.Format(user)
    }
}

================================================================================
PART 4: DATA LAYER AND PERFORMANCE
================================================================================

1. PAGINATION
   - Violation: offset scans on large lists.
   - Requirement: keyset/cursor pagination.

2. STATE AND CACHING
   - Cache hot data deliberately.
   - Persist recoverable user input before risky mutations.

3. SQL OPTIMIZATION
   - Run `EXPLAIN ANALYZE` on slow queries.
   - Avoid `Seq Scan` on large tables.
   - Use B-Tree, GIN, and other indexes according to access pattern.

================================================================================
PART 5: PRODUCTION HARDENING
================================================================================

1. AUTOMATED VERIFICATION
   - No production logic without automated verification.

2. HORROR PATH
   - Handle upstream collapse, mutation failure, and malformed payloads.
   - Wrap external dependencies in circuit breaker and/or retry policies.
   - Restore user input after failed submissions.
   - Do not expose raw stack traces.

3. FINAL REVIEW GATES
   - [ ] Is the active token profile declared and lockfile-backed?
   - [ ] Are UI values projected through semantic tokens instead of raw literals?
   - [ ] Is business logic decoupled from transport/UI boundaries?
   - [ ] Are remote dependencies wrapped in resilience policies?
   - [ ] Is recoverable user state restored after failure?
