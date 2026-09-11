import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A single labeled measurement value. Pass `null` for [value] to render
/// the required "Not available on this device" fallback instead of
/// guessing or hiding the metric.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.notAvailableText = 'Not available on this device',
  });

  final String label;
  final String? value;
  final IconData? icon;
  final Color? valueColor;
  final String notAvailableText;

  @override
  Widget build(BuildContext context) {
    final bool available = value != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(label,
                    style: AppTextStyles.caption,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            available ? value! : notAvailableText,
            style: available
                ? AppTextStyles.metricValue.copyWith(
                    fontSize: 18,
                    color: valueColor ?? AppColors.textPrimary,
                  )
                : AppTextStyles.bodySecondary.copyWith(fontStyle: FontStyle.italic),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
