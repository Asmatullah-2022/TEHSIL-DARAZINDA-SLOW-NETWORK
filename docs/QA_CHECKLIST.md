# QA Checklist — Darazinda Connect

**Update (Phase 2, re-verified in Phase 3):** sections 1 and 2 below
have now genuinely been run twice, in a temporary Flutter 3.24.5 /
Dart 3.5.4 install inside this environment — not simulated. Results
are inlined below each command. Section 4 (release build) has **not**
been run: `flutter build apk --debug` was attempted in Phase 3 and
failed immediately with `No Android SDK found` — this session's
network policy blocks `dl.google.com`, so the Android SDK cannot be
installed here. Sections 3 (manual device testing) and 4 still require
a real machine/device — see `docs/LOCAL_ANDROID_SETUP.md` (Windows
setup) and `docs/REAL_PHONE_TEST_REPORT.md` (device test template).

## 1. Static analysis
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```
**Result at last verification: `flutter analyze` → "No issues found!"**
(after fixing several real errors this pass surfaced — see git history
around the Phase 2 commit — including a `locationServiceProvider`
import missing in three screens, a Geolocator API mismatch, and a
`CardThemeData` vs `CardTheme` Flutter-version mismatch).

Before analyzing: Drift codegen must run first (`*.g.dart` files are
gitignored, see `.gitignore`) or every file importing
`app_database.dart` will show unresolved `part` errors. Note also:
`riverpod_generator`/`freezed`/`json_serializable` were removed from
`pubspec.yaml` — they were unused dead dependencies and, at the time
of this check, crashed against this Flutter SDK's newer Dart syntax
(see the version note in the main README). Only `drift_dev` codegen
runs now.

## 2. Automated tests
```bash
flutter test
```
**Result at last verification: All 11 tests passed.**

Currently covered (pure Dart logic, no Flutter bindings needed beyond
`flutter_test`):
- `test/core/signal_quality_test.dart` — dBm → quality bucket mapping,
  null-safety of the "not available" path.
- `test/features/network_test/dead_zone_analyzer_test.dart` — a single
  poor measurement is never flagged; clustering by proximity; the
  minimum-sample and poor-ratio thresholds.
- `test/features/operator_comparison/operator_stats_calculator_test.dart`
  — averages ignore null samples; small sample sizes are flagged
  insufficient rather than silently ranked.

Not yet written (do before release):
- Widget tests for `NetworkTestScreen` (idle/running/error/result
  states) and `ReportProblemScreen` (validation, submission).
- Integration test for the full offline → sync round trip using a
  fake/in-memory Firestore.
- Golden tests for RTL (Urdu) layout on at least the dashboard and
  onboarding screens.

## 3. Manual test matrix

| Scenario | How to test | Expected |
|---|---|---|
| Offline mode | Enable airplane mode, run a network test | Measurement saves locally, shows "Pending Sync"; download/upload/ping show "Not available on this device" (no fake numbers) |
| Sync on reconnect | Disable airplane mode after the above | `SyncService.syncPending()` runs via `SyncTrigger`; status flips to "Synced" |
| Permission denial (location) | Deny location permission when prompted | `LocationPermissionDenied` surfaces a specific, actionable message; app does not crash or guess a location |
| Permission denial (phone state) | Deny `READ_PHONE_STATE` | Operator/network type/signal show "Not available on this device"; test still completes using whatever GPS/speed data is available |
| GPS unavailable | Disable location services at the OS level | `LocationServiceDisabled` message shown; no test run attempted |
| GPS timeout | Test indoors with poor GPS reception | `LocationTimedOut` message after ~20s, suggests trying outdoors |
| Network unavailable mid-test | Kill connectivity during download/upload leg | Ping/download/upload return null gracefully; GPS + telephony data still saved |
| Android back navigation | Navigate several screens deep, press back repeatedly | Returns through the `go_router` stack correctly, no crash, no duplicate screens |
| Urdu RTL | Settings → Language → Urdu | Text direction flips, all screens remain legible and usable, no clipped/overlapping text |
| Low-end device | Test on a 2GB RAM / Android 7 (API 23, the app's `minSdk`) device | App remains responsive; map/list scrolling doesn't jank badly |
| Map loading failure | Test with OSM tile server unreachable | Map shows blank/grey tiles gracefully, rest of the screen (legend, filters) remains usable, no crash |
| Firebase failure | Test with `firebase_options.dart` left as placeholder values | App boots in offline/demo mode per the `try/catch` in `main.dart`; guest mode + local storage fully functional |
| PDF generation | Submit a report, export PDF from "My Reports" | PDF renders report ID, category, GPS, operator/network, and the non-official-submission disclaimer |
| Large datasets | Seed several thousand local measurements | Map clustering (`flutter_map_marker_cluster`) keeps the map responsive; dead-zone analysis (`O(n^2)` proximity clustering) may need the geohash optimization noted in `docs/ARCHITECTURE.md` past ~10-20k points |

## 4. Release build sanity

**Not run in this environment.** This session's egress network policy
blocks `dl.google.com` (403, organization policy), so the Android SDK
could not be downloaded and no `flutter build` command targeting
Android could be attempted here. `flutter analyze`/`flutter test` were
still genuinely run and pass (sections 1-2) since those don't need the
Android SDK. Run the following yourself with Android Studio / the
Android SDK installed:

```bash
flutter build apk --debug      # sanity check first — no signing needed
flutter build apk --release
flutter build appbundle --release
```
Before running the `--release` commands: replace the debug signing
config in `android/app/build.gradle` with a real release keystore (see
`docs/PLAY_STORE_PREP.md`), and confirm `firebase_options.dart` /
`android/app/google-services.json` are the real, `flutterfire
configure`-generated files (not the placeholders committed here) — or
the app will fall back to the offline/demo-mode path in `main.dart`
rather than actually using Firebase. Note: `google-services.json`'s
absence no longer breaks the Gradle build itself (the Firebase Gradle
plugins are applied conditionally — see the comment in
`android/app/build.gradle`); it only means Firebase features won't
work in that build, which is expected and safe for local iteration.
