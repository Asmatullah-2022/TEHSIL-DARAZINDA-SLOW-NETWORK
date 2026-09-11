import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../sync/data/sync_service.dart';

class SchoolSurveyRepository {
  SchoolSurveyRepository(this._db);
  final AppDatabase _db;

  Future<void> submit({
    required String schoolName,
    required double latitude,
    required double longitude,
    int? students,
    int? teachers,
    String? operatorName,
    String? networkType,
    int? signalDbm,
    double? downloadMbps,
    double? uploadMbps,
    int? pingMs,
    bool? onlineLearningAccessible,
  }) async {
    final id = const Uuid().v4();
    await _db.into(_db.schoolSurveys).insert(
          SchoolSurveysCompanion.insert(
            id: id,
            schoolName: schoolName,
            latitude: latitude,
            longitude: longitude,
            students: Value(students),
            teachers: Value(teachers),
            operatorName: Value(operatorName),
            networkType: Value(networkType),
            signalDbm: Value(signalDbm),
            downloadMbps: Value(downloadMbps),
            uploadMbps: Value(uploadMbps),
            pingMs: Value(pingMs),
            onlineLearningAccessible: Value(onlineLearningAccessible),
            createdAt: DateTime.now(),
          ),
        );

    await _db.into(_db.syncQueueItems).insert(
          SyncQueueItemsCompanion.insert(
            entityType: 'school',
            entityId: id,
            createdAt: DateTime.now(),
          ),
        );
  }
}

final Provider<SchoolSurveyRepository> schoolSurveyRepositoryProvider =
    Provider<SchoolSurveyRepository>((ref) {
  return SchoolSurveyRepository(ref.watch(appDatabaseProvider));
});
