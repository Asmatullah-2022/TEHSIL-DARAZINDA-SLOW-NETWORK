# Data Model — Darazinda Connect

Firestore is the source of truth once data syncs; the on-device Drift
database (`lib/core/database/app_database.dart`) mirrors the same shape
so the app is fully usable offline. Collections below map 1:1 to the
Drift tables of the same purpose.

## `users/{uid}`
Private, owner-readable only.
| Field | Type | Notes |
|---|---|---|
| email | string | from Firebase Auth |
| displayName | string? | optional |
| createdAt | timestamp | |
| role | string | `citizen` \| `admin` (custom claim mirrors this) |

## `measurements/{measurementId}`
Public read, append-only from clients. **Never contains any account
identifier** — see "Privacy model" below. Firestore rules
(`hasOnly()`) reject a write containing any field not in this list, so
this table is the actual enforced contract, not just documentation.
| Field | Type | Notes |
|---|---|---|
| anonymousDeviceId | string | random UUID, not a hardware ID, not tied to any account |
| location | GeoPoint | required |
| gpsAccuracyMeters | number? | |
| operator | string? | `null` = not available on device |
| networkType | string? | 2G/3G/4G (LTE)/5G/Unknown |
| signalDbm | number? | |
| signalAsu | number? | |
| downloadMbps | number? | |
| uploadMbps | number? | |
| pingMs | number? | |
| measuredAt | timestamp | client-recorded measurement time |
| isDemoData | boolean | always `false` outside dev builds |
| createdAt | timestamp | server timestamp on write |

## `measurement_owners/{measurementId}` — private
Same document ID as its `measurements/{measurementId}` counterpart, so
the two are trivially joinable server-side or by the owner/an admin,
but **never** publicly readable (`firestore.rules` restricts read to
`ownerUid == request.auth.uid` or an admin). Written by the client
only when the submitter was signed in — guests never get one.
| Field | Type | Notes |
|---|---|---|
| ownerUid | string | the submitter's real Firebase UID |
| anonymousDeviceId | string | joins back to the public document |
| createdAt | timestamp | |

## `reports/{reportId}`
Public read; status only editable by admins; description/photo
editable by the verified owner (see `report_owners` below) while
status is unchanged. **Never contains any account identifier** — same
`hasOnly()` enforcement as `measurements`.
| Field | Type | Notes |
|---|---|---|
| anonymousDeviceId | string | |
| category | string | `ProblemCategory` enum name |
| description | string? | |
| photoUrl | string? | Firebase Storage download URL |
| location | GeoPoint | |
| operator | string? | auto-attached from latest measurement |
| networkType | string? | |
| linkedMeasurementId | string? | |
| signalDbm / downloadMbps / uploadMbps / pingMs | number? | snapshot of the linked measurement at submission time |
| gpsAccuracyMeters | number? | |
| status | string | pending / underReview / inProgress / resolved / closed |
| createdAt | timestamp | |
| updatedAt | timestamp | |

## `report_owners/{reportId}` — private
Same shape and purpose as `measurement_owners`, for reports. This is
what `firestore.rules`' owner-edit rule actually checks (via `get()`)
— the public `reports` document itself carries no ownership signal.
| Field | Type | Notes |
|---|---|---|
| ownerUid | string | the submitter's real Firebase UID |
| anonymousDeviceId | string | joins back to the public document |
| createdAt | timestamp | |

Report IDs are human-shareable, e.g. `DZC-20260911-7F3A` (see
`ReportRepository._generateReportId`), so citizens can reference them
without opening the app.

## Privacy model: why owner data is split out

Early on, `measurements`/`reports` stored a signed-in citizen's real
Firebase UID directly on the public document (needed so the owner
could later edit their own report, and so Firestore rules could
enforce that). The problem: any public reader of the community map or
report list could then correlate every measurement/report from the
same UID across time — building a location/activity history for a
named, registered account, even though their email/name were never
directly exposed.

The fix (current design): ownership now lives **only** in
`measurement_owners`/`report_owners`, collections that are never
publicly readable — only the owner themselves (matched by
`request.auth.uid`) or an admin can read them. The public documents
are written with a `hasOnly()`-restricted field set that structurally
cannot include an account identifier; this is enforced by Firestore
itself, not just by app code discipline.

What is still visible publicly: `anonymousDeviceId`, a random UUID
generated once per app install (`DeviceIdentity`), used by both guests
and signed-in users. It lets the community map/dead-zone analysis
recognize "these five points came from the same device" (useful for
abuse/spam pattern detection) **without** revealing which, if any,
registered account that device belongs to. This is an intentional
pseudonymization tradeoff, not an oversight — see
`docs/ARCHITECTURE.md` → "No fake data policy" for the sibling
"no fabricated data" principle this sits alongside.

What admins can still do: read `measurement_owners`/`report_owners`
for moderation (e.g. investigating a pattern of abusive reports tied
to one account), same as before — nothing about admin capability
changed, only what a *public, unauthenticated* reader can see.

## `schools/{schoolId}`
| Field | Type |
|---|---|
| schoolName | string |
| location | GeoPoint |
| students / teachers | number? |
| operator / networkType | string? |
| signalDbm / downloadMbps / uploadMbps / pingMs | number? |
| onlineLearningAccessible | boolean? |
| createdAt | timestamp |

## `health_facilities/{facilityId}`
| Field | Type |
|---|---|
| facilityName | string |
| location | GeoPoint |
| operator / networkType | string? |
| signalDbm / downloadMbps / uploadMbps / pingMs | number? |
| emergencyCommunicationAvailable | boolean? |
| createdAt | timestamp |

## `areas/{areaId}` (derived, Cloud Functions only)
Precomputed "probable connectivity problem" clusters for the admin
dashboard/map, mirroring the on-device `DeadZoneAnalyzer` logic but run
server-side over the full community dataset.

## `operators/{operatorId}`
Reference data (operator display name, brand color) used by the UI;
admin-managed.

## `sync_queue` (local only — Drift, not Firestore)
Generic outbound queue drained by `SyncService`. Never mirrored to
Firestore; it exists purely to make offline-first sync uniform across
entity types.

## Suggested Firestore indexes
- `measurements`: composite index on (`operator`, `measuredAt` desc)
  and (`networkType`, `measuredAt` desc) for map filters.
- `reports`: composite index on (`status`, `createdAt` desc) for the
  admin dashboard and "My Reports".
