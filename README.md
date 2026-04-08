# Tartelea Mobile App

Flutter mobile application for the Tartelea platform.

## Stack

- Flutter
- Riverpod
- GoRouter
- Dio
- SharedPreferences
- Supabase Flutter

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
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

## Notes

- `API_BASE_URL` should point to the backend REST API.
- Local secrets should stay in `.env` and must not be committed.
- This repository is the standalone mobile codebase and should not contain backend or web app source.
