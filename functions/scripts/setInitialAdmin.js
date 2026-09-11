#!/usr/bin/env node
/**
 * One-time bootstrap script to grant the FIRST admin account its
 * `admin: true` custom claim. Every subsequent admin should be added
 * through the `setAdminClaim` callable Cloud Function (by an existing
 * admin, from the admin dashboard), not this script — this script
 * exists only to solve the chicken-and-egg problem of creating the
 * very first admin.
 *
 * Usage:
 *   1. In the Firebase Console: Project Settings > Service Accounts >
 *      "Generate new private key". Save the JSON file somewhere OUTSIDE
 *      this repository (never commit a service account key).
 *   2. GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json \
 *        node functions/scripts/setInitialAdmin.js someone@example.com
 */
const admin = require("firebase-admin");

const targetEmail = process.argv[2];
if (!targetEmail) {
  console.error("Usage: node setInitialAdmin.js <email>");
  process.exit(1);
}

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error(
    "GOOGLE_APPLICATION_CREDENTIALS must point to a service account key " +
      "JSON file downloaded from Firebase Console > Project Settings > " +
      "Service Accounts. Never commit this file to the repository."
  );
  process.exit(1);
}

admin.initializeApp({ credential: admin.credential.applicationDefault() });

admin
  .auth()
  .getUserByEmail(targetEmail)
  .then((user) =>
    admin.auth().setCustomUserClaims(user.uid, { admin: true }).then(() => user)
  )
  .then((user) => {
    console.log(`Granted admin claim to ${targetEmail} (uid: ${user.uid}).`);
    console.log(
      "The user must sign out and back in (or call getIdToken(true)) " +
        "for the new claim to take effect."
    );
    process.exit(0);
  })
  .catch((err) => {
    console.error("Failed to set admin claim:", err.message);
    process.exit(1);
  });
