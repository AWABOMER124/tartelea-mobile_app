# Tartelea Android Release APK Report (2026-04-19)

This report documents the exact validation and build steps used to generate a **release-mode** Android APK for testing against production.

## Build Artifact

- APK path: `build/app/outputs/flutter-apk/app-release.apk`
- Size: `89.41 MB` (`93755112` bytes)
- SHA-256: `1785F28FBE45246E4F7D6F33873DD161EF2D724A146BB486D8A2AD711E4FB27A`
- Mode: `--release` (AOT)
- Signing: **Debug certificate** (installable for testing; not Play Store ready without a release keystore)

## Production Endpoints (Hard Requirement)

- API Base URL: `https://api.tartelea.com/api/v1`
- LiveKit WebSocket: `wss://rtc.tartelea.com`

These are the defaults in `lib/core/api/api_config.dart` and can be overridden via `--dart-define` if needed.

## Validation Performed

### 1) Endpoint / Legacy Scan

- No `localhost`, `127.0.0.1`, `traefik.me`, raw IPs, `http://`, or `ws://` found under `lib/`.
- No direct `Supabase` or `Directus` usage in the app code.
- Android manifest explicitly disables cleartext:
  - `android:usesCleartextTraffic="false"`
  - `network_security_config.xml` uses `cleartextTrafficPermitted="false"`

### 2) Static Checks

- `flutter analyze`: **No issues found**
- `flutter test`: **No tests present** in `test/` (Flutter reported no `_test.dart` files)

### 3) Production Reachability Smoke Checks (from this environment)

- `GET https://api.tartelea.com/api/v1/health` -> `200`
- `GET https://api.tartelea.com/api/v1/contents` -> `200`

Important: as of **2026-04-19**, multiple new-domain endpoints required for full feature validation returned non-OK responses on production:

- `GET /community/*` -> `404`
- `GET /sessions` -> `404`
- `GET /plans` -> `404`
- `GET /entitlements/me` -> `404`

Also:

- `GET /subscriptions/me` -> `500` with PostgreSQL error code `22P02`
  - This strongly suggests production currently matches a legacy `/:id` route (treating `me` as an id), not the new `/me` contract.

This blocks end-to-end validation of **Community**, **Sessions (LiveKit join)**, and **Subscriptions/Entitlements** until production backend routes are deployed to match the current backend-first contract.

## Build Commands Used

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

## Notes / Next Actions

- To produce a Play-Store-ready or upgrade-stable APK, provide a real release keystore via `android/key.properties` + a `.jks`, then rebuild.
- For full end-to-end testing on production, ensure the production backend exposes the backend-first routes:
  - `/api/v1/community/*`
  - `/api/v1/sessions/*`
  - `/api/v1/plans`
  - `/api/v1/subscriptions/me`
  - `/api/v1/entitlements/me`

