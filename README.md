# Darazinda Connect
### Tehsil Darazinda Slow Network — Signal Mapping & Complaint App

**Measure • Map • Report • Improve Connectivity**

Darazinda Connect is a civic-technology Flutter app for Darazinda
Tehsil. It measures real cellular network conditions (signal, speed,
latency), records where they were measured, builds a community signal
map, detects **probable** connectivity problem areas from repeated
evidence, and lets citizens submit evidence-based reports.

> **Darazinda Connect does not "boost" cellular signal.** No Android
> app can. This app is an evidence-collection and reporting platform,
> not a signal amplifier.

---

## Project status

This repository currently contains a **complete architectural
scaffold with production-quality, genuinely functional feature code**
for the core measurement → map → report → PDF loop, plus the offline
sync engine and Firestore data model. It has **not** been built or run
against a live Flutter SDK — this development environment has no
Flutter/Dart toolchain installed, so `flutter analyze`, `flutter test`,
and `flutter build` could not be executed here. See
[`docs/QA_CHECKLIST.md`](docs/QA_CHECKLIST.md) for exactly what has and
has not been verified, and run the commands there in a real Flutter
environment before shipping.

Nothing in this codebase fabricates signal strength, speed, or operator
data — see [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) → "No fake
data policy".

## What's implemented

| Area | Status |
|---|---|
| Clean architecture project structure (core / features, data-domain-presentation) | ✅ |
| Design system (Material 3, blue/cyan identity, signal-quality color scale) | ✅ |
| English + Urdu localization with RTL | ✅ |
| Splash, onboarding, guest/email auth, dashboard | ✅ |
| Real Android telephony reading (Kotlin platform channel: operator, network type, signal dBm/ASU) | ✅ |
| GPS capture with explicit permission/denial/timeout states | ✅ |
| Real download/upload/ping measurement (no simulated numbers) | ✅ |
| Offline-first local database (Drift) + generic sync queue | ✅ |
| Firestore sync service (push on reconnect) | ✅ |
| Signal map (OpenStreetMap via flutter_map, clustering, filters) | ✅ |
| Probable dead-zone analysis (repeated-measurement threshold, never single-sample) | ✅ |
| Report Problem form (auto-attaches GPS/operator/measurement, unique report ID) | ✅ |
| My Reports + status tracking | ✅ |
| PDF evidence report generator | ✅ |
| Operator comparison (minimum sample size before ranking) | ✅ |
| Community statistics | ✅ |
| School & health facility surveys | ✅ |
| Settings (language, privacy, delete local data) | ✅ |
| Firestore security rules + data model docs | ✅ |
| Admin web dashboard (separate Flutter Web app) | 🟡 Functional scaffold — overview, map, report moderation done; exports/pagination/roles are next (see `admin_dashboard/README.md`) |
| Cloud Functions (server-side dead-zone precomputation, admin claim assignment) | ⬜ Not started — documented as required in `docs/ARCHITECTURE.md` |
| Firebase Crashlytics/Analytics wiring | 🟡 Hooked in `main.dart`; needs a real Firebase project via `flutterfire configure` |
| Play Store release config | 🟡 Manifest/Gradle scaffolded; signing, store listing, screenshots pending — see `docs/PLAY_STORE_PREP.md` |
| Automated tests | 🟡 Pure-logic unit tests written for `DeadZoneAnalyzer`, `OperatorStatsCalculator`, `SignalQuality` (see `test/`); widget/integration tests not yet written |

## Getting started (in a real Flutter environment)

```bash
flutter --version   # requires Flutter 3.22+ / Dart 3.3+
flutter pub get

# Generate Drift's *.g.dart and any Freezed/JSON codegen:
flutter pub run build_runner build --delete-conflicting-outputs

# Connect to a real Firebase project (creates real firebase_options.dart,
# google-services.json, GoogleService-Info.plist):
dart pub global activate flutterfire_cli
flutterfire configure

flutter analyze
flutter test
flutter run
```

The admin dashboard is a **separate** Flutter Web project:
```bash
cd admin_dashboard
flutter pub get
flutterfire configure
flutter run -d chrome
```

## Repository layout

```
lib/
  core/            # theme, constants, routing, localization, database,
                    # network, services (GPS/speed test), shared widgets
  features/
    splash/ onboarding/ auth/ dashboard/
    network_test/        # measurement engine
    signal_map/           # map + filters
    dead_zone/             # probable dead-zone analysis
    report_problem/ report_status/ pdf_report/
    operator_comparison/ statistics/
    school_survey/ health_survey/
    settings/ sync/
android/            # Kotlin platform channel (TelephonyManager), manifest
firestore/          # firestore.rules
docs/               # architecture, data model, QA checklist, Play Store prep
admin_dashboard/    # separate Flutter Web app for moderators/admins
test/               # unit tests for pure business logic
```

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full
technical rationale and [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md) for
Firestore collections.

## Privacy & permissions

Darazinda Connect requests only: `INTERNET`, `ACCESS_NETWORK_STATE`,
`ACCESS_FINE_LOCATION`/`ACCESS_COARSE_LOCATION`, `READ_PHONE_STATE`,
and `CAMERA`/`READ_MEDIA_IMAGES` (for the optional report photo). It
never requests contacts, SMS, or call-log permissions, and never runs
background location tracking. See `android/app/src/main/AndroidManifest.xml`
for the exact list with rationale comments, and
[`docs/PLAY_STORE_PREP.md`](docs/PLAY_STORE_PREP.md) for the permission
disclosure text used in the Play Store listing.
