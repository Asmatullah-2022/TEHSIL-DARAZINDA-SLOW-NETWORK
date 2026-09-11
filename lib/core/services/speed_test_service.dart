import 'dart:io';

import 'package:dio/dio.dart';

import '../constants/app_constants.dart';

class SpeedTestResult {
  const SpeedTestResult({this.downloadMbps, this.uploadMbps, this.pingMs});

  final double? downloadMbps;
  final double? uploadMbps;
  final int? pingMs;
}

class SpeedTestCancelledException implements Exception {
  const SpeedTestCancelledException();
}

/// Measures real download/upload throughput and latency against public
/// endpoints. Results reflect actual transferred bytes over wall-clock
/// time — never simulated or randomized. Any leg that fails (timeout,
/// no connectivity) is reported as `null`, surfaced as "Not available"
/// rather than a fabricated number.
///
/// Bandwidth is bounded on both legs: the download test stops itself
/// once [AppConstants.speedTestMaxDownloadBytes] have been received,
/// regardless of how much longer the timeout window has left — so a
/// fast connection cannot pull the entire remote test file (important
/// for users on a limited/expensive mobile data plan, per the "be
/// careful about bandwidth consumption" requirement). A slow connection
/// is still bounded by [AppConstants.speedTestFileTimeout] as before.
///
/// The whole test (download, upload, or ping) can be aborted mid-flight
/// via [cancel] — wired to a "Cancel Test" action in the UI so the user
/// can always stop early rather than being forced to wait out a timeout.
class SpeedTestService {
  SpeedTestService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  CancelToken? _activeCancelToken;

  /// Aborts whichever leg (download/upload) is currently in flight.
  /// Safe to call even if nothing is running.
  void cancel() {
    _activeCancelToken?.cancel('User cancelled the test.');
  }

  /// Measures latency as a real TCP connect round-trip to
  /// [AppConstants.pingHost]:[AppConstants.pingPort]. A bare IP address
  /// is used deliberately (see AppConstants) so this measures actual
  /// network round-trip time rather than DNS resolution time — the
  /// previous implementation looked up an IP literal via
  /// `InternetAddress.lookup`, which most resolvers short-circuit
  /// locally without any network I/O at all, making it meaningless as
  /// a latency probe.
  Future<int?> measurePingMs() async {
    Socket? socket;
    try {
      final stopwatch = Stopwatch()..start();
      socket = await Socket.connect(
        AppConstants.pingHost,
        AppConstants.pingPort,
        timeout: const Duration(seconds: 6),
      );
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      return null;
    } finally {
      socket?.destroy();
    }
  }

  Future<double?> measureDownloadMbps({
    void Function(double fractionComplete)? onProgress,
  }) async {
    final cancelToken = CancelToken();
    _activeCancelToken = cancelToken;
    final stopwatch = Stopwatch()..start();
    int lastReceivedBytes = 0;

    try {
      await _dio.get<List<int>>(
        AppConstants.speedTestDownloadUrl,
        cancelToken: cancelToken,
        options: Options(responseType: ResponseType.stream),
        onReceiveProgress: (received, total) {
          lastReceivedBytes = received;
          final cappedFraction =
              received / AppConstants.speedTestMaxDownloadBytes;
          onProgress?.call(cappedFraction.clamp(0, 1).toDouble());

          if (received >= AppConstants.speedTestMaxDownloadBytes) {
            // Enough data collected for a stable estimate — stop the
            // transfer here rather than continuing to download the
            // remainder of the remote file.
            cancelToken.cancel(_dataCapReached);
          }
        },
      ).timeout(AppConstants.speedTestFileTimeout);

      stopwatch.stop();
      return _mbps(lastReceivedBytes, stopwatch.elapsedMilliseconds);
    } on DioException catch (e) {
      stopwatch.stop();
      if (e.type == DioExceptionType.cancel) {
        if (e.error == _dataCapReached) {
          // Intentional self-cancellation once the data cap was hit —
          // this is a successful measurement, not a failure.
          return _mbps(lastReceivedBytes, stopwatch.elapsedMilliseconds);
        }
        // User-initiated cancel via [cancel()] — surface as "no result"
        // rather than a fabricated speed from a partial, user-aborted
        // sample.
        return null;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      _activeCancelToken = null;
    }
  }

  Future<double?> measureUploadMbps() async {
    final cancelToken = CancelToken();
    _activeCancelToken = cancelToken;

    try {
      // Fixed-size zero-filled payload — small enough to keep data
      // usage predictable and bounded regardless of connection speed.
      final payload =
          List<int>.filled(AppConstants.speedTestUploadBytes, 0);
      final stopwatch = Stopwatch()..start();

      await _dio
          .post<dynamic>(
            AppConstants.speedTestUploadUrl,
            data: Stream.fromIterable([payload]),
            cancelToken: cancelToken,
            options: Options(
              headers: {
                Headers.contentLengthHeader: payload.length,
                Headers.contentTypeHeader: 'application/octet-stream',
              },
            ),
          )
          .timeout(AppConstants.speedTestFileTimeout);

      stopwatch.stop();
      return _mbps(payload.length, stopwatch.elapsedMilliseconds);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return null;
      return null;
    } catch (_) {
      return null;
    } finally {
      _activeCancelToken = null;
    }
  }

  static const String _dataCapReached = 'darazinda_connect_data_cap_reached';

  double? _mbps(int bytes, int elapsedMs) {
    final seconds = elapsedMs / 1000.0;
    if (seconds <= 0 || bytes <= 0) return null;
    final megabits = (bytes * 8) / 1000000.0;
    return double.parse((megabits / seconds).toStringAsFixed(2));
  }
}
