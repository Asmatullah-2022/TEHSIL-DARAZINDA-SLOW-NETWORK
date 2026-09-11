import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/signal_quality.dart';
import '../../../network_test/data/repositories/community_measurement_repository.dart';
import '../providers/map_filter_provider.dart';

class MapFilterSheet extends ConsumerWidget {
  const MapFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measurements = ref.watch(combinedMeasurementsProvider).value ?? [];
    final operators = measurements
        .map((m) => m.operatorName)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    final networkTypes = measurements
        .map((m) => m.networkType)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();

    final filters = ref.watch(mapFilterProvider);
    final notifier = ref.read(mapFilterProvider.notifier);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Filter Map',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(
                onPressed: () => notifier.clear(),
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final op in operators)
                ChoiceChip(
                  label: Text(op),
                  selected: filters.operatorName == op,
                  onSelected: (selected) => notifier.update(
                    (c) => c.copyWith(
                      operatorName: selected ? op : null,
                      clearOperator: !selected,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final type in networkTypes)
                ChoiceChip(
                  label: Text(type),
                  selected: filters.networkType == type,
                  onSelected: (selected) => notifier.update(
                    (c) => c.copyWith(
                      networkType: selected ? type : null,
                      clearNetworkType: !selected,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final q in [
                SignalQuality.good,
                SignalQuality.moderate,
                SignalQuality.weak,
              ])
                ChoiceChip(
                  label: Text('${q.name}+'),
                  selected: filters.minSignal == q,
                  onSelected: (selected) => notifier.update(
                    (c) => c.copyWith(
                      minSignal: selected ? q : null,
                      clearMinSignal: !selected,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
