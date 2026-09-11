import 'dart:math';

import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/device_identity.dart';
import '../../sync/data/sync_service.dart';
import '../domain/entities/problem_category.dart';
import '../domain/entities/problem_report.dart';

/// Generates a short, unique, human-shareable report ID such as
/// `DZC-20260911-7F3A`, and saves reports locally-first exactly like
/// measurements. A report is always linked to the citizen's most recent
/// measurement (if any) so the evidence is self-contained.
class ReportRepository {
  ReportRepository(this._db);
  final AppDatabase _db;

  String _generateReportId() {
    final now = DateTime.now();
    final datePart =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final rand = Random.secure();
    final suffix = List.generate(
      4,
      (_) => '0123456789ABCDEF'[rand.nextInt(16)],
    ).join();
    return 'DZC-$datePart-$suffix';
  }

  /// Window and radius used to detect an accidental duplicate
  /// submission (e.g. a double-tap that slipped past the disabled
  /// button, or a retry after what looked like a failed submit).
  static const Duration duplicateWindow = Duration(minutes: 5);
  static const double duplicateRadiusMeters = 75;

  /// Returns the existing report if the same category was already
  /// reported from essentially the same location within
  /// [duplicateWindow], so the UI can ask the user to confirm before
  /// creating a second report for what is likely the same incident.
  /// Pass [allowDuplicate]=true to skip this check once the user has
  /// confirmed they do want to submit again.
  Future<ProblemReport?> findLikelyDuplicate({
    required ProblemCategory category,
    required double latitude,
    required double longitude,
  }) async {
    final anonymousId = await DeviceIdentity.getOrCreateAnonymousId();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final cutoff = DateTime.now().subtract(duplicateWindow);

    final query = _db.select(_db.reports)
      ..where((t) => t.category.equals(category.name))
      ..where((t) => t.createdAt.isBiggerOrEqualValue(cutoff))
      ..where((t) => userId != null
          ? t.userId.equals(userId)
          : t.anonymousDeviceId.equals(anonymousId));

    final candidates = await query.get();
    for (final row in candidates) {
      final distance = _distanceMeters(
        latitude,
        longitude,
        row.latitude,
        row.longitude,
      );
      if (distance <= duplicateRadiusMeters) {
        return _rowToEntity(row);
      }
    }
    return null;
  }

  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0;
    double degToRad(double deg) => deg * (pi / 180.0);
    final dLat = degToRad(lat2 - lat1);
    final dLon = degToRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(degToRad(lat1)) *
            cos(degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  Future<ProblemReport> submitReport({
    required ProblemCategory category,
    required double latitude,
    required double longitude,
    String? description,
    String? photoLocalPath,
    String? operatorName,
    String? networkType,
    String? linkedMeasurementId,
    int? signalDbm,
    double? downloadMbps,
    double? uploadMbps,
    int? pingMs,
    double? gpsAccuracyMeters,
  }) async {
    final anonymousId = await DeviceIdentity.getOrCreateAnonymousId();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final id = _generateReportId();
    final now = DateTime.now();

    final report = ProblemReport(
      id: id,
      userId: userId,
      anonymousDeviceId: anonymousId,
      category: category,
      description: description,
      photoLocalPath: photoLocalPath,
      latitude: latitude,
      longitude: longitude,
      operatorName: operatorName,
      networkType: networkType,
      linkedMeasurementId: linkedMeasurementId,
      signalDbm: signalDbm,
      downloadMbps: downloadMbps,
      uploadMbps: uploadMbps,
      pingMs: pingMs,
      gpsAccuracyMeters: gpsAccuracyMeters,
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.reports).insert(
          ReportsCompanion.insert(
            id: report.id,
            userId: Value(report.userId),
            anonymousDeviceId: report.anonymousDeviceId,
            category: report.category.name,
            description: Value(report.description),
            photoLocalPath: Value(report.photoLocalPath),
            latitude: report.latitude,
            longitude: report.longitude,
            operatorName: Value(report.operatorName),
            networkType: Value(report.networkType),
            linkedMeasurementId: Value(report.linkedMeasurementId),
            signalDbm: Value(report.signalDbm),
            downloadMbps: Value(report.downloadMbps),
            uploadMbps: Value(report.uploadMbps),
            pingMs: Value(report.pingMs),
            gpsAccuracyMeters: Value(report.gpsAccuracyMeters),
            createdAt: report.createdAt,
            updatedAt: report.updatedAt,
          ),
        );

    await _db.into(_db.syncQueueItems).insert(
          SyncQueueItemsCompanion.insert(
            entityType: 'report',
            entityId: report.id,
            createdAt: DateTime.now(),
          ),
        );

    return report;
  }

  Stream<List<ProblemReport>> watchMyReports() {
    return (_db.select(_db.reports)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_rowToEntity).toList());
  }

  ProblemReport _rowToEntity(ReportsData row) {
    return ProblemReport(
      id: row.id,
      userId: row.userId,
      anonymousDeviceId: row.anonymousDeviceId,
      category: ProblemCategory.values.firstWhere(
        (c) => c.name == row.category,
        orElse: () => ProblemCategory.other,
      ),
      description: row.description,
      photoLocalPath: row.photoLocalPath,
      photoRemoteUrl: row.photoRemoteUrl,
      latitude: row.latitude,
      longitude: row.longitude,
      operatorName: row.operatorName,
      networkType: row.networkType,
      linkedMeasurementId: row.linkedMeasurementId,
      signalDbm: row.signalDbm,
      downloadMbps: row.downloadMbps,
      uploadMbps: row.uploadMbps,
      pingMs: row.pingMs,
      gpsAccuracyMeters: row.gpsAccuracyMeters,
      status: ReportStatus.fromKey(row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}

final Provider<ReportRepository> reportRepositoryProvider =
    Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(appDatabaseProvider));
});

final StreamProvider<List<ProblemReport>> myReportsProvider =
    StreamProvider<List<ProblemReport>>((ref) {
  return ref.watch(reportRepositoryProvider).watchMyReports();
});
