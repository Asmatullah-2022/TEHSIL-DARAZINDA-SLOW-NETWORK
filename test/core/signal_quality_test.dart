import 'package:darazinda_connect/core/constants/signal_quality.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('null dBm maps to unknown, never a guessed quality', () {
    expect(SignalQuality.fromDbm(null), SignalQuality.unknown);
  });

  test('strong signal maps to good', () {
    expect(SignalQuality.fromDbm(-65), SignalQuality.good);
  });

  test('very weak signal maps to veryWeak and is flagged as poor', () {
    final q = SignalQuality.fromDbm(-118);
    expect(q, SignalQuality.veryWeak);
    expect(q.isPoor, isTrue);
  });

  test('moderate signal is not flagged as poor', () {
    final q = SignalQuality.fromDbm(-90);
    expect(q, SignalQuality.moderate);
    expect(q.isPoor, isFalse);
  });
}
