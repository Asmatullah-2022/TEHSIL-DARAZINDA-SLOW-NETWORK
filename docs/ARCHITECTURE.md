# Architecture — Darazinda Connect

## Layering (clean architecture, feature-based)

Each feature under `lib/features/<name>/` follows, where it has enough
complexity to warrant it:

```
data/         # datasources (platform channels, HTTP), repositories,
               # DTO <-> entity mapping
domain/       # entities, enums, pure business rules (no Flutter/Firebase imports)
presentation/ # screens, widgets, Riverpod providers/state notifiers
```

`lib/core/` holds everything cross-cutting: theme, routing, the Drift
database, localization, and small platform-facing services
(`LocationService`, `SpeedTestService`, `ConnectivityService`) that
multiple features share.

State management is **Riverpod** (`flutter_riverpod`) chosen for:
compile-time-safe DI without a service locator, first-class support for
`StreamProvider`/`FutureProvider` (a natural fit for a Drift `.watch()`
stream feeding straight into the UI), and no BuildContext coupling in
business logic.

## Offline-first data flow

Every write (measurement, report, school/health survey) follows the
same shape:

```
User action
  -> Repository.saveLocally()      (Drift insert, always succeeds if the
                                     device has disk space)
  -> Repository.enqueueForSync()   (row in sync_queue)
  -> UI reflects "Pending Sync" immediately, no network wait
  -> SyncTrigger (listens to ConnectivityService) fires
     SyncService.syncPending() when the device comes back online
  -> Each queued item is pushed to Firestore; on success the source
     row's syncStatus flips to "synced" and the queue row is deleted;
     on failure the queue row's attemptCount increments and it is
     retried on the next connectivity event.
```

This means the app is **fully usable with zero connectivity** — the
entire measurement/report/survey flow only touches the local SQLite
database (via Drift) until a sync pass runs. Firestore/Firebase Auth
being unconfigured (see `firebase_options.dart` placeholder) does not
block any local functionality; only sign-in and sync are affected, and
both degrade gracefully to "guest mode, local-only".

## No fake data policy

This is enforced structurally, not just by convention:

- `TelephonyReading`, `Measurement`, and every survey entity model
  every OS-sourced field as **nullable**. There is no default value
  path that substitutes a number for a missing reading.
- `MetricTile` (the canonical way any measurement value is rendered)
  requires an explicit `value` and renders "Not available on this
  device" whenever it is null — there is no code path that silently
  drops a missing metric or invents a placeholder.
- `SpeedTestService` measures real transferred bytes over wall-clock
  time against public endpoints; any failure returns `null`, never a
  randomized or estimated number.
- `AppConstants.demoModeDefault` is `false`, and
  `AppConstants.isDemoModeAllowed` is hard-wired to `false` in release
  builds (`bool.fromEnvironment('dart.vm.product')`). Any future demo
  data path must gate on this and must never be reachable in a
  production build.
- Dead-zone labeling never fires on a single measurement — see
  `DeadZoneAnalyzer` and `AppConstants.deadZoneMinMeasurements` /
  `deadZonePoorSignalRatio`. The label used everywhere is "Probable
  Connectivity Problem", never "confirmed" or "permanent".
- Report submission never claims the report was sent to a telecom
  operator or government authority — see the disclaimer text in
  `ReportProblemScreen` and `PdfReportGenerator`. That would require a
  real, documented integration (none exists in this codebase).

## Why OpenStreetMap (flutter_map) instead of Google Maps

A civic-tech project for a specific Tehsil doesn't need Google's
commercial map feature set, and flutter_map + OpenStreetMap tiles:
- requires no API key or billing account (important for a
  community-maintained public-interest app),
- is ODbL-licensed, which is compatible with redistributing derived,
  aggregated public data (the whole point of the signal map),
- has first-class marker clustering (`flutter_map_marker_cluster`) for
  the dataset sizes this app will realistically see.

If usage ever needs Google-specific features (Street View, Places
autocomplete), that's a swap at the `signal_map` feature boundary only
— nothing else in the app depends on the map provider.

## Extending to phone authentication

`AuthRepository` already isolates every Firebase Auth call. Adding
phone auth means adding `signInWithPhoneNumber` /
`verifySmsCode` methods there and a corresponding screen under
`features/auth/presentation/screens/` — no changes needed anywhere else
(guest mode, sync, and every other feature only depend on
`FirebaseAuth.instance.currentUser?.uid`, which is null-safe by
construction already).

## Extending to all of Pakistan

Nothing in the data model or clustering logic is Tehsil-specific except
the default map center (`AppConstants.defaultMapLat/Lng`) and the
proximity-clustering radius, which is a flat constant appropriate at
Tehsil scale. Scaling nationally would mean:
1. Replacing the greedy O(n²) proximity clustering in
   `DeadZoneAnalyzer` with a geohash-bucketed approach (still pure
   Dart, no architecture change) once measurement counts grow past
   roughly tens of thousands.
2. Adding an `areas`/region hierarchy (province → district → tehsil)
   to the `measurements`/`reports` documents so the admin dashboard and
   statistics screens can filter by region — the Firestore schema in
   `docs/DATA_MODEL.md` already reserves an `areas` collection for
   this.
3. Moving dead-zone aggregation to a scheduled Cloud Function instead
   of on-device recomputation, writing precomputed results into
   `areas` for both the mobile map and the admin dashboard to read
   cheaply.

## Server-side work not yet implemented

- **Cloud Functions**: (a) assign the `admin: true` custom claim to
  vetted accounts, (b) periodically recompute `areas` (probable dead
  zones) over the full community dataset, (c) optionally generate
  thumbnail/compressed versions of report photos on upload to Storage.
- **App Check**: recommended before opening `create` rules on
  `schools`/`health_facilities` to unauthenticated clients, to curb
  spam without requiring every citizen to create an account.
