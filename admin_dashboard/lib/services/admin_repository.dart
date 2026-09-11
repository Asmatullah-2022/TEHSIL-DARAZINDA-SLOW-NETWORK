import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_models.dart';

/// Reads/writes the same collections the mobile app writes to (see
/// `docs/DATA_MODEL.md`). Report status updates go through this
/// repository so they respect the `isAdmin()` Firestore rule — the
/// signed-in admin account must carry the `admin: true` custom claim.
class AdminRepository {
  final _firestore = FirebaseFirestore.instance;

  Stream<List<AdminMeasurement>> watchMeasurements({int limit = 500}) {
    return _firestore
        .collection('measurements')
        .orderBy('measuredAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(AdminMeasurement.fromDoc).toList());
  }

  Stream<List<AdminReport>> watchReports({String? statusFilter}) {
    Query<Map<String, dynamic>> query =
        _firestore.collection('reports').orderBy('createdAt', descending: true);
    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }
    return query.snapshots().map(
        (s) => s.docs.map((d) => AdminReport.fromDoc(d)).toList());
  }

  Future<void> updateReportStatus(String reportId, String newStatus) {
    return _firestore.collection('reports').doc(reportId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<int> watchCollectionCount(String collection) {
    return _firestore
        .collection(collection)
        .snapshots()
        .map((s) => s.size);
  }
}
