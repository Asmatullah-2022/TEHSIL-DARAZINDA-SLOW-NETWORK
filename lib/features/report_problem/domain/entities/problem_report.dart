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
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
}
