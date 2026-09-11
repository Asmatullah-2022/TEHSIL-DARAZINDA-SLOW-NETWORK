import 'package:darazinda_connect/features/network_test/domain/entities/measurement.dart';
import 'package:darazinda_connect/features/operator_comparison/data/operator_stats_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

Measurement _m(String op, {double? down, double? up, int? ping}) {
  return Measurement(
    id: 'id-${op}_$down$up$ping',
    anonymousDeviceId: 'device-1',
    latitude: 31.9,
    longitude: 70.5,
    operatorName: op,
    downloadMbps: down,
    uploadMbps: up,
    pingMs: ping,
    measuredAt: DateTime.now(),
  );
}

void main() {
  final calculator = OperatorStatsCalculator();

  test('computes averages only from actual non-null samples', () {
    final stats = calculator.calculate([
      _m('Jazz', down: 10, up: 2, ping: 40),
      _m('Jazz', down: 20, up: null, ping: 60),
    ]);

    final jazz = stats.firstWhere((s) => s.operatorName == 'Jazz');
    expect(jazz.avgDownloadMbps, 15);
    expect(jazz.avgUploadMbps, 2); // only one non-null sample
    expect(jazz.avgPingMs, 50);
  });

  test('flags operators below the minimum sample size as insufficient', () {
    final stats = calculator.calculate([_m('Zong', down: 5)]);
    final zong = stats.firstWhere((s) => s.operatorName == 'Zong');
    expect(zong.hasSufficientSamples, isFalse);
  });

  test('measurements without an operator name are ignored', () {
    final stats = calculator.calculate([
      Measurement(
        id: 'no-op',
        anonymousDeviceId: 'd1',
        latitude: 0,
        longitude: 0,
        measuredAt: DateTime.now(),
      ),
    ]);
    expect(stats, isEmpty);
  });
}
