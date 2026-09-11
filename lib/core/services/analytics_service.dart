import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// Thin wrapper over Firebase Analytics. Every call is wrapped so a
/// missing/unconfigured Firebase project (see main.dart's offline/demo
/// fallback) never crashes the app — analytics is diagnostic, not a
/// dependency the rest of the app relies on. Only anonymous, aggregate
/// usage events are logged here; no measurement content, GPS
/// coordinates, or report text is ever sent as an analytics parameter.
class AnalyticsService {
  AnalyticsService(this._analytics);
  final FirebaseAnalytics? _analytics;

  Future<void> logNetworkTestCompleted({
    required bool hasSignalData,
    required bool hasSpeedData,
  }) => _log_('network_test_completed', {
        'has_signal_data': hasSignalData,
        'has_speed_data': hasSpeedData,
      });

  Future<void> logNetworkTestCancelled() => _log_('network_test_cancelled');

  Future<void> logReportSubmitted(String category) =>
      _log_('report_submitted', {'category': category});

  Future<void> logSurveySubmitted(String surveyType) =>
      _log_('survey_submitted', {'survey_type': surveyType});

  Future<void> logPdfExported() => _log_('pdf_report_exported');

  Future<void> setScreen(String screenName) async {
    try {
      await _analytics?.logScreenView(screenName: screenName);
    } catch (error) {
      _log.w('Analytics screen view failed: $error');
    }
  }

  Future<void> _log_(String name, [Map<String, Object>? params]) async {
    try {
      await _analytics?.logEvent(name: name, parameters: params);
    } catch (error) {
      _log.w('Analytics event "$name" failed: $error');
    }
  }
}

final Provider<FirebaseAnalytics?> firebaseAnalyticsProvider =
    Provider<FirebaseAnalytics?>((ref) {
  try {
    return FirebaseAnalytics.instance;
  } catch (_) {
    return null; // Firebase not initialized (offline/demo scaffold mode).
  }
});

final Provider<AnalyticsService> analyticsServiceProvider =
    Provider<AnalyticsService>((ref) {
  return AnalyticsService(ref.watch(firebaseAnalyticsProvider));
});
