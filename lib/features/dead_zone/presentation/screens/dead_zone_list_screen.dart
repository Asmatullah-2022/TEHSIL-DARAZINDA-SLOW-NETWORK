import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../network_test/presentation/providers/network_test_provider.dart';
import '../../data/dead_zone_analyzer.dart';
import '../../domain/probable_dead_zone.dart';

final Provider<DeadZoneAnalyzer> deadZoneAnalyzerProvider =
    Provider<DeadZoneAnalyzer>((ref) => DeadZoneAnalyzer());

final Provider<List<ProbableDeadZone>> probableDeadZonesProvider =
    Provider<List<ProbableDeadZone>>((ref) {
  final measurements = ref.watch(allMeasurementsProvider).value ?? [];
  return ref.watch(deadZoneAnalyzerProvider).analyze(measurements);
});

class DeadZoneListScreen extends ConsumerWidget {
  const DeadZoneListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zones = ref.watch(probableDeadZonesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Probable Connectivity Problems')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.signalWeak.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'These areas show a high rate of poor measurements from '
              'multiple tests. This is community-sourced evidence of a '
              'probable connectivity problem — not a confirmed or '
              'permanent outage assessment.',
              style: TextStyle(fontSize: 12.5),
            ),
          ),
          Expanded(
            child: zones.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No probable connectivity problems have been '
                        'identified yet. This requires several repeated '
                        'poor measurements in the same area.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: zones.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _DeadZoneCard(zone: zones[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DeadZoneCard extends StatelessWidget {
  const _DeadZoneCard({required this.zone});
  final ProbableDeadZone zone;

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
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.signalWeak, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Probable Connectivity Problem',
                    style: AppTextStyles.title),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _row('Measurements', '${zone.measurementCount}'),
          _row(
            'Average signal',
            zone.averageSignalDbm != null
                ? '${zone.averageSignalDbm!.toStringAsFixed(0)} dBm'
                : 'Not available on this device',
          ),
          _row('Poor signal rate',
              '${(zone.poorSignalRatio * 100).toStringAsFixed(0)}%'),
          _row(
            'Affected operator(s)',
            zone.affectedOperators.isEmpty
                ? 'Unknown'
                : zone.affectedOperators.join(', '),
          ),
          _row('Last measured',
              DateFormat.yMMMd().add_jm().format(zone.lastMeasuredAt)),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(label, style: AppTextStyles.bodySecondary)),
          Expanded(
              flex: 3,
              child: Text(value,
                  style: AppTextStyles.body, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
