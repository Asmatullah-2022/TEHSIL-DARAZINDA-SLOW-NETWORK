import 'problem_category.dart';

/// A citizen-submitted connectivity problem report. Submitting this
/// report only saves evidence into Darazinda Connect's own database
/// (local, then Firestore once synced) — it does NOT constitute an
/// official complaint filed with any telecom operator or government
/// authority unless a specific integration for that is explicitly
/// documented and enabled.
class ProblemReport {
  const ProblemReport({
    required this.id,
    required this.anonymousDeviceId,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
    this.description,
    this.photoLocalPath,
    this.photoRemoteUrl,
    this.operatorName,
    this.networkType,
    this.linkedMeasurementId,
    this.signalDbm,
    this.downloadMbps,
    this.uploadMbps,
    this.pingMs,
    this.gpsAccuracyMeters,
    this.status = ReportStatus.pending,
  });

  final String id;
  final String? userId;
  final String anonymousDeviceId;
  final ProblemCategory category;
  final String? description;
  final String? photoLocalPath;
  final String? photoRemoteUrl;
  final double latitude;
  final double longitude;
  final String? operatorName;
  final String? networkType;
  final String? linkedMeasurementId;

  /// Snapshot of the citizen's most recent measurement at the moment
  /// this report was submitted (null if no measurement was available
  /// on-device yet — never a fabricated value). Stored on the report
  /// itself, not just referenced via [linkedMeasurementId], so the
  /// evidence in "My Reports" and the exported PDF is self-contained
  /// even if the original measurement is later pruned.
  final int? signalDbm;
  final double? downloadMbps;
  final double? uploadMbps;
  final int? pingMs;
  final double? gpsAccuracyMeters;

  final ReportStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}
