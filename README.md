# checkmate_by_caris

Checkmate by Caris is a governed Flutter chess platform built to deliver real chess play, unlockable 2.5D themed sets, and audited release paths that can ship safely from GitHub.

## Why It Exists

- Turn a playable chess product into a governed release system instead of a loose prototype.
- Keep the board, rules, themes, and delivery paths aligned across web, Windows, Android, and LAN play.
- Use Caris / Phoenix controls to make AI-assisted development deterministic, inspectable, and safe to release.

## What It Does

- Starts a local match on one device.
- Hosts a match over the local network.
- Joins a host, synchronizes state, and submits moves remotely.
- Lets the browser build host and join matches between tabs in the same browser profile.
- Renders a real chess board with white-view coordinates and visible pieces.
- Unlocks themed chess sets as you level up.
- Persists match state with `shared_preferences`.
- Applies design tokens and guardrails through the repo scripts.

## Play and Download on GitHub

- The repository now has a GitHub Actions workflow that builds the web app and publishes it to a `gh-pages` branch.
- Once GitHub Pages is pointed at that branch in repo settings, the browser build will be playable from GitHub at `https://BCaris-RN.github.io/checkmate/`.
- The same workflow uploads the web build and Windows release as downloadable artifacts in GitHub Actions.
- Web builds use the `/checkmate/` base path so the app works correctly when served from the repository subpath.
- In the browser, host/join play works between tabs in the same browser profile by sharing the invite link or room code.

## Run

```powershell
flutter pub get
flutter test
flutter analyze
python scripts/dependency_gate.py .
python scripts/design_token_guard.py --root .
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/enforce_exclusion_zones.ps1 -RootDir .
```

## Notes

- `publish_to: none` keeps the package private.
- The private Caris stack content lives locally under `.caris_stack/` and is excluded from GitHub.
- The exclusion gate now fails closed without depending on `rg`.
