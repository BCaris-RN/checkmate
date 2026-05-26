# Checkmate Update Notes - 2026-05-26

Commit covered: `9c0d915` (`Harden release gates and platform metadata`)

## Summary

This update hardens the app for governed release validation, fixes hosted-match timing behavior, and cleans native platform metadata before wider distribution.

## Product Updates

- Hosted LAN matches no longer inherit the local hot-seat pass-device state.
- Hosted turn timing now resets after network-applied moves so the next local host move records the correct elapsed time.
- Replay import now supports queenside castling tokens such as `O-O-O`.
- Replay exports now use platform-safe path joining on desktop and mobile.

## Release and Platform Updates

- Dependency governance now passes with `file_selector` replacing `file_picker`, and `url_launcher` documented in the allowlist.
- Design-token validation now ignores generated/build output and treats the chess set palette catalog as the intentional source of theme colors.
- macOS release builds now include client and server network entitlements for LAN play and analytics calls.
- Android, iOS, macOS, Linux, and Windows metadata now use `com.carisindustries.checkmate` / `Checkmate by Caris` instead of template `com.example` labels.
- Android release signing now uses `android/key.properties` when present; real keystores and signing files are ignored by git.
- Kotlin incremental compilation is disabled for Android builds to avoid cross-drive cache failures on this Windows checkout.

## Verification

- `flutter test`
- `flutter analyze`
- `python scripts/dependency_gate.py .`
- `python scripts/design_token_guard.py --root .`
- `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/enforce_exclusion_zones.ps1 -RootDir .`
- `flutter build apk --debug`
- `flutter build apk --release`
- `flutter build windows --debug`
