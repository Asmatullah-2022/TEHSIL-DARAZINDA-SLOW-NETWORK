import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../network_test/domain/entities/measurement.dart';
import '../../../network_test/presentation/providers/network_test_provider.dart';
import '../widgets/map_filter_sheet.dart';
import '../providers/map_filter_provider.dart';

/// Community signal map. Uses OpenStreetMap tiles (ODbL-licensed, no API
/// key required) via flutter_map — a properly licensed, freely usable
/// map provider appropriate for a civic-tech project with no ad-hoc
/// commercial map budget. Marker clustering keeps large datasets
/// performant; pins never show more precise location than the
/// measurement's own recorded coordinates (already coarse-grained by
/// GPS accuracy), and no per-user identity is shown on the public map.
class SignalMapScreen extends ConsumerWidget {
  const SignalMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measurementsAsync = ref.watch(allMeasurementsProvider);
    final filters = ref.watch(mapFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Signal Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const MapFilterSheet(),
            ),
          ),
        ],
      ),
      body: measurementsAsync.when(
        data: (measurements) {
          final filtered = filters.apply(measurements);
          return Stack(
            children: [
              FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(
                    AppConstants.defaultMapLat,
                    AppConstants.defaultMapLng,
                  ),
                  initialZoom: AppConstants.defaultMapZoom,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'pk.darazindaconnect.app',
                    maxZoom: 19,
                  ),
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 45,
                      size: const Size(40, 40),
                      markers: [
                        for (final m in filtered) _markerFor(m),
                      ],
                      builder: (context, markers) => Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          markers.length.toString(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: _Legend(),
              ),
              if (filtered.isEmpty)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No measurements match the current filters yet.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Could not load map data.')),
      ),
    );
  }

  Marker _markerFor(Measurement m) {
    return Marker(
      point: LatLng(m.latitude, m.longitude),
      width: 22,
      height: 22,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.forSignalLevel(m.signalQuality.level),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      ('Good', AppColors.signalGood),
      ('Moderate', AppColors.signalModerate),
      ('Weak', AppColors.signalWeak),
      ('Very Weak / No Service', AppColors.signalVeryWeak),
    ];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (label, color) in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(label, style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
