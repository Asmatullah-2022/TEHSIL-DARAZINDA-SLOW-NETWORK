import 'package:darazinda_connect/features/dead_zone/data/dead_zone_analyzer.dart';
import 'package:darazinda_connect/features/network_test/domain/entities/measurement.dart';
import 'package:flutter_test/flutter_test.dart';

Measurement _measurement({
  required double lat,
  required double lng,
  int? signalDbm,
  DateTime? measuredAt,
}) {
  return Measurement(
    id: 'm-${lat}_$lng-${measuredAt?.millisecondsSinceEpoch}',
    anonymousDeviceId: 'device-1',
    latitude: lat,
    longitude: lng,
    signalDbm: signalDbm,
    measuredAt: measuredAt ?? DateTime.now(),
  );
}

void main() {
  final analyzer = DeadZoneAnalyzer();

  test('a single poor measurement is never flagged as a dead zone', () {
    final result = analyzer.analyze([
      _measurement(lat: 31.935, lng: 70.594, signalDbm: -120),
    ]);
    expect(result, isEmpty);
  });

  test('flags a cluster once enough poor measurements accumulate', () {
    final measurements = List.generate(
      6,
      (i) => _measurement(
        lat: 31.935 + (i * 0.0001),
        lng: 70.594,
        signalDbm: -115,
        measuredAt: DateTime.now().subtract(Duration(days: i)),
      ),
    );

    final result = analyzer.analyze(measurements);
    expect(result, isNotEmpty);
    expect(result.first.measurementCount, greaterThanOrEqualTo(5));
    expect(result.first.poorSignalRatio, greaterThanOrEqualTo(0.6));
  });

  test('does not flag a cluster with mostly good signal', () {
    final measurements = List.generate(
      6,
      (i) => _measurement(
        lat: 31.935 + (i * 0.0001),
        lng: 70.594,
        signalDbm: -70,
      ),
    );

    final result = analyzer.analyze(measurements);
    expect(result, isEmpty);
  });

  test('measurements far apart are not clustered together', () {
    final near = List.generate(
      6,
      (i) => _measurement(lat: 31.935, lng: 70.594, signalDbm: -115),
    );
    final far = [_measurement(lat: 32.5, lng: 71.2, signalDbm: -118)];

    final result = analyzer.analyze([...near, ...far]);
    // Only the tight cluster meets the minimum sample size.
    expect(result.length, 1);
  });
}
