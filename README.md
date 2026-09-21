# Tartelea Mobile App

Flutter mobile application for the Tartelea platform.

## Stack

- Flutter
- Riverpod
- GoRouter
- Dio
- Secure credential storage (see auth implementation)

## Setup

1. Install Flutter dependencies:

```bash
flutter pub get
```

2. Create your local environment file if needed:

```bash
cp .env.example .env
```

3. Run the app against the backend API:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://api.tartelea.com/api/v1 \
  --dart-define=LIVEKIT_API_BASE_URL=wss://rtc.tartelea.com \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-oauth-client-id>
```

## Notes

- `API_BASE_URL` should point to the backend REST API.
- `LIVEKIT_API_BASE_URL` should point to the LiveKit WebSocket endpoint (wss).
- Local secrets should stay in `.env` and must not be committed.
- This repository is the standalone mobile codebase and should not contain backend or web app source.


## Google Sign-In (Android)

The Android application ID is `com.tartelea.app`.

For each debug/release signing certificate:
1. Register `com.tartelea.app` and its SHA-1/SHA-256 fingerprints in the Google/Firebase project.
2. Use the OAuth **Web client ID** as `GOOGLE_SERVER_CLIENT_ID` when building the app.
3. Configure the backend `GOOGLE_CLIENT_ID` to the same Web client ID so the backend verifies the token audience expected from the mobile app.
4. Never commit OAuth client secrets or signing keystores.

Example:

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-oauth-client-id>
```

A Google `PlatformException(sign_in_failed)` that occurs before `POST /auth/google` reaches the backend normally indicates Android package/signing/OAuth configuration, not a database failure.
