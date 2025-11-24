# LigaPass Mobile
Flutter client for LigaPass that consumes the Django `matches` API (`/matches/api/calendar/`) and renders the match calendar, filters, pagination, and details UI.

## Setup
1) Install dependencies: `flutter pub get`
2) Ensure Django is running: `python manage.py runserver 8000` (already running per your note).
3) Configure API base URL:
   - Web / desktop / iOS simulator default: `http://localhost:8000` (auto).
   - Android emulator default: `http://10.0.2.2:8000` (auto).
   - Override for real devices/LAN: `--dart-define API_BASE_URL=http://<your-ip>:8000`.

### Run
```bash
flutter run \
  --dart-define API_BASE_URL=http://localhost:8000
```

## What’s wired
- Data layer (models, filter, pagination) mapped to Django JSON shape from `/matches/api/calendar/`.
- API client + repository + ChangeNotifier state for loading, filtering (search, status, date range, per-page), pagination.
- UI: match list with status badges, team logos, venue info, pagination controls, and a detail page using the fetched data.

## Django notes (no files changed here)
- The current calendar API does **not** expose match `api_id`, ticket prices, or a JSON detail endpoint.  
  - If you need live score (`/matches/api/live-score/<api_id>/`) in the app, add `api_id` to the calendar response or expose a detail API that includes it.
  - If you need ticket prices/venue lists or per-match reviews in mobile, add JSON endpoints for those resources.
