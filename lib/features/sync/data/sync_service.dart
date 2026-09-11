import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/database/app_database.dart';
import '../../../core/network/connectivity_service.dart';

final _log = Logger();

/// Offline-first synchronization engine. Local Drift tables are always
/// the source of truth for the device; this service drains
/// [SyncQueueItems] into Firestore whenever connectivity is available,
/// and never blocks local writes on network state.
class SyncService {
  SyncService(this._db, this._firestore);

  final AppDatabase _db;
  final FirebaseFirestore? _firestore;

  static const int maxAttemptsBeforeBackoffCap = 8;

  Future<void> syncPending() async {
    if (_firestore == null) {
      _log.i('Firestore not configured — skipping sync, data stays local.');
      return;
    }

    final pending = await _db.select(_db.syncQueueItems).get();
    for (final item in pending) {
      try {
        await _pushItem(item);
        await (_db.delete(_db.syncQueueItems)
              ..where((tbl) => tbl.id.equals(item.id)))
            .go();
      } catch (error) {
        _log.w('Sync failed for ${item.entityType}/${item.entityId}: $error');
        await (_db.update(_db.syncQueueItems)
              ..where((tbl) => tbl.id.equals(item.id)))
            .write(
          SyncQueueItemsCompanion(
            attemptCount: Value(item.attemptCount + 1),
            lastAttemptAt: Value(DateTime.now()),
          ),
        );
      }
    }
  }

  Future<void> _pushItem(SyncQueueItem item) async {
    switch (item.entityType) {
      case 'measurement':
        await _pushMeasurement(item.entityId);
        break;
      case 'report':
        await _pushReport(item.entityId);
        break;
      case 'school':
        await _pushSchoolSurvey(item.entityId);
        break;
      case 'health':
        await _pushHealthSurvey(item.entityId);
        break;
      default:
        _log.w('Unknown sync entity type: ${item.entityType}');
    }
  }

  Future<void> _pushMeasurement(String id) async {
    final row = await (_db.select(_db.measurements)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;

    await _firestore!.collection('measurements').doc(row.id).set({
      'userId': row.userId,
      'anonymousDeviceId': row.anonymousDeviceId,
      'location': GeoPoint(row.latitude, row.longitude),
      'gpsAccuracyMeters': row.gpsAccuracyMeters,
      'operator': row.operatorName,
      'networkType': row.networkType,
      'signalDbm': row.signalDbm,
      'signalAsu': row.signalAsu,
      'downloadMbps': row.downloadMbps,
      'uploadMbps': row.uploadMbps,
      'pingMs': row.pingMs,
      'measuredAt': Timestamp.fromDate(row.measuredAt),
      'isDemoData': row.isDemoData,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await (_db.update(_db.measurements)
          ..where((tbl) => tbl.id.equals(id)))
        .write(
      MeasurementsCompanion(
        syncStatus: const Value('synced'),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _pushReport(String id) async {
    final row = await (_db.select(_db.reports)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;

    await _firestore!.collection('reports').doc(row.id).set({
      'userId': row.userId,
      'anonymousDeviceId': row.anonymousDeviceId,
      'category': row.category,
      'description': row.description,
      'photoUrl': row.photoRemoteUrl,
      'location': GeoPoint(row.latitude, row.longitude),
      'operator': row.operatorName,
      'networkType': row.networkType,
      'linkedMeasurementId': row.linkedMeasurementId,
      'status': row.status,
      'createdAt': Timestamp.fromDate(row.createdAt),
      'updatedAt': Timestamp.fromDate(row.updatedAt),
    });

    await (_db.update(_db.reports)..where((tbl) => tbl.id.equals(id)))
        .write(const ReportsCompanion(syncStatus: Value('synced')));
  }

  Future<void> _pushSchoolSurvey(String id) async {
    final row = await (_db.select(_db.schoolSurveys)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;

    await _firestore!.collection('schools').doc(row.id).set({
      'schoolName': row.schoolName,
      'location': GeoPoint(row.latitude, row.longitude),
      'students': row.students,
      'teachers': row.teachers,
      'operator': row.operatorName,
      'networkType': row.networkType,
      'signalDbm': row.signalDbm,
      'downloadMbps': row.downloadMbps,
      'uploadMbps': row.uploadMbps,
      'pingMs': row.pingMs,
      'onlineLearningAccessible': row.onlineLearningAccessible,
      'createdAt': Timestamp.fromDate(row.createdAt),
    });

    await (_db.update(_db.schoolSurveys)..where((tbl) => tbl.id.equals(id)))
        .write(const SchoolSurveysCompanion(syncStatus: Value('synced')));
  }

  Future<void> _pushHealthSurvey(String id) async {
    final row = await (_db.select(_db.healthFacilitySurveys)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;

    await _firestore!.collection('health_facilities').doc(row.id).set({
      'facilityName': row.facilityName,
      'location': GeoPoint(row.latitude, row.longitude),
      'operator': row.operatorName,
      'networkType': row.networkType,
      'signalDbm': row.signalDbm,
      'downloadMbps': row.downloadMbps,
      'uploadMbps': row.uploadMbps,
      'pingMs': row.pingMs,
      'emergencyCommunicationAvailable':
          row.emergencyCommunicationAvailable,
      'createdAt': Timestamp.fromDate(row.createdAt),
    });

    await (_db.update(_db.healthFacilitySurveys)
          ..where((tbl) => tbl.id.equals(id)))
        .write(const HealthFacilitySurveysCompanion(
            syncStatus: Value('synced')));
  }
}

final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final Provider<FirebaseFirestore?> firestoreProvider =
    Provider<FirebaseFirestore?>((ref) {
  try {
    return FirebaseFirestore.instance;
  } catch (_) {
    return null; // Firebase not initialized (offline/demo scaffold mode).
  }
});

final Provider<SyncService> syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final firestore = ref.watch(firestoreProvider);
  return SyncService(db, firestore);
});

/// Watches connectivity and triggers a sync pass whenever the device
/// comes back online. Call [start] once from app startup.
class SyncTrigger {
  SyncTrigger(this._ref);
  final Ref _ref;

  void start() {
    _ref.listen<AsyncValue<bool>>(isOnlineProvider, (previous, next) {
      final wasOffline = previous?.value == false;
      final isOnlineNow = next.value == true;
      if (wasOffline && isOnlineNow) {
        _ref.read(syncServiceProvider).syncPending();
      }
    });
  }
}
