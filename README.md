# checkmate_by_caris

Checkmate by Caris is a governed Flutter chess board with unlockable 2.5D sets for local hot-seat play and LAN host/join play.

## What It Does

- Starts a local match on one device.
- Hosts a match over the local network.
- Joins a host, synchronizes state, and submits moves remotely.
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
- The repo includes a semantic bundle and governance templates for downstream automation.
- The exclusion gate now fails closed without depending on `rg`.
