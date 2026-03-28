# checkmate_by_caris

Checkmate by Caris is a governed Flutter match room for local hot-seat play and LAN host/join play.

## What It Does

- Starts a local match on one device.
- Hosts a match over the local network.
- Joins a host, synchronizes state, and submits moves remotely.
- Persists match state with `shared_preferences`.
- Applies design tokens and guardrails through the repo scripts.

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
