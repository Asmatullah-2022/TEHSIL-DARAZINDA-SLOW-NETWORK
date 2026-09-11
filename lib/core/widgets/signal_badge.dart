import 'package:flutter/material.dart';

import '../constants/signal_quality.dart';
import '../theme/app_colors.dart';

/// Colored dot + label representing a [SignalQuality] level. This is
/// the single canonical visual for signal quality reused across the
/// dashboard, map, and dead-zone list so the color language stays
/// consistent app-wide.
class SignalBadge extends StatelessWidget {
  const SignalBadge({super.key, required this.quality, this.label});

  final SignalQuality quality;
  final String? label;

  String _defaultLabel() {
    switch (quality) {
      case SignalQuality.good:
        return 'Good';
      case SignalQuality.moderate:
        return 'Moderate';
      case SignalQuality.weak:
        return 'Weak';
      case SignalQuality.veryWeak:
        return 'Very Weak / No Service';
      case SignalQuality.unknown:
        return 'Not available';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forSignalLevel(quality.level);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label ?? _defaultLabel(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
