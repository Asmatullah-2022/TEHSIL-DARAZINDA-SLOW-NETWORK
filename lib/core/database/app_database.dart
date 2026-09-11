import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// A single locally-collected network measurement. Every field is either
/// a real OS-reported value or explicitly null ("not available on this
/// device") — never a fabricated placeholder.
///
/// Row type is named `MeasurementsData` (via @DataClassName) instead of
/// Drift's default `Measurement` to avoid colliding with the domain
/// entity `Measurement` in `features/network_test/domain/entities/`.
@DataClassName('MeasurementsData')
class Measurements extends Table {
  TextColumn get id => text()(); // uuid, generated client-side
  TextColumn get userId => text().nullable()(); // null for guest/anonymous
  TextColumn get anonymousDeviceId => text()(); // stable per-install, not PII

  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get gpsAccuracyMeters => real().nullable()();

  TextColumn get operatorName => text().nullable()();
  TextColumn get networkType => text().nullable()(); // e.g. LTE, 3G, 2G, NR
  IntColumn get signalDbm => integer().nullable()();
  IntColumn get signalAsu => integer().nullable()();
  TextColumn get simCountryIso => text().nullable()();

  RealColumn get downloadMbps => real().nullable()();
  RealColumn get uploadMbps => real().nullable()();
  IntColumn get pingMs => integer().nullable()();

  DateTimeColumn get measuredAt => dateTime()();
  BoolColumn get isDemoData =>
      boolean().withDefault(const Constant(false))();

  TextColumn get syncStatus =>
      text().withDefault(const Constant('pendingSync'))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A citizen-submitted connectivity problem report.
@DataClassName('ReportsData')
class Reports extends Table {
  TextColumn get id => text()(); // human-friendly unique report ID
  TextColumn get userId => text().nullable()();
  TextColumn get anonymousDeviceId => text()();

  TextColumn get category => text()(); // ProblemCategory enum name
  TextColumn get description => text().nullable()();
  TextColumn get photoLocalPath => text().nullable()();
  TextColumn get photoRemoteUrl => text().nullable()();

  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get operatorName => text().nullable()();
  TextColumn get networkType => text().nullable()();
  TextColumn get linkedMeasurementId => text().nullable()();

  // Snapshot of the linked measurement's readings at submission time —
  // stored directly so "My Reports" and the exported PDF are
  // self-contained evidence, not just a dangling foreign key.
  IntColumn get signalDbm => integer().nullable()();
  RealColumn get downloadMbps => real().nullable()();
  RealColumn get uploadMbps => real().nullable()();
  IntColumn get pingMs => integer().nullable()();
  RealColumn get gpsAccuracyMeters => real().nullable()();

  TextColumn get status =>
      text().withDefault(const Constant('pending'))(); // ReportStatus enum
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  TextColumn get syncStatus =>
      text().withDefault(const Constant('pendingSync'))();

  @override
  Set<Column> get primaryKey => {id};
}

class SchoolSurveys extends Table {
  TextColumn get id => text()();
  TextColumn get schoolName => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get students => integer().nullable()();
  IntColumn get teachers => integer().nullable()();
  TextColumn get operatorName => text().nullable()();
  TextColumn get networkType => text().nullable()();
  IntColumn get signalDbm => integer().nullable()();
  RealColumn get downloadMbps => real().nullable()();
  RealColumn get uploadMbps => real().nullable()();
  IntColumn get pingMs => integer().nullable()();
  BoolColumn get onlineLearningAccessible => boolean().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pendingSync'))();

  @override
  Set<Column> get primaryKey => {id};
}

class HealthFacilitySurveys extends Table {
  TextColumn get id => text()();
  TextColumn get facilityName => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get operatorName => text().nullable()();
  TextColumn get networkType => text().nullable()();
  IntColumn get signalDbm => integer().nullable()();
  RealColumn get downloadMbps => real().nullable()();
  RealColumn get uploadMbps => real().nullable()();
  IntColumn get pingMs => integer().nullable()();
  BoolColumn get emergencyCommunicationAvailable => boolean().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pendingSync'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Generic outbound sync queue: every locally-created record that must
/// reach Firestore is enqueued here, so sync logic is uniform across
/// entity types and survives app restarts while offline.
class SyncQueueItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // measurement|report|school|health
  TextColumn get entityId => text()();
  TextColumn get operation =>
      text().withDefault(const Constant('create'))(); // create|update
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(
  tables: [
    Measurements,
    Reports,
    SchoolSurveys,
    HealthFacilitySurveys,
    SyncQueueItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'darazinda_connect.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
