import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";

// Mirrors lib/features/dead_zone/data/dead_zone_analyzer.dart. Keep the
// two implementations in sync if thresholds change — the mobile app
// runs this over the device's own local data for instant, offline
// feedback; this function runs the same logic over the FULL community
// dataset in Firestore and writes results to `areas` for the admin
// dashboard and (optionally) a "community dead zones" layer in the app.
//
// A single measurement is NEVER enough to flag an area. Results are
// always "probable", never "confirmed" or "permanent".
const MIN_MEASUREMENTS = 5;
const POOR_SIGNAL_RATIO = 0.6;
const AGGREGATION_RADIUS_METERS = 150;
const RECENCY_DAYS = 90;

interface MeasurementPoint {
  id: string;
  lat: number;
  lng: number;
  signalDbm: number | null;
  operatorName: string | null;
  measuredAt: admin.firestore.Timestamp;
}

function isPoorSignal(dbm: number | null): boolean {
  if (dbm === null) return false; // unknown is never counted as poor
  return dbm < -95; // weak or very weak per SignalQuality.fromDbm
}

function toRad(deg: number): number {
  return (deg * Math.PI) / 180;
}

function distanceMeters(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const earthRadius = 6371000;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.asin(Math.sqrt(a));
  return earthRadius * c;
}

function clusterByProximity(
  points: MeasurementPoint[],
  radiusMeters: number
): MeasurementPoint[][] {
  const remaining = [...points];
  const clusters: MeasurementPoint[][] = [];

  while (remaining.length > 0) {
    const seed = remaining.shift()!;
    const cluster = [seed];

    for (let i = remaining.length - 1; i >= 0; i--) {
      const candidate = remaining[i];
      if (
        distanceMeters(seed.lat, seed.lng, candidate.lat, candidate.lng) <=
        radiusMeters
      ) {
        cluster.push(candidate);
        remaining.splice(i, 1);
      }
    }
    clusters.push(cluster);
  }
  return clusters;
}

/**
 * Runs daily at 02:00. Recomputes probable-dead-zone clusters over all
 * measurements from the last [RECENCY_DAYS] days and overwrites the
 * `areas` collection (deleting stale entries first) so the admin
 * dashboard and mobile map always reflect current, real evidence —
 * never a stale or fabricated snapshot.
 */
export const computeProbableDeadZones = onSchedule(
  { schedule: "0 2 * * *", timeZone: "Asia/Karachi" },
  async () => {
    const db = admin.firestore();
    const cutoff = admin.firestore.Timestamp.fromMillis(
      Date.now() - RECENCY_DAYS * 24 * 60 * 60 * 1000
    );

    const snapshot = await db
      .collection("measurements")
      .where("measuredAt", ">=", cutoff)
      .get();

    const points: MeasurementPoint[] = snapshot.docs
      .map((doc) => {
        const data = doc.data();
        const geo = data.location as admin.firestore.GeoPoint | undefined;
        if (!geo) return null;
        return {
          id: doc.id,
          lat: geo.latitude,
          lng: geo.longitude,
          signalDbm:
            typeof data.signalDbm === "number" ? data.signalDbm : null,
          operatorName:
            typeof data.operator === "string" ? data.operator : null,
          measuredAt: data.measuredAt as admin.firestore.Timestamp,
        };
      })
      .filter((p): p is MeasurementPoint => p !== null);

    const clusters = clusterByProximity(points, AGGREGATION_RADIUS_METERS);

    const batch = db.batch();
    const existingAreas = await db.collection("areas").get();
    existingAreas.forEach((doc) => batch.delete(doc.ref));

    let flaggedCount = 0;
    for (const cluster of clusters) {
      if (cluster.length < MIN_MEASUREMENTS) continue;

      const poorCount = cluster.filter((p) => isPoorSignal(p.signalDbm))
        .length;
      const poorRatio = poorCount / cluster.length;
      if (poorRatio < POOR_SIGNAL_RATIO) continue;

      const dbmSamples = cluster
        .map((p) => p.signalDbm)
        .filter((v): v is number => v !== null);
      const avgSignal =
        dbmSamples.length > 0
          ? dbmSamples.reduce((a, b) => a + b, 0) / dbmSamples.length
          : null;

      const centerLat =
        cluster.reduce((sum, p) => sum + p.lat, 0) / cluster.length;
      const centerLng =
        cluster.reduce((sum, p) => sum + p.lng, 0) / cluster.length;

      const operators = Array.from(
        new Set(
          cluster.map((p) => p.operatorName).filter((v): v is string => !!v)
        )
      );

      const lastMeasuredAt = cluster.reduce((latest, p) =>
        p.measuredAt.toMillis() > latest.measuredAt.toMillis() ? p : latest
      ).measuredAt;

      const areaRef = db.collection("areas").doc();
      batch.set(areaRef, {
        label: "Probable Connectivity Problem",
        centerLocation: new admin.firestore.GeoPoint(centerLat, centerLng),
        measurementCount: cluster.length,
        averageSignalDbm: avgSignal,
        poorSignalRatio: poorRatio,
        affectedOperators: operators,
        lastMeasuredAt,
        computedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      flaggedCount++;
    }

    await batch.commit();
    console.log(
      `computeProbableDeadZones: ${points.length} measurements, ` +
        `${clusters.length} clusters, ${flaggedCount} flagged as probable ` +
        `connectivity problems.`
    );
  }
);
