import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/signal_quality.dart';
import '../../../network_test/domain/entities/measurement.dart';

class MapFilters {
  const MapFilters({
    this.operatorName,
    this.networkType,
    this.minSignal,
    this.dateFrom,
    this.dateTo,
    this.minDownloadMbps,
    this.minUploadMbps,
    this.maxPingMs,
  });

  final String? operatorName;
  final String? networkType;
  final SignalQuality? minSignal;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final double? minDownloadMbps;
  final double? minUploadMbps;
  final int? maxPingMs;

  MapFilters copyWith({
    String? operatorName,
    String? networkType,
    SignalQuality? minSignal,
    DateTime? dateFrom,
    DateTime? dateTo,
    double? minDownloadMbps,
    double? minUploadMbps,
    int? maxPingMs,
    bool clearOperator = false,
    bool clearNetworkType = false,
    bool clearMinSignal = false,
  }) {
    return MapFilters(
      operatorName: clearOperator ? null : (operatorName ?? this.operatorName),
      networkType:
          clearNetworkType ? null : (networkType ?? this.networkType),
      minSignal: clearMinSignal ? null : (minSignal ?? this.minSignal),
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      minDownloadMbps: minDownloadMbps ?? this.minDownloadMbps,
      minUploadMbps: minUploadMbps ?? this.minUploadMbps,
      maxPingMs: maxPingMs ?? this.maxPingMs,
    );
  }

  List<Measurement> apply(List<Measurement> input) {
    return input.where((m) {
      if (operatorName != null && m.operatorName != operatorName) {
        return false;
      }
      if (networkType != null && m.networkType != networkType) return false;
      if (minSignal != null && m.signalQuality.level < minSignal!.level) {
        return false;
      }
      if (dateFrom != null && m.measuredAt.isBefore(dateFrom!)) return false;
      if (dateTo != null && m.measuredAt.isAfter(dateTo!)) return false;
      if (minDownloadMbps != null &&
          (m.downloadMbps == null || m.downloadMbps! < minDownloadMbps!)) {
        return false;
      }
      if (minUploadMbps != null &&
          (m.uploadMbps == null || m.uploadMbps! < minUploadMbps!)) {
        return false;
      }
      if (maxPingMs != null && (m.pingMs == null || m.pingMs! > maxPingMs!)) {
        return false;
      }
      return true;
    }).toList();
  }
}

class MapFilterNotifier extends StateNotifier<MapFilters> {
  MapFilterNotifier() : super(const MapFilters());

  void update(MapFilters Function(MapFilters current) updater) {
    state = updater(state);
  }

  void clear() => state = const MapFilters();
}

final StateNotifierProvider<MapFilterNotifier, MapFilters> mapFilterProvider =
    StateNotifierProvider<MapFilterNotifier, MapFilters>(
        (ref) => MapFilterNotifier());
