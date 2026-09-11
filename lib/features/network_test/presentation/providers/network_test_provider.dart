import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/measurement_repository.dart';
import '../../domain/entities/measurement.dart';

enum TestStage {
  idle,
  locating,
  readingTelephony,
  testingPing,
  testingDownload,
  testingUpload,
  saving,
  done,
  error,
}

class NetworkTestState {
  const NetworkTestState({
    this.stage = TestStage.idle,
    this.result,
    this.errorCode,
  });

  final TestStage stage;
  final Measurement? result;
  final String? errorCode;

  bool get isRunning => stage != TestStage.idle &&
      stage != TestStage.done &&
      stage != TestStage.error;

  NetworkTestState copyWith({
    TestStage? stage,
    Measurement? result,
    String? errorCode,
  }) {
    return NetworkTestState(
      stage: stage ?? this.stage,
      result: result ?? this.result,
      errorCode: errorCode,
    );
  }
}

class NetworkTestNotifier extends StateNotifier<NetworkTestState> {
  NetworkTestNotifier(this._repository) : super(const NetworkTestState());

  final MeasurementRepository _repository;

  static const Map<String, TestStage> _stageMap = {
    'locating': TestStage.locating,
    'reading_telephony': TestStage.readingTelephony,
    'testing_ping': TestStage.testingPing,
    'testing_download': TestStage.testingDownload,
    'testing_upload': TestStage.testingUpload,
    'saving': TestStage.saving,
  };

  Future<void> runTest() async {
    state = const NetworkTestState(stage: TestStage.locating);
    try {
      final measurement = await _repository.runFullTest(
        onStage: (stageKey) {
          final stage = _stageMap[stageKey];
          if (stage != null) state = state.copyWith(stage: stage);
        },
      );
      state = NetworkTestState(stage: TestStage.done, result: measurement);
    } on MeasurementException catch (e) {
      state = NetworkTestState(stage: TestStage.error, errorCode: e.message);
    } catch (_) {
      state = const NetworkTestState(
        stage: TestStage.error,
        errorCode: 'unknown_error',
      );
    }
  }

  void reset() => state = const NetworkTestState();
}

final StateNotifierProvider<NetworkTestNotifier, NetworkTestState>
    networkTestProvider =
    StateNotifierProvider<NetworkTestNotifier, NetworkTestState>((ref) {
  return NetworkTestNotifier(ref.watch(measurementRepositoryProvider));
});

final StreamProvider<List<Measurement>> allMeasurementsProvider =
    StreamProvider<List<Measurement>>((ref) {
  return ref.watch(measurementRepositoryProvider).watchAllMeasurements();
});

final FutureProvider<Measurement?> lastMeasurementProvider =
    FutureProvider<Measurement?>((ref) {
  return ref.watch(measurementRepositoryProvider).getLastMeasurement();
});
