import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/services/speed_test_service.dart';
import '../../../../core/utils/device_identity.dart';
import '../../../sync/data/sync_service.dart';
import '../../domain/entities/measurement.dart';
import '../datasources/telephony_data_source.dart';

/// Orchestrates a full measurement: GPS fix -> telephony reading ->
/// speed/latency test -> save-locally-first -> enqueue for sync. Never
/// blocks on network availability; a measurement is complete and useful
/// the moment it is written to the local database.
class MeasurementRepository {
  MeasurementRepository(this._db, this._telephony, this._location,
      this._speedTest, this._connectivity, this._permissions);

  final AppDatabase _db;
  final TelephonyDataSource _telephony;
  final LocationService _location;
  final SpeedTestService _speedTest;
  final ConnectivityService _connectivity;
  final PermissionService _permissions;

  bool _cancelRequested = false;

  /// Aborts the in-flight download/upload leg of the current test, if
  /// any, and stops `runFullTest` from proceeding to save a partial
  /// result. Lets the UI offer a "Cancel Test" action instead of
  /// forcing the user to wait out the full timeout — also bounds data
  /// usage if the user changes their mind mid-download.
  void cancelRunningTest() {
    _cancelRequested = true;
    _speedTest.cancel();
  }

  Future<Measurement> runFullTest({
    required void Function(String stage) onStage,
  }) async {
    _cancelRequested = false;

    onStage('locating');
    final locationResult = await _location.getCurrentLocation();
    if (locationResult is! LocationSuccess) {
      throw MeasurementException.fromLocationResult(locationResult);
    }
    final Position position = locationResult.position;

    onStage('reading_telephony');
    // Request READ_PHONE_STATE here (not earlier) so the permission
    // rationale is shown right when it's about to be used, and so a
    // denial doesn't block the GPS-only parts of a measurement.
    await _permissions.ensurePhoneStatePermission();
    final telephony = await _telephony.getReading();

    onStage('testing_ping');
    final bool online = await _connectivity.isOnline;
    final pingMs = online ? await _speedTest.measurePingMs() : null;
    if (_cancelRequested) throw const MeasurementCancelledException();

    onStage('testing_download');
    final downloadMbps =
        online ? await _speedTest.measureDownloadMbps() : null;
    if (_cancelRequested) throw const MeasurementCancelledException();

    onStage('testing_upload');
    final uploadMbps = online ? await _speedTest.measureUploadMbps() : null;
    if (_cancelRequested) throw const MeasurementCancelledException();

    onStage('saving');
    final anonymousId = await DeviceIdentity.getOrCreateAnonymousId();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final id = const Uuid().v4();
    final now = DateTime.now();

    final measurement = Measurement(
      id: id,
      userId: userId,
      anonymousDeviceId: anonymousId,
      latitude: position.latitude,
      longitude: position.longitude,
      gpsAccuracyMeters: position.accuracy,
      operatorName: telephony.operatorName,
      networkType: telephony.networkType,
      signalDbm: telephony.signalDbm,
      signalAsu: telephony.signalAsu,
      simCountryIso: telephony.simCountryIso,
      downloadMbps: downloadMbps,
      uploadMbps: uploadMbps,
      pingMs: pingMs,
      measuredAt: now,
    );

    await _saveLocally(measurement);
    return measurement;
  }

  Future<void> _saveLocally(Measurement m) async {
    await _db.into(_db.measurements).insert(
          MeasurementsCompanion.insert(
            id: m.id,
            userId: Value(m.userId),
            anonymousDeviceId: m.anonymousDeviceId,
            latitude: m.latitude,
            longitude: m.longitude,
            gpsAccuracyMeters: Value(m.gpsAccuracyMeters),
            operatorName: Value(m.operatorName),
            networkType: Value(m.networkType),
            signalDbm: Value(m.signalDbm),
            signalAsu: Value(m.signalAsu),
            simCountryIso: Value(m.simCountryIso),
            downloadMbps: Value(m.downloadMbps),
            uploadMbps: Value(m.uploadMbps),
            pingMs: Value(m.pingMs),
            measuredAt: m.measuredAt,
          ),
        );

    await _db.into(_db.syncQueueItems).insert(
          SyncQueueItemsCompanion.insert(
            entityType: 'measurement',
            entityId: m.id,
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<Measurement?> getLastMeasurement() async {
    final row = await (_db.select(_db.measurements)
          ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)])
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return null;
    return _rowToEntity(row);
  }

  Stream<List<Measurement>> watchAllMeasurements() {
    return (_db.select(_db.measurements)
          ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)]))
        .watch()
        .map((rows) => rows.map(_rowToEntity).toList());
  }

  Measurement _rowToEntity(MeasurementsData row) {
    return Measurement(
      id: row.id,
      userId: row.userId,
      anonymousDeviceId: row.anonymousDeviceId,
      latitude: row.latitude,
      longitude: row.longitude,
      gpsAccuracyMeters: row.gpsAccuracyMeters,
      operatorName: row.operatorName,
      networkType: row.networkType,
      signalDbm: row.signalDbm,
      signalAsu: row.signalAsu,
      simCountryIso: row.simCountryIso,
      downloadMbps: row.downloadMbps,
      uploadMbps: row.uploadMbps,
      pingMs: row.pingMs,
      measuredAt: row.measuredAt,
      isDemoData: row.isDemoData,
      syncStatus: row.syncStatus == 'synced'
          ? SyncStatus.synced
          : SyncStatus.pendingSync,
    );
  }
}

class MeasurementException implements Exception {
  MeasurementException(this.message);
  final String message;

  factory MeasurementException.fromLocationResult(LocationResult result) {
    return switch (result) {
      LocationServiceDisabled() =>
        MeasurementException('gps_disabled'),
      LocationPermissionDenied(isPermanent: true) =>
        MeasurementException('gps_permission_permanently_denied'),
      LocationPermissionDenied(isPermanent: false) =>
        MeasurementException('gps_permission_denied'),
      LocationTimedOut() => MeasurementException('gps_timeout'),
      _ => MeasurementException('gps_unknown_error'),
    };
  }

  @override
  String toString() => message;
}

/// Thrown when the user cancels a test in progress (see
/// [MeasurementRepository.cancelRunningTest]). Deliberately distinct
/// from [MeasurementException] so the UI can show a neutral "Test
/// cancelled" state instead of an error.
class MeasurementCancelledException implements Exception {
  const MeasurementCancelledException();
}

final Provider<TelephonyDataSource> telephonyDataSourceProvider =
    Provider<TelephonyDataSource>((ref) => TelephonyDataSource());

final Provider<LocationService> locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

final Provider<SpeedTestService> speedTestServiceProvider =
    Provider<SpeedTestService>((ref) => SpeedTestService());

final Provider<PermissionService> permissionServiceProvider =
    Provider<PermissionService>((ref) => PermissionService());

final Provider<MeasurementRepository> measurementRepositoryProvider =
    Provider<MeasurementRepository>((ref) {
  return MeasurementRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(telephonyDataSourceProvider),
    ref.watch(locationServiceProvider),
    ref.watch(speedTestServiceProvider),
    ref.watch(connectivityServiceProvider),
    ref.watch(permissionServiceProvider),
  );
});
