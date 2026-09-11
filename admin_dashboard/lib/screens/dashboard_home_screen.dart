import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/admin_models.dart';
import '../services/admin_repository.dart';
import 'reports_screen.dart';

/// Root admin shell: left nav + map/reports/stats panes. Deliberately
/// simple (no heavy state management dependency) since this is a small
/// internal tool, not a consumer app — reduces the dependency surface
/// admins need to trust.
class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

enum _AdminTab { overview, map, reports }

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  _AdminTab _tab = _AdminTab.overview;
  final _repo = AdminRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _tab.index,
            onDestinationSelected: (i) =>
                setState(() => _tab = _AdminTab.values[i]),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined), label: Text('Overview')),
              NavigationRailDestination(
                  icon: Icon(Icons.map_outlined), label: Text('Map')),
              NavigationRailDestination(
                  icon: Icon(Icons.report_outlined), label: Text('Reports')),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_tab) {
      case _AdminTab.overview:
        return _OverviewPane(repo: _repo);
      case _AdminTab.map:
        return _MapPane(repo: _repo);
      case _AdminTab.reports:
        return ReportsScreen(repo: _repo);
    }
  }
}

class _OverviewPane extends StatelessWidget {
  const _OverviewPane({required this.repo});
  final AdminRepository repo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _countCard('Users', repo.watchCollectionCount('users')),
          _countCard('Measurements', repo.watchCollectionCount('measurements')),
          _countCard('Reports', repo.watchCollectionCount('reports')),
          _countCard('Schools Surveyed', repo.watchCollectionCount('schools')),
          _countCard('Health Facilities', repo.watchCollectionCount('health_facilities')),
        ],
      ),
    );
  }

  Widget _countCard(String label, Stream<int> stream) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        Widget valueWidget;
        if (snapshot.hasError) {
          valueWidget = const Tooltip(
            message: 'Failed to load — check Firestore rules/connection',
            child: Icon(Icons.error_outline, color: Colors.red, size: 24),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          valueWidget = const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        } else {
          valueWidget = Text('${snapshot.data ?? 0}',
              style:
                  const TextStyle(fontSize: 28, fontWeight: FontWeight.bold));
        }
        return Container(
          width: 180,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              valueWidget,
            ],
          ),
        );
      },
    );
  }
}

class _MapPane extends StatelessWidget {
  const _MapPane({required this.repo});
  final AdminRepository repo;

  Color _colorFor(int? dbm) {
    if (dbm == null) return Colors.grey;
    if (dbm >= -80) return Colors.green;
    if (dbm >= -95) return Colors.amber;
    if (dbm >= -110) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminMeasurement>>(
      stream: repo.watchMeasurements(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load measurements: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final measurements = snapshot.data ?? [];
        if (measurements.isEmpty) {
          return const Center(
            child: Text('No community measurements yet.'),
          );
        }
        return FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(31.9350, 70.5940),
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'pk.darazindaconnect.admin',
            ),
            MarkerLayer(
              markers: [
                for (final m in measurements)
                  Marker(
                    point: LatLng(m.lat, m.lng),
                    width: 14,
                    height: 14,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _colorFor(m.signalDbm),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
