# Darazinda Connect — Admin Web Dashboard

A separate Flutter Web app (own `pubspec.yaml`, own deploy target —
e.g. Firebase Hosting) for moderating community-submitted data from the
Darazinda Connect mobile app. It talks to the **same Firebase project**
via `cloud_firestore` / `firebase_auth`.

## What's implemented in this scaffold
- Admin sign-in (email/password via Firebase Auth).
- Overview pane: live counts of users, measurements, reports, schools,
  health facilities.
- Map pane: all measurements plotted with signal-based coloring
  (flutter_map + OpenStreetMap tiles).
- Reports pane: filter by status, update a report's status inline
  (writes are enforced server-side by `firestore.rules` — only accounts
  with the `admin: true` custom claim can actually persist the update).

## What's still needed before production use
- Set the `admin: true` custom claim on admin accounts — this must be
  done server-side (Cloud Function or Admin SDK script), never from the
  client.
- Run `flutterfire configure` inside this directory to generate a real
  `firebase_options.dart` for the web target.
- Operator statistics and probable-dead-zone views mirroring the mobile
  app's `OperatorStatsCalculator` / `DeadZoneAnalyzer`, ideally
  precomputed server-side into the `areas` collection so the dashboard
  doesn't recompute over the full dataset on every load.
- School/health facility list + detail views.
- CSV/PDF export for reports and measurements.
- Pagination for the measurements/reports streams once the dataset
  grows beyond a few thousand documents (`limit()` + cursor).
- Role-based UI (read-only moderator vs. full admin) if the team needs
  more than one access level.

## Running locally
```
cd admin_dashboard
flutter pub get
flutterfire configure   # generates firebase_options.dart for web
flutter run -d chrome
```
