/// App-wide constants. Kept free of environment secrets — those live in
/// Firebase config files (`google-services.json`, `firebase_options.dart`)
/// which are generated per-environment and are NOT committed with real
/// credentials in this scaffold.
class AppConstants {
  AppConstants._();

  static const String appName = 'Darazinda Connect';
  static const String appLegalName = 'Tehsil Darazinda Slow Network';
  static const String packageId = 'pk.darazindaconnect.app';

  /// Global switch for clearly-marked demo/development data. Must be
  /// false in any release build — enforced by [isDemoModeAllowed].
  static const bool demoModeDefault = false;

  static bool get isDemoModeAllowed => !isReleaseBuild;
  static const bool isReleaseBuild =
      bool.fromEnvironment('dart.vm.product');

  // Dead-zone / "probable connectivity problem" thresholds. Configurable
  // here so policy can evolve without touching business logic. A single
  // measurement must NEVER be enough to flag a location.
  static const int deadZoneMinMeasurements = 5;
  static const double deadZonePoorSignalRatio = 0.6; // 60% of samples poor
  static const int deadZoneAggregationRadiusMeters = 150;
  static const int deadZoneRecencyDays = 90;

  // Operator comparison: minimum sample size before ranking is shown.
  static const int operatorComparisonMinSamples = 10;

  // Passive measurement cadence guardrails (battery/network friendly).
  static const Duration minTimeBetweenAutoTests = Duration(minutes: 30);

  static const Duration speedTestFileTimeout = Duration(seconds: 20);
  static const String speedTestDownloadUrl =
      'https://speed.hetzner.de/100MB.bin';
  static const String speedTestUploadUrl =
      'https://httpbin.org/post';
  static const String pingHost = '8.8.8.8';

  static const double defaultMapLat = 31.9350; // Darazinda Tehsil approx.
  static const double defaultMapLng = 70.5940;
  static const double defaultMapZoom = 12.5;

  static const String supportEmail = 'support@darazindaconnect.app';
  static const String privacyPolicyUrl =
      'https://darazindaconnect.app/privacy';
}

enum AppEnvironment { development, staging, production }
