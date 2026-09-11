import 'dart:io';

import 'package:dio/dio.dart';

import '../constants/app_constants.dart';

class SpeedTestResult {
  const SpeedTestResult({this.downloadMbps, this.uploadMbps, this.pingMs});

  final double? downloadMbps;
  final double? uploadMbps;
  final int? pingMs;
}

/// Measures real download/upload throughput and latency against public
/// endpoints. Results reflect actual transferred bytes over wall-clock
/// time — never simulated or randomized. Any leg that fails (timeout,
/// no connectivity) is reported as `null`, surfaced as "Not available"
/// rather than a fabricated number.
class SpeedTestService {
  SpeedTestService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<int?> measurePingMs() async {
    try {
      final stopwatch = Stopwatch()..start();
      final result = await InternetAddress.lookup('dns.google')
          .timeout(const Duration(seconds: 6));
      stopwatch.stop();
      if (result.isEmpty) return null;
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      return null;
    }
  }

  Future<double?> measureDownloadMbps({
    void Function(double fractionComplete)? onProgress,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();
      int totalBytes = 0;

      final response = await _dio.get<List<int>>(
        AppConstants.speedTestDownloadUrl,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          totalBytes = received;
          if (total > 0) onProgress?.call(received / total);
        },
      ).timeout(AppConstants.speedTestFileTimeout);

      stopwatch.stop();
      totalBytes = response.data?.length ?? totalBytes;
      final seconds = stopwatch.elapsedMilliseconds / 1000.0;
      if (seconds <= 0 || totalBytes == 0) return null;

      final megabits = (totalBytes * 8) / 1000000.0;
      return double.parse((megabits / seconds).toStringAsFixed(2));
    } catch (_) {
      return null;
    }
  }

  Future<double?> measureUploadMbps() async {
    try {
      // 2MB of pseudo-random-free zero-filled payload is sufficient to
      // estimate upload throughput without wasting user data.
      final payload = List<int>.filled(2 * 1024 * 1024, 0);
      final stopwatch = Stopwatch()..start();

      await _dio
          .post<dynamic>(
            AppConstants.speedTestUploadUrl,
            data: Stream.fromIterable([payload]),
            options: Options(
              headers: {
                Headers.contentLengthHeader: payload.length,
                Headers.contentTypeHeader: 'application/octet-stream',
              },
            ),
          )
          .timeout(AppConstants.speedTestFileTimeout);

      stopwatch.stop();
      final seconds = stopwatch.elapsedMilliseconds / 1000.0;
      if (seconds <= 0) return null;

      final megabits = (payload.length * 8) / 1000000.0;
      return double.parse((megabits / seconds).toStringAsFixed(2));
    } catch (_) {
      return null;
    }
  }
}
