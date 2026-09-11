import 'package:flutter/material.dart';

/// Civic-tech visual identity: professional blue/cyan with a distinct
/// green/yellow/orange/red scale reserved exclusively for connectivity
/// quality status (never reused for generic UI states).
class AppColors {
  AppColors._();

  static const Color primaryBlue = Color(0xFF0B5FA5);
  static const Color primaryBlueDark = Color(0xFF073A66);
  static const Color accentCyan = Color(0xFF00B8D9);

  static const Color background = Color(0xFFF5F8FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A2733);
  static const Color textSecondary = Color(0xFF5B6B7A);
  static const Color divider = Color(0xFFE1E8EF);

  // Connectivity quality scale — used ONLY for signal/quality indicators.
  static const Color signalGood = Color(0xFF2E9E44); // green
  static const Color signalModerate = Color(0xFFE6B400); // yellow
  static const Color signalWeak = Color(0xFFE8791A); // orange
  static const Color signalVeryWeak = Color(0xFFD32F2F); // red
  static const Color signalUnknown = Color(0xFF9AA6B2); // grey — no data

  static const Color pendingSync = Color(0xFF9C6ADE);
  static const Color success = signalGood;
  static const Color warning = signalWeak;
  static const Color error = signalVeryWeak;

  /// Maps a normalized signal quality (0-4, see SignalQuality) to a color.
  static Color forSignalLevel(int level) {
    switch (level) {
      case 4:
        return signalGood;
      case 3:
        return signalModerate;
      case 2:
        return signalWeak;
      case 1:
        return signalVeryWeak;
      default:
        return signalUnknown;
    }
  }
}
