# Darazinda Connect — Cloud Functions

Two functions, deliberately minimal:

- **`setAdminClaim`** (callable) — the only way `admin: true` is granted
  to a Firebase Auth account after the first admin exists. Requires the
  caller to already be an admin. See `src/adminClaims.ts`.
- **`computeProbableDeadZones`** (scheduled, daily 02:00 Asia/Karachi)
  — recomputes probable-connectivity-problem clusters over the last 90
  days of community measurements and writes them to the `areas`
  collection. Mirrors `lib/features/dead_zone/data/dead_zone_analyzer.dart`
  — keep both in sync if thresholds change. See `src/deadZoneAggregation.ts`.

## Bootstrapping the first admin

`setAdminClaim` can only be called by an existing admin, so it cannot
create the first one. Run this once, locally, against your real
Firebase project:

```bash
cd functions
npm install
# Download a service account key from:
# Firebase Console > Project Settings > Service Accounts > Generate new private key
# Save it OUTSIDE this repo — never commit it.
GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json \
  node scripts/setInitialAdmin.js your-admin-email@example.com
```

The user must sign out/in (or call `getIdToken(true)`) in the admin
dashboard afterwards for the new claim to take effect — Firebase ID
tokens cache claims until refreshed.

## Local development

```bash
npm install
npm run build
firebase emulators:start --only functions,firestore,auth
```

## Deploying

```bash
firebase deploy --only functions
```

Requires `firebase login` and a real project set in `.firebaserc`
(replace the `REPLACE_WITH_YOUR_FIREBASE_PROJECT_ID` placeholder at the
repo root first).

## Not yet implemented here (documented, not built)

- Report photo thumbnailing/compression on Storage upload.
- Rate limiting / abuse detection beyond Firestore rules + App Check.
- A `deleteUserData` callable for full GDPR-style erasure of a user's
  synced Firestore documents (Settings currently only deletes local
  on-device data — see `docs/ARCHITECTURE.md`).
