import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../dead_zone/presentation/screens/dead_zone_list_screen.dart';
import '../../../network_test/data/repositories/community_measurement_repository.dart';
import '../../../operator_comparison/presentation/screens/operator_comparison_screen.dart';
import '../../../report_problem/data/report_repository.dart';

/// Community statistics, explicitly labeled as crowdsourced. Numbers
/// come only from what has actually been measured/reported — combining
/// this device's own local data with the shared Firestore community
/// dataset — never extrapolated or estimated beyond the underlying
/// sample.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measurements = ref.watch(combinedMeasurementsProvider).value ?? [];
    final myReports = ref.watch(myReportsProvider).value ?? [];
    final communityReportCount = ref.watch(communityReportCountProvider).value;
    // Falls back to this device's own report count if the community
    // count isn't available (offline / Firebase not configured) —
    // still real data, just a smaller real sample, never fabricated.
    final totalReports = communityReportCount ?? myReports.length;
    final deadZones = ref.watch(probableDeadZonesProvider);
    final operatorStats = ref.watch(operatorStatsProvider);

    final networkTypeCounts = <String, int>{};
    for (final m in measurements) {
      final t = m.networkType ?? 'Unknown';
      networkTypeCounts[t] = (networkTypeCounts[t] ?? 0) + 1;
    }

    final downloads =
        measurements.map((m) => m.downloadMbps).whereType<double>().toList();
    final avgDownload = downloads.isEmpty
        ? null
        : downloads.reduce((a, b) => a + b) / downloads.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Community Statistics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentCyan.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'These statistics are crowdsourced from community '
              'measurements and reports. They reflect what has actually '
              'been collected, not an official survey.',
              style: TextStyle(fontSize: 12.5),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _StatTile(label: 'Total Measurements', value: '${measurements.length}'),
              _StatTile(label: 'Total Reports', value: '$totalReports'),
              _StatTile(
                  label: 'Probable Dead Zones', value: '${deadZones.length}'),
              _StatTile(
                label: 'Avg. Download',
                value: avgDownload != null
                    ? '${avgDownload.toStringAsFixed(1)} Mbps'
                    : 'Not available',
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Network Type Distribution', style: AppTextStyles.title),
          const SizedBox(height: 8),
          if (networkTypeCounts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No data yet.'),
            )
          else
            ...networkTypeCounts.entries.map(
              (e) => _DistributionBar(
                label: e.key,
                count: e.value,
                total: measurements.length,
              ),
            ),
          const SizedBox(height: 20),
          const Text('Operator Distribution', style: AppTextStyles.title),
          const SizedBox(height: 8),
          if (operatorStats.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No data yet.'),
            )
          else
            ...operatorStats.map(
              (s) => _DistributionBar(
                label: s.operatorName,
                count: s.sampleCount,
                total: measurements.length,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final String value;

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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: AppTextStyles.metricValue.copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _DistributionBar extends StatelessWidget {
  const _DistributionBar({
    required this.label,
    required this.count,
    required this.total,
  });

  final String label;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.body)),
              Text('$count', style: AppTextStyles.bodySecondary),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}
