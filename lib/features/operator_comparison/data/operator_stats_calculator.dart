import '../../../core/constants/app_constants.dart';
import '../../network_test/domain/entities/measurement.dart';

class OperatorStats {
  const OperatorStats({
    required this.operatorName,
    required this.sampleCount,
    required this.avgDownloadMbps,
    required this.avgUploadMbps,
    required this.avgPingMs,
    required this.signalDistribution,
    required this.hasSufficientSamples,
  });

  final String operatorName;
  final int sampleCount;
  final double? avgDownloadMbps;
  final double? avgUploadMbps;
  final double? avgPingMs;

  /// Count of measurements per SignalQuality name (good/moderate/weak/
  /// veryWeak/unknown).
  final Map<String, int> signalDistribution;
  final bool hasSufficientSamples;
}

/// Computes operator statistics strictly from actual collected
/// measurements. Operators are only eligible for ranking/comparison
/// once they have at least [AppConstants.operatorComparisonMinSamples]
/// samples — below that, stats are still shown but flagged as
/// insufficient sample size rather than used to rank operators against
/// each other.
class OperatorStatsCalculator {
  List<OperatorStats> calculate(List<Measurement> measurements) {
    final byOperator = <String, List<Measurement>>{};
    for (final m in measurements) {
      final name = m.operatorName;
      if (name == null || name.isEmpty) continue;
      byOperator.putIfAbsent(name, () => []).add(m);
    }

    final results = <OperatorStats>[];
    byOperator.forEach((operatorName, list) {
      final downloads =
          list.map((m) => m.downloadMbps).whereType<double>().toList();
      final uploads =
          list.map((m) => m.uploadMbps).whereType<double>().toList();
      final pings = list.map((m) => m.pingMs).whereType<int>().toList();

      final distribution = <String, int>{};
      for (final m in list) {
        final key = m.signalQuality.name;
        distribution[key] = (distribution[key] ?? 0) + 1;
      }

      results.add(
        OperatorStats(
          operatorName: operatorName,
          sampleCount: list.length,
          avgDownloadMbps: _avg(downloads),
          avgUploadMbps: _avg(uploads),
          avgPingMs: pings.isEmpty
              ? null
              : pings.reduce((a, b) => a + b) / pings.length,
          signalDistribution: distribution,
          hasSufficientSamples:
              list.length >= AppConstants.operatorComparisonMinSamples,
        ),
      );
    });

    results.sort((a, b) => b.sampleCount.compareTo(a.sampleCount));
    return results;
  }

  double? _avg(List<double> values) {
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }
}
