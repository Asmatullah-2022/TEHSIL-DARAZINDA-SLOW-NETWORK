import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMeasurement {
  AdminMeasurement({
    required this.id,
    required this.lat,
    required this.lng,
    this.operatorName,
    this.networkType,
    this.signalDbm,
    this.downloadMbps,
    this.uploadMbps,
    this.pingMs,
    this.measuredAt,
  });

  final String id;
  final double lat;
  final double lng;
  final String? operatorName;
  final String? networkType;
  final int? signalDbm;
  final double? downloadMbps;
  final double? uploadMbps;
  final int? pingMs;
  final DateTime? measuredAt;

  factory AdminMeasurement.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final GeoPoint? point = data['location'] as GeoPoint?;
    return AdminMeasurement(
      id: doc.id,
      lat: point?.latitude ?? 0,
      lng: point?.longitude ?? 0,
      operatorName: data['operator'] as String?,
      networkType: data['networkType'] as String?,
      signalDbm: (data['signalDbm'] as num?)?.toInt(),
      downloadMbps: (data['downloadMbps'] as num?)?.toDouble(),
      uploadMbps: (data['uploadMbps'] as num?)?.toDouble(),
      pingMs: (data['pingMs'] as num?)?.toInt(),
      measuredAt: (data['measuredAt'] as Timestamp?)?.toDate(),
    );
  }
}

class AdminReport {
  AdminReport({
    required this.id,
    required this.category,
    required this.status,
    this.description,
    this.operatorName,
    this.networkType,
    this.createdAt,
  });

  final String id;
  final String category;
  final String status;
  final String? description;
  final String? operatorName;
  final String? networkType;
  final DateTime? createdAt;

  factory AdminReport.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AdminReport(
      id: doc.id,
      category: data['category'] as String? ?? 'other',
      status: data['status'] as String? ?? 'pending',
      description: data['description'] as String?,
      operatorName: data['operator'] as String?,
      networkType: data['networkType'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
