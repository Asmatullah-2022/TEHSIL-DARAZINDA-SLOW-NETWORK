import 'dart:math' as math;

import '../../../core/constants/app_constants.dart';
import '../../network_test/domain/entities/measurement.dart';
import '../domain/probable_dead_zone.dart';

/// Groups measurements by proximity and flags clusters with enough
/// repeated evidence of poor connectivity as a "Probable Connectivity
/// Problem". A single measurement, however weak, is NEVER enough —
/// [AppConstants.deadZoneMinMeasurements] and
/// [AppConstants.deadZonePoorSignalRatio] gate the label, and results
/// are always phrased as "probable", never "confirmed" or "permanent".
class DeadZoneAnalyzer {
  List<ProbableDeadZone> analyze(List<Measurement> measurements) {
    final cutoff =
        DateTime.now().subtract(const Duration(days: AppConstants.deadZoneRecencyDays));
    final recent = measurements.where((m) => m.measuredAt.isAfter(cutoff)).toList();

    final clusters = _clusterByProximity(
      recent,
      AppConstants.deadZoneAggregationRadiusMeters.toDouble(),
    );

    final results = <ProbableDeadZone>[];
    for (final cluster in clusters) {
      if (cluster.length < AppConstants.deadZoneMinMeasurements) continue;

      final poorCount = cluster.where((m) => m.signalQuality.isPoor).length;
      final poorRatio = poorCount / cluster.length;
      if (poorRatio < AppConstants.deadZonePoorSignalRatio) continue;

      final dbmSamples =
          cluster.where((m) => m.signalDbm != null).map((m) => m.signalDbm!).toList();
      final double? avgSignal = dbmSamples.isEmpty
          ? null
          : dbmSamples.reduce((a, b) => a + b) / dbmSamples.length;

      final operators = cluster
          .map((m) => m.operatorName)
          .whereType<String>()
          .toSet()
          .toList();

      final centerLat =
          cluster.map((m) => m.latitude).reduce((a, b) => a + b) / cluster.length;
      final centerLng =
          cluster.map((m) => m.longitude).reduce((a, b) => a + b) / cluster.length;

      final lastMeasured = cluster
          .map((m) => m.measuredAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);

      results.add(
        ProbableDeadZone(
          centerLatitude: centerLat,
          centerLongitude: centerLng,
          measurementCount: cluster.length,
          averageSignalDbm: avgSignal,
          poorSignalRatio: poorRatio,
          affectedOperators: operators,
          lastMeasuredAt: lastMeasured,
        ),
      );
    }

    results.sort((a, b) => b.poorSignalRatio.compareTo(a.poorSignalRatio));
    return results;
  }

  /// Simple greedy proximity clustering (haversine distance). Adequate
  /// for a Tehsil-scale dataset; can be swapped for a spatial index
  /// (e.g. geohash grid) if the dataset grows to province/country scale.
  List<List<Measurement>> _clusterByProximity(
    List<Measurement> measurements,
    double radiusMeters,
  ) {
    final remaining = List<Measurement>.from(measurements);
    final clusters = <List<Measurement>>[];

    while (remaining.isNotEmpty) {
      final seed = remaining.removeAt(0);
      final cluster = <Measurement>[seed];

      remaining.removeWhere((m) {
        final withinRadius =
            _distanceMeters(seed.latitude, seed.longitude, m.latitude, m.longitude) <=
                radiusMeters;
        if (withinRadius) cluster.add(m);
        return withinRadius;
      });

      clusters.add(cluster);
    }
    return clusters;
  }

  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (3.141592653589793 / 180.0);
}
