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
Public read, append-only from clients.
| Field | Type | Notes |
|---|---|---|
| userId | string? | null for guest/anonymous |
| anonymousDeviceId | string | random UUID, not a hardware ID |
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

## `reports/{reportId}`
Public read; status only editable by admins.
| Field | Type | Notes |
|---|---|---|
| userId | string? | |
| anonymousDeviceId | string | |
| category | string | `ProblemCategory` enum name |
| description | string? | |
| photoUrl | string? | Firebase Storage download URL |
| location | GeoPoint | |
| operator | string? | auto-attached from latest measurement |
| networkType | string? | |
| linkedMeasurementId | string? | |
| status | string | pending / underReview / inProgress / resolved / closed |
| createdAt | timestamp | |
| updatedAt | timestamp | |

Report IDs are human-shareable, e.g. `DZC-20260911-7F3A` (see
`ReportRepository._generateReportId`), so citizens can reference them
without opening the app.

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
