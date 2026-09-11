# QA Checklist — Darazinda Connect

**Important**: this codebase was written in a sandboxed environment
with no Flutter/Dart SDK installed, so none of the commands or manual
tests below have actually been executed against this code yet. Nothing
in this document should be read as "verified" — it is the checklist to
run through in a real Flutter environment before any release, ordered
the way the project brief requires (analyze → tests → manual → release).

## 1. Static analysis
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
```
Expect to fix: Drift/Freezed codegen must run first (`*.g.dart` files
are gitignored, see `.gitignore`) or every file importing
`app_database.dart` will show unresolved `part` errors.

## 2. Automated tests
```bash
flutter test
```
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
```bash
flutter build apk --release
flutter build appbundle --release
```
Before running these: replace the debug signing config in
`android/app/build.gradle` with a real release keystore (see
`docs/PLAY_STORE_PREP.md`), and confirm `firebase_options.dart` /
`google-services.json` are the real, `flutterfire configure`-generated
files (not the placeholders committed here).
