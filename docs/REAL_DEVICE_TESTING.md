# Real Device Testing Checklist — Darazinda Connect

None of the scenarios below have been run against a physical device or
emulator — this development environment has no Android SDK/emulator
and (per this session's network policy) cannot download one from
`dl.google.com`, so only source-level verification (`flutter analyze`,
`flutter test`) has actually been performed. This document is the
checklist to execute on a real machine with Android Studio / a
physical phone before any release. Each row states what to do and what
"pass" looks like, referencing the exact code path being exercised.

## Setup
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutterfire configure          # real Firebase project
flutter run -d <device-id>
```

## Device/OS matrix

| # | Scenario | How to test | Expected result | Code path |
|---|---|---|---|---|
| 1 | Android 10+ | Run on Android 10, 12, and 14 devices/emulators | App installs and runs on all three; runtime permission dialogs (location, phone, camera) appear correctly on each | `AndroidManifest.xml` (`minSdk 23`, `targetSdk 34`) |
| 2 | Low-end device | Run on a 2GB RAM / older CPU device (or throttle an emulator) | UI stays responsive; map scrolling/clustering doesn't freeze the app; no ANRs | `flutter_map_marker_cluster` config in `signal_map_screen.dart` |
| 3 | Dual SIM | Test on a dual-SIM phone with two active SIMs | `TelephonyManager` reports data from the active/default data SIM; app doesn't crash reading a second SIM slot | `MainActivity.kt` `getTelephonyInfo()` |
| 4 | SIM with no data plan | Insert a SIM with calling only, no mobile data | Operator/network type/signal still read correctly (telephony ≠ internet); download/upload/ping show "Not available" if no other connectivity | `SpeedTestService`, `MeasurementRepository.runFullTest` |
| 5 | Weak signal | Test in a basement/rural area with 1-2 signal bars | `signalDbm` reads a real low (very negative) value; UI shows "Weak"/"Very Weak" badge in red/orange, not a crash | `SignalQuality.fromDbm` |
| 6 | No signal | Enable airplane mode, then disable only Wi-Fi (keep cellular radio on but out of range) | Operator/network type show "Not available on this device" if `TelephonyManager` genuinely has nothing; no fabricated value appears anywhere | `TelephonyDataSource.getReading()` |
| 7 | Wi-Fi only (no SIM) | Test on a Wi-Fi-only tablet or a phone with no SIM inserted | Operator/network type/signal show "Not available on this device"; download/upload/ping still work over Wi-Fi | Same as above + `SpeedTestService` |
| 8 | GPS disabled | Turn off Location Services at the OS level, then run a test | `LocationServiceDisabled` state shown with a clear message; no test attempted; app doesn't hang | `LocationService.getCurrentLocation`, `network_test_screen.dart` error branch |
| 9 | Location permission denied | Deny the location permission prompt (once, then permanently) | First denial: `LocationPermissionDenied(isPermanent:false)` message shown, user can retry. Permanent denial: message directs to Android Settings | Same as above |
| 10 | Phone-state permission denied | Deny the `READ_PHONE_STATE` prompt | Operator/network type/signal show "Not available on this device"; GPS/speed test still complete normally | `PermissionService.ensurePhoneStatePermission`, `MainActivity.kt` |
| 11 | Mobile data disabled (Wi-Fi available) | Turn off mobile data, keep Wi-Fi on | Speed test runs over Wi-Fi; telephony reading still reflects the SIM's signal/operator (independent of data being enabled) | `ConnectivityService.isOnline` |
| 12 | Airplane mode | Enable airplane mode fully, run a test | GPS still works (GPS is independent of airplane mode on most devices) if location toggled back on; telephony/speed show "Not available"; measurement still saves locally as Pending Sync | `MeasurementRepository.runFullTest` |
| 13 | Firebase unavailable | Test with `firebase_options.dart` left as placeholder values, or block Firebase hosts at the network level | App boots into offline/demo mode per `main.dart`'s try/catch; guest mode, local measurements, reports, and surveys all still work; sync silently no-ops | `main.dart`, `SyncService.syncPending` |
| 14 | Offline measurement → sync on reconnect | Airplane mode ON, run 2-3 tests, then turn airplane mode OFF | Each test saves locally as "Pending Sync"; within moments of reconnecting, `SyncTrigger` fires and status flips to "Synced" (requires a real Firebase project) | `SyncTrigger`, `SyncService.syncPending` |
| 15 | Intermittent connectivity | Toggle Wi-Fi on/off repeatedly during a sync pass | No duplicate Firestore documents (writes are `.set()` on the report/measurement's own deterministic ID, so a retry overwrites rather than duplicates); failed items retry with incrementing `attemptCount` | `SyncService._pushMeasurement` / `_pushReport` |
| 16 | Photo upload | Submit a report with a photo, online | Photo uploads to Firebase Storage under `report_photos/{reportId}/`; `photoRemoteUrl` populates; report doc isn't marked synced until the photo upload succeeds | `SyncService._uploadReportPhoto` |
| 17 | Photo upload failure | Submit a report with a photo, then kill connectivity mid-upload | Report stays "Pending Sync" (not silently dropped); retried on next connectivity event; no crash | Same as above, via `syncPending`'s per-item catch block |
| 18 | Map loading failure | Test with OpenStreetMap tile server unreachable (block `tile.openstreetmap.org`) | Map shows blank/grey tiles but the rest of the screen (legend, filter button, empty-state text) stays usable; no crash | `signal_map_screen.dart` `TileLayer` |
| 19 | Large datasets | Seed several thousand measurements (locally via test data, or against a Firestore emulator) | Marker clustering keeps the map responsive; if dead-zone analysis (`O(n²)` proximity clustering) becomes visibly slow past ~10-20k points, see the geohash-bucketing note in `docs/ARCHITECTURE.md` | `DeadZoneAnalyzer._clusterByProximity` |
| 20 | Android back navigation | Navigate Dashboard → Network Test → (mid-test) → back; also Dashboard → Report → back; repeat a few screens deep | Back always returns to the previous screen via `go_router`'s stack; no duplicate screens, no crash; an in-progress test is abandoned cleanly (no orphaned state) | `core/routing/app_router.dart` |
| 21 | Urdu RTL | Settings → Language → Urdu, then navigate every screen | Text direction flips app-wide; forms, buttons, and cards remain legible and usable. The map legend and a couple of right-aligned labels were switched to direction-aware widgets (`PositionedDirectional`, `AlignmentDirectional`, `TextAlign.end`) — verify they actually mirror correctly on a real RTL layout, since this was fixed by static review, not visually tested on-device | `core/localization/*`, `signal_map_screen.dart` `_Legend`, `my_reports_screen.dart`, `dead_zone_list_screen.dart` |
| 21b | Urdu PDF export | Export a PDF report while the app is set to Urdu | **Known gap**: `PdfReportGenerator` renders report PDFs in English only, left-to-right, regardless of the app's language setting — Urdu PDF text/RTL layout is not implemented. Confirm this is acceptable for initial release or scope it as follow-up work | `pdf_report/data/pdf_report_generator.dart` |
| 22 | Firebase Crashlytics | Force a test crash (`FirebaseCrashlytics.instance.crash()` behind a debug-only button, or an uncaught exception) in a release build | Crash appears in the Firebase Console within a few minutes | `main.dart` `FlutterError.onError` wiring |
| 23 | Duplicate report guard | Submit the same problem category twice within 5 minutes at the same spot | Second submission shows a "Similar report already submitted" confirmation dialog before proceeding | `ReportRepository.findLikelyDuplicate` |
| 24 | Test cancellation | Start a network test, tap "Cancel Test" during the download/upload phase | Test stops immediately; "Test cancelled. No measurement was saved." shown; no partial/fake measurement is written | `NetworkTestNotifier.cancelTest`, `MeasurementRepository.cancelRunningTest` |
| 25 | PDF generation | Export a PDF from "My Reports" for a report with and without a linked measurement | PDF renders correctly in both cases; missing metrics show "Not available on this device" rather than blank fields or a crash | `PdfReportGenerator.generate` |
| 26 | Data deletion | Settings → Delete Account/Data, confirm | All local Drift tables are cleared; app returns to a fresh state; confirm this does NOT claim server-side data was deleted (it doesn't touch Firestore) | `settings_screen.dart` `_confirmDeleteData` |

## Known gaps to watch for while testing

- The signal map / statistics / dead-zone / operator-comparison
  screens now read a **combined local + community (Firestore)**
  dataset (`combinedMeasurementsProvider`). On first real-device test,
  confirm the community half actually populates once a second test
  device syncs data — this is the part that cannot be verified without
  two real devices and a real Firebase project.
- `SpeedTestService` hits two public third-party endpoints
  (`speed.hetzner.de`, `httpbin.org`) — confirm both are reachable from
  the field-test network; if either is blocked/rate-limited in
  practice, swap `AppConstants.speedTestDownloadUrl` /
  `speedTestUploadUrl` for owned infrastructure before wide rollout.
- Battery/data usage over a multi-hour field session has not been
  profiled on a real device — do this before large-scale community
  deployment (see "Performance" in `docs/QA_CHECKLIST.md`).
