import * as admin from "firebase-admin";

admin.initializeApp();

export { setAdminClaim } from "./adminClaims";
export { computeProbableDeadZones } from "./deadZoneAggregation";
