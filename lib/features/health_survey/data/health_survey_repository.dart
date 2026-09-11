import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../sync/data/sync_service.dart';

class HealthSurveyRepository {
  HealthSurveyRepository(this._db);
  final AppDatabase _db;

  Future<void> submit({
    required String facilityName,
    required double latitude,
    required double longitude,
    String? operatorName,
    String? networkType,
    int? signalDbm,
    double? downloadMbps,
    double? uploadMbps,
    int? pingMs,
    bool? emergencyCommunicationAvailable,
  }) async {
    final id = const Uuid().v4();
    await _db.into(_db.healthFacilitySurveys).insert(
          HealthFacilitySurveysCompanion.insert(
            id: id,
            facilityName: facilityName,
            latitude: latitude,
            longitude: longitude,
            operatorName: Value(operatorName),
            networkType: Value(networkType),
            signalDbm: Value(signalDbm),
            downloadMbps: Value(downloadMbps),
            uploadMbps: Value(uploadMbps),
            pingMs: Value(pingMs),
            emergencyCommunicationAvailable:
                Value(emergencyCommunicationAvailable),
            createdAt: DateTime.now(),
          ),
        );

    await _db.into(_db.syncQueueItems).insert(
          SyncQueueItemsCompanion.insert(
            entityType: 'health',
            entityId: id,
            createdAt: DateTime.now(),
          ),
        );
  }
}

final Provider<HealthSurveyRepository> healthSurveyRepositoryProvider =
    Provider<HealthSurveyRepository>((ref) {
  return HealthSurveyRepository(ref.watch(appDatabaseProvider));
});
