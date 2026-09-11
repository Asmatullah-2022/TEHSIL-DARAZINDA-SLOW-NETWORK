import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../network_test/presentation/providers/network_test_provider.dart';
import '../../data/operator_stats_calculator.dart';

final Provider<OperatorStatsCalculator> operatorStatsCalculatorProvider =
    Provider<OperatorStatsCalculator>((ref) => OperatorStatsCalculator());

final Provider<List<OperatorStats>> operatorStatsProvider =
    Provider<List<OperatorStats>>((ref) {
  final measurements = ref.watch(allMeasurementsProvider).value ?? [];
  return ref.watch(operatorStatsCalculatorProvider).calculate(measurements);
});

class OperatorComparisonScreen extends ConsumerWidget {
  const OperatorComparisonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(operatorStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Operator Comparison')),
      body: stats.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No operator data yet. Run some network tests first.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: stats.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _OperatorCard(stats: stats[i]),
            ),
    );
  }
}

class _OperatorCard extends StatelessWidget {
  const _OperatorCard({required this.stats});
  final OperatorStats stats;

  @override
  Widget build(BuildContext context) {
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
              Expanded(
                child: Text(stats.operatorName, style: AppTextStyles.title),
              ),
              Text('${stats.sampleCount} samples',
                  style: AppTextStyles.caption),
            ],
          ),
          if (!stats.hasSufficientSamples) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.signalModerate.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Sample size too small for reliable ranking',
                style: TextStyle(fontSize: 11, color: AppColors.signalModerate),
              ),
            ),
          ],
          const SizedBox(height: 10),
          _metricRow('Avg. Download', stats.avgDownloadMbps != null
              ? '${stats.avgDownloadMbps!.toStringAsFixed(1)} Mbps'
              : 'Not available'),
          _metricRow('Avg. Upload', stats.avgUploadMbps != null
              ? '${stats.avgUploadMbps!.toStringAsFixed(1)} Mbps'
              : 'Not available'),
          _metricRow('Avg. Ping', stats.avgPingMs != null
              ? '${stats.avgPingMs!.toStringAsFixed(0)} ms'
              : 'Not available'),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodySecondary)),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
