# howdy_site

Single-page placeholder website for Howdy (Flutter Web).

## Run (Web)

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5000 --dart-define=EMAIL_CAPTURE_PATH=/site/waitlist
```

## Deploy (Release build)

```bash
flutter build web --dart-define=API_BASE_URL=https://your-api --dart-define=EMAIL_CAPTURE_PATH=/site/waitlist
# Output: build/web
```

## Configure

- API_BASE_URL: Base URL of your Howdy backend (e.g., `https://api.howdy.it.com`).
- EMAIL_CAPTURE_PATH: Path for email capture endpoint (POST with JSON: `{ "email": "user@example.com" }`).

## Notes

- Logo is in `assets/howdy2.svg`.
- Primary color uses Howdy’s orange brand `#EE8C0D`.
