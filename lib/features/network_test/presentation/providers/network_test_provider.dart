import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/analytics_service.dart';
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
  cancelled,
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
      stage != TestStage.error &&
      stage != TestStage.cancelled;

  /// Only the download/upload legs are actually abortable — GPS lookup,
  /// telephony reads, and the local save are fast and not worth
  /// offering a cancel button for.
  bool get isCancellable =>
      stage == TestStage.testingDownload || stage == TestStage.testingUpload;

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
  NetworkTestNotifier(this._repository, this._analytics)
      : super(const NetworkTestState());

  final MeasurementRepository _repository;
  final AnalyticsService _analytics;

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
      unawaited(_analytics.logNetworkTestCompleted(
        hasSignalData: measurement.signalDbm != null,
        hasSpeedData: measurement.hasSpeedData,
      ));
    } on MeasurementCancelledException {
      state = const NetworkTestState(stage: TestStage.cancelled);
      unawaited(_analytics.logNetworkTestCancelled());
    } on MeasurementException catch (e) {
      state = NetworkTestState(stage: TestStage.error, errorCode: e.message);
    } catch (_) {
      state = const NetworkTestState(
        stage: TestStage.error,
        errorCode: 'unknown_error',
      );
    }
  }

  /// Stops the in-flight test (see
  /// [MeasurementRepository.cancelRunningTest]). No partial result is
  /// saved — the user can start a fresh test whenever they're ready.
  void cancelTest() => _repository.cancelRunningTest();

  void reset() => state = const NetworkTestState();
}

final StateNotifierProvider<NetworkTestNotifier, NetworkTestState>
    networkTestProvider =
    StateNotifierProvider<NetworkTestNotifier, NetworkTestState>((ref) {
  return NetworkTestNotifier(
    ref.watch(measurementRepositoryProvider),
    ref.watch(analyticsServiceProvider),
  );
});

final StreamProvider<List<Measurement>> allMeasurementsProvider =
    StreamProvider<List<Measurement>>((ref) {
  return ref.watch(measurementRepositoryProvider).watchAllMeasurements();
});

final FutureProvider<Measurement?> lastMeasurementProvider =
    FutureProvider<Measurement?>((ref) {
  return ref.watch(measurementRepositoryProvider).getLastMeasurement();
});
