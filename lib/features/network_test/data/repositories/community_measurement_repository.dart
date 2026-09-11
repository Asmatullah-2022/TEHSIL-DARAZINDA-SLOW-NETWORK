import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../sync/data/sync_service.dart';
import '../../domain/entities/measurement.dart';
import '../../presentation/providers/network_test_provider.dart'
    show allMeasurementsProvider;

final _log = Logger();

/// Reads the shared, public `measurements` collection from Firestore —
/// this is what actually makes the Signal Map, Statistics, Operator
/// Comparison, and Dead Zone screens "community" features rather than
/// a private on-device log. Without this, those screens would only
/// ever reflect the current device's own measurements, even though
/// data is being synced UP to Firestore from every device.
///
/// Bounded by [recencyWindow] and [maxResults] — Firestore billing and
/// on-device memory both make "stream the entire collection forever"
/// impractical at real community scale. A device that is offline or
/// has no Firebase project configured simply gets an empty stream
/// here (never an error, never fabricated data) and the UI falls back
/// to local-only data, which is exactly the offline-first contract the
/// rest of the app already follows.
class CommunityMeasurementRepository {
  CommunityMeasurementRepository(this._firestore);
  final FirebaseFirestore? _firestore;

  static const Duration recencyWindow = Duration(days: 90);
  static const int maxResults = 2000;

  Stream<List<Measurement>> watchCommunityMeasurements() {
    final firestore = _firestore;
    if (firestore == null) return Stream.value(const []);

    final cutoff = DateTime.now().subtract(recencyWindow);

    return firestore
        .collection('measurements')
        .where('measuredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('measuredAt', descending: true)
        .limit(maxResults)
        .snapshots()
        .handleError((Object error) {
      _log.w('Community measurements stream error: $error');
    }).map((snapshot) => snapshot.docs
        .map(_fromFirestoreDoc)
        .whereType<Measurement>()
        .toList());
  }

  Measurement? _fromFirestoreDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final data = doc.data();
      final location = data['location'] as GeoPoint?;
      final measuredAt = data['measuredAt'] as Timestamp?;
      if (location == null || measuredAt == null) return null;

      return Measurement(
        id: doc.id,
        userId: data['userId'] as String?,
        anonymousDeviceId: data['anonymousDeviceId'] as String? ?? 'unknown',
        latitude: location.latitude,
        longitude: location.longitude,
        gpsAccuracyMeters: (data['gpsAccuracyMeters'] as num?)?.toDouble(),
        operatorName: data['operator'] as String?,
        networkType: data['networkType'] as String?,
        signalDbm: (data['signalDbm'] as num?)?.toInt(),
        signalAsu: (data['signalAsu'] as num?)?.toInt(),
        downloadMbps: (data['downloadMbps'] as num?)?.toDouble(),
        uploadMbps: (data['uploadMbps'] as num?)?.toDouble(),
        pingMs: (data['pingMs'] as num?)?.toInt(),
        measuredAt: measuredAt.toDate(),
        isDemoData: data['isDemoData'] as bool? ?? false,
        syncStatus: SyncStatus.synced,
        isFromCommunity: true,
      );
    } catch (error) {
      _log.w('Skipping malformed community measurement ${doc.id}: $error');
      return null;
    }
  }
}

final Provider<CommunityMeasurementRepository>
    communityMeasurementRepositoryProvider =
    Provider<CommunityMeasurementRepository>((ref) {
  return CommunityMeasurementRepository(ref.watch(firestoreProvider));
});

/// Community-wide report count via a Firestore aggregate `count()`
/// query — cheap (one aggregation read, not N document reads) and
/// avoids pulling every citizen's report description/photo just to
/// show a number on the Statistics screen.
final FutureProvider<int?> communityReportCountProvider =
    FutureProvider<int?>((ref) async {
  final firestore = ref.watch(firestoreProvider);
  if (firestore == null) return null;
  try {
    final snapshot = await firestore.collection('reports').count().get();
    return snapshot.count;
  } catch (error) {
    _log.w('Community report count failed: $error');
    return null;
  }
});

final StreamProvider<List<Measurement>> communityMeasurementsProvider =
    StreamProvider<List<Measurement>>((ref) {
  return ref
      .watch(communityMeasurementRepositoryProvider)
      .watchCommunityMeasurements();
});

/// Local device measurements + community measurements, de-duplicated by
/// id (a measurement that originated locally and has since synced
/// would otherwise appear twice — once from each stream). Local data
/// wins the dedupe so a device's own not-yet-synced or in-flight
/// measurements are never masked by a stale community copy.
final Provider<AsyncValue<List<Measurement>>> combinedMeasurementsProvider =
    Provider<AsyncValue<List<Measurement>>>((ref) {
  final local = ref.watch(allMeasurementsProvider);
  final community = ref.watch(communityMeasurementsProvider);

  if (local.isLoading) return const AsyncValue.loading();
  if (local.hasError) {
    return AsyncValue.error(local.error!, local.stackTrace!);
  }

  final localList = local.value ?? const [];
  final communityList = community.value ?? const [];

  final byId = <String, Measurement>{};
  for (final m in communityList) {
    byId[m.id] = m;
  }
  for (final m in localList) {
    byId[m.id] = m; // local always wins
  }

  return AsyncValue.data(byId.values.toList());
});
