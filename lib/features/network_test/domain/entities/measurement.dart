import 'package:equatable/equatable.dart';

import '../../../../core/constants/signal_quality.dart';

enum SyncStatus { pendingSync, synced, failed }

/// A completed (or in-progress) network measurement. `null` fields mean
/// the OS did not expose that metric on this device — the UI must show
/// "Not available on this device" rather than a fake value.
class Measurement extends Equatable {
  const Measurement({
    required this.id,
    required this.anonymousDeviceId,
    required this.latitude,
    required this.longitude,
    required this.measuredAt,
    this.userId,
    this.gpsAccuracyMeters,
    this.operatorName,
    this.networkType,
    this.signalDbm,
    this.signalAsu,
    this.simCountryIso,
    this.downloadMbps,
    this.uploadMbps,
    this.pingMs,
    this.isDemoData = false,
    this.syncStatus = SyncStatus.pendingSync,
  });

  final String id;
  final String? userId;
  final String anonymousDeviceId;

  final double latitude;
  final double longitude;
  final double? gpsAccuracyMeters;

  final String? operatorName;
  final String? networkType;
  final int? signalDbm;
  final int? signalAsu;
  final String? simCountryIso;

  final double? downloadMbps;
  final double? uploadMbps;
  final int? pingMs;

  final DateTime measuredAt;
  final bool isDemoData;
  final SyncStatus syncStatus;

  SignalQuality get signalQuality => SignalQuality.fromDbm(signalDbm);

  bool get hasSpeedData => downloadMbps != null || uploadMbps != null;

  @override
  List<Object?> get props => [
        id,
        userId,
        anonymousDeviceId,
        latitude,
        longitude,
        gpsAccuracyMeters,
        operatorName,
        networkType,
        signalDbm,
        signalAsu,
        simCountryIso,
        downloadMbps,
        uploadMbps,
        pingMs,
        measuredAt,
        isDemoData,
        syncStatus,
      ];
}
