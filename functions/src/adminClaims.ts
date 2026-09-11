import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

/**
 * Grants or revokes the `admin: true` custom claim on another user's
 * Firebase Auth account. This is the ONLY supported way admin access
 * is granted in Darazinda Connect — there is deliberately no "isAdmin"
 * flag stored in a client-writable Firestore document, because a
 * client-writable flag can be forged by any signed-in user. Custom
 * claims are set exclusively by the Admin SDK (server-side), and the
 * Firestore/Storage security rules check `request.auth.token.admin`,
 * which the client cannot influence.
 *
 * The very first admin account CANNOT be created through this
 * function (a function that only admins may call obviously can't
 * bootstrap the first admin) — it must be set once via the
 * `scripts/setInitialAdmin.js` script, run locally with a service
 * account key. See functions/README.md.
 */
export const setAdminClaim = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }
  if (request.auth.token.admin !== true) {
    throw new HttpsError(
      "permission-denied",
      "Only an existing admin may grant or revoke admin access."
    );
  }

  const targetUid = request.data?.targetUid;
  const makeAdmin = request.data?.makeAdmin;

  if (typeof targetUid !== "string" || targetUid.length === 0) {
    throw new HttpsError("invalid-argument", "targetUid is required.");
  }
  if (typeof makeAdmin !== "boolean") {
    throw new HttpsError("invalid-argument", "makeAdmin must be a boolean.");
  }

  const targetUser = await admin.auth().getUser(targetUid);
  const existingClaims = targetUser.customClaims ?? {};

  await admin.auth().setCustomUserClaims(targetUid, {
    ...existingClaims,
    admin: makeAdmin,
  });

  await admin.firestore().collection("admin_audit_log").add({
    action: makeAdmin ? "grant_admin" : "revoke_admin",
    targetUid,
    performedBy: request.auth.uid,
    at: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, targetUid, admin: makeAdmin };
});
