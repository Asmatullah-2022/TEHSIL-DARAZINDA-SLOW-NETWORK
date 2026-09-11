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

**Phase 2 update:** a real Flutter SDK (3.24.5 stable / Dart 3.5.4) was
installed in the working environment and used to genuinely verify this
codebase — not simulated:

- `flutter pub get` — resolves cleanly.
- `dart run build_runner build` — generates Drift's database code
  successfully (202 outputs).
- `flutter analyze` — **No issues found.**
- `flutter test` — **All 11 tests passed** (dead-zone analysis,
  operator statistics, signal-quality mapping).
- `flutter build apk`/`appbundle` — **not run**: this session's egress
  network policy blocks `dl.google.com`, so the Android SDK could not
  be downloaded here. Nothing about a successful APK/AAB build is
  claimed. See [`docs/QA_CHECKLIST.md`](docs/QA_CHECKLIST.md) for the
  exact commands to run this yourself with Android Studio installed.

**Phase 3 (current):** getting the app running on a real Android phone
with a real Firebase project. Start with
[`docs/LOCAL_ANDROID_SETUP.md`](docs/LOCAL_ANDROID_SETUP.md) (Windows,
beginner-friendly) if you don't already have Flutter/Android Studio on
your own computer, then fill in
[`docs/REAL_PHONE_TEST_REPORT.md`](docs/REAL_PHONE_TEST_REPORT.md) once
you can run the app on a device. Play Store signing/release
(`docs/PLAY_STORE_PREP.md`) is Phase 4 — not yet.

That verification pass also caught and fixed several real bugs that
existed in the original scaffold — among them: `READ_PHONE_STATE` was
declared in the manifest but never actually requested at runtime (so
operator/signal data would never have worked on a real device), three
screens referenced an unimported provider, a Gradle Firebase plugin
would have hard-failed the build with no `google-services.json`
present, no launcher icon resources existed at all, and the Signal
Map/Statistics/Dead-Zone/Operator-Comparison screens only ever read
the local on-device database — never Firestore — so the "community"
map never actually showed community data. All are fixed; see git
history and `docs/ARCHITECTURE.md` for detail.

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
| Firestore security rules + Storage rules + data model docs | ✅ |
| Community data on the mobile app (Signal Map / Statistics / Operator Comparison / Dead Zones read real Firestore data, not just local) | ✅ |
| Report photo upload to Firebase Storage on sync | ✅ |
| Duplicate-report guard, test cancel/bandwidth cap on speed test | ✅ |
| Admin web dashboard (separate Flutter Web app) | 🟡 Functional scaffold with loading/error/empty states — overview, map, report moderation done; exports/pagination/roles are next (see `admin_dashboard/README.md`) |
| Cloud Functions (`setAdminClaim`, server-side dead-zone precomputation) | ✅ Written (`functions/`), not deployed — needs a real Firebase project |
| Firebase Crashlytics/Analytics wiring | ✅ Wired (`main.dart`, `core/services/analytics_service.dart`, router screen-view observer); needs a real Firebase project via `flutterfire configure` to actually report |
| Play Store release config | 🟡 Manifest/Gradle scaffolded, launcher icons generated; signing, store listing, screenshots still pending — see `docs/PLAY_STORE_PREP.md` |
| Automated tests | 🟡 Pure-logic unit tests **verified passing** (`flutter test`) for `DeadZoneAnalyzer`, `OperatorStatsCalculator`, `SignalQuality`; widget/integration tests not yet written |
| APK/AAB build | ⬜ Not run — Android SDK unavailable in this environment (network-policy blocked); see `docs/QA_CHECKLIST.md` |

## Getting started (in a real Flutter environment)

```bash
flutter --version   # verified against Flutter 3.24.5 / Dart 3.5.4 stable
flutter pub get

# Generate Drift's *.g.dart:
dart run build_runner build --delete-conflicting-outputs

# Connect to a real Firebase project (creates real firebase_options.dart,
# google-services.json, GoogleService-Info.plist):
dart pub global activate flutterfire_cli
flutterfire configure

flutter analyze
flutter test
flutter run
```

> **Flutter version note:** `pubspec.yaml`'s `intl: ^0.19.0` pin is
> intentional and matches `flutter_localizations`' requirement on
> Flutter 3.24.x. On a much newer Flutter/Dart SDK you may need to
> bump it (`flutter pub add intl:^0.20.3` or whatever the resolver
> suggests). Also: as of this writing, `drift_dev` (via its pinned
> `analyzer` version) cannot parse code under Dart SDKs that already
> use the newer "dot shorthand" syntax internally — if `build_runner`
> crashes with `Missing implementation of
> visitDotShorthandPropertyAccess`, that's this issue; either wait for
> an updated `drift_dev`/`analyzer` release, or build against Flutter
> 3.24.x–3.29.x-ish as used here. This is an upstream ecosystem
> limitation, not a bug in this codebase.

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
firestore/          # firestore.rules, firestore.indexes.json
storage/            # storage.rules (report photos)
functions/          # Cloud Functions: admin claims, dead-zone precomputation
docs/               # architecture, data model, QA checklist, Play Store prep,
                    # real-device testing checklist
admin_dashboard/    # separate Flutter Web app for moderators/admins
test/               # unit tests for pure business logic
firebase.json / .firebaserc   # Firebase CLI project config (placeholder project ID)
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
