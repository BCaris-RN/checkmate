================================================================================
PART 1: THE DESIGN SYSTEM ("THE UNFORGETTABLE AESTHETIC")
================================================================================

1. ACTIVE TOKEN PROFILE
   - Active font pair: `editorial`
   - Display font: `DM Serif Display`
   - Body font: `IBM Plex Sans`
   - The selected values must be stored in a lockfile-backed token source before UI code is written.

2. TYPOGRAPHY AND COLOR RULES
   - Use generated semantic tokens, not raw `Color(...)` values or ad-hoc font sizes.
   - Required type aliases:
     * `type.displayXL`
     * `type.displayMD`
     * `type.bodyMD`
     * `type.labelMD`
   - Required color aliases:
     * `colors.surface`
     * `colors.textPrimary`
     * `colors.textMuted`
     * `colors.accent`

3. FLUTTER TOKEN PROJECTION MAP

| Universal schema key | Flutter token alias | Theme usage |
| --- | --- | --- |
| `fontPairs.editorial.display` | `AppFonts.displayFamily` | `GoogleFonts.getFont(AppFonts.displayFamily)` |
| `fontPairs.editorial.body` | `AppFonts.bodyFamily` | `GoogleFonts.getFont(AppFonts.bodyFamily)` |
| `typography.scaleRatio` | `AppTypeScale.*` | `TextTheme` sizing |
| `spacing.baselineGridPx` | `AppSpacing.grid*` | padding, gaps, layout rhythm |
| `textureAssets.paper_fiber_01` | `AppTextures.paperFiber` | background decoration/tokenized asset usage |

4. WHITESPACE AND LAYOUT
   - Use `AppSpacing.grid1`, `grid2`, `grid4`, and `grid8`.
   - Minimum touch target: `44px`.
   - Texture usage must be referenced by tokenized asset aliases, not raw paths scattered in widgets.

================================================================================
PART 2: APP ARCHITECTURE (MVVM)
================================================================================

1. DEPENDENCY STACK
   - Framework: Flutter
   - UI library: Forui
   - State management: Riverpod (app-wide), flutter_hooks (local)
   - Navigation: GoRouter
   - Typography adapter: google_fonts
   - Remote calls: `package:http` behind a repository-owned resilience wrapper
   - Horror Path draft persistence: `shared_preferences` behind a `DraftStore` interface
   - Whitelist authority: `004_EXTERNAL_LIBS_AND_RESOURCES.md`

2. SEPARATION OF CONCERNS
   - View:
     * renders UI
     * owns user interaction wiring
     * contains no business logic
   - ViewModel:
     * owns state mutation, validation, and orchestration
     * persists drafts before risky mutations
   - Data layer:
     * repositories, adapters, API clients

3. DIRECTORY STRUCTURE
   /lib
     /core
       /theme
       /tokens
     /features
       /auth
         /presentation
         /data
     /shared

================================================================================
PART 3: IMPLEMENTATION REFERENCE
================================================================================

/// Generated token output from the active lockfile.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/tokens/app_tokens.g.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final tokens = AppTokens.current;

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: tokens.colors.surface,
      colorScheme: ColorScheme.light(
        primary: tokens.colors.accent,
        surface: tokens.colors.surface,
        onSurface: tokens.colors.textPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.getFont(
          tokens.fonts.displayFamily,
          fontSize: tokens.type.displayXL,
          height: tokens.type.displayLineHeight,
          letterSpacing: tokens.type.displayXLTracking,
          color: tokens.colors.textPrimary,
        ),
        bodyMedium: GoogleFonts.getFont(
          tokens.fonts.bodyFamily,
          fontSize: tokens.type.bodyMD,
          height: tokens.type.bodyLineHeight,
          color: tokens.colors.textMuted,
        ),
      ),
    );
  }
}

class LoginState {
  final String email;
  final bool isLoading;
  final String? error;

  const LoginState({
    this.email = '',
    this.isLoading = false,
    this.error,
  });
}

class LoginViewModel {
  LoginViewModel(this._draftStore, this._repo);

  final DraftStore _draftStore;
  final AuthRepository _repo;

  Future<void> login(LoginDraft draft) async {
    await _draftStore.saveDraft(draft);
    try {
      await _repo.login(draft);
      await _draftStore.clearDraft(draft.key);
    } catch (_) {
      await _draftStore.restoreDraft(draft.key);
      rethrow;
    }
  }
}

================================================================================
PART 4: DATA LAYER AND PERFORMANCE
================================================================================

1. PAGINATION
   - Requirement: keyset/cursor pagination.
   - Pattern: `WHERE id > last_seen_id ORDER BY id LIMIT 20`.

2. LIST RENDERING
   - Requirement: `ListView.builder` or equivalent lazy rendering.

3. SQL SUPPORT RULES
   - Diagnose slow queries with `EXPLAIN (ANALYZE, BUFFERS)`.
   - Avoid `Seq Scan` on large tables.
   - Use B-Tree, GIN, and trigram indexes according to access pattern.

================================================================================
PART 5: PRODUCTION HARDENING AND QA
================================================================================

1. TDD
   - No production code without a failing test first.

2. HORROR PATH
   - Explicitly test DB drops, API failures, and resource exhaustion.
   - Persist recoverable drafts through `DraftStore` before network mutation.
   - Use retry/backoff only where safe.
   - Do not expose raw stack traces.

3. ACCESSIBILITY
   - Interactive elements must meet the `44x44` minimum.
   - Do not rely on color alone for error communication.

4. FINAL REVIEW GATES
   - [ ] Does the UI consume generated token aliases instead of raw literals?
   - [ ] Does the active font pair match the lockfile?
   - [ ] Is business logic decoupled from UI widgets?
   - [ ] Are keyset pagination and lazy rendering in place?
   - [ ] Does the ViewModel persist and restore drafts through `DraftStore`?

5. IDE GUARDRAILS
   - `custom_lint` must fail on banned imports, raw UI color literals, and off-scale typography.
   - `analysis_options.yaml` must be aligned with the active token lockfile and exclusion rules.
