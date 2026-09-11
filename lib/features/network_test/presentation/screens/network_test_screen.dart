import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/metric_tile.dart';
import '../../../../core/widgets/signal_badge.dart';
import '../providers/network_test_provider.dart';

class NetworkTestScreen extends ConsumerWidget {
  const NetworkTestScreen({super.key});

  String _stageLabel(TestStage stage) {
    switch (stage) {
      case TestStage.locating:
        return 'Getting GPS location…';
      case TestStage.readingTelephony:
        return 'Reading network info…';
      case TestStage.testingPing:
        return 'Measuring latency…';
      case TestStage.testingDownload:
        return 'Measuring download speed…';
      case TestStage.testingUpload:
        return 'Measuring upload speed…';
      case TestStage.saving:
        return 'Saving result…';
      default:
        return 'Testing…';
    }
  }

  String _errorMessage(String? code) {
    switch (code) {
      case 'gps_disabled':
        return 'Location services are turned off. Please enable GPS to '
            'record where this measurement was taken.';
      case 'gps_permission_denied':
        return 'Location permission is required to tag measurements with '
            'GPS coordinates. Please allow it and try again.';
      case 'gps_permission_permanently_denied':
        return 'Location permission was permanently denied. Please enable '
            'it from Android Settings > Apps > Darazinda Connect > '
            'Permissions.';
      case 'gps_timeout':
        return 'Could not get a GPS fix in time. Try again outdoors or '
            'near a window.';
      default:
        return 'Something went wrong while testing. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(networkTestProvider);
    final notifier = ref.read(networkTestProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Network Test')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const _NoBoostDisclaimer(),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: state.result != null
                      ? _ResultView(state: state)
                      : _IdleOrRunningView(state: state, errorText: state.stage == TestStage.error
                          ? _errorMessage(state.errorCode)
                          : null, stageLabel: _stageLabel(state.stage)),
                ),
              ),
              if (state.isCancellable) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: notifier.cancelTest,
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel Test'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: state.isRunning
                      ? null
                      : () {
                          notifier.reset();
                          notifier.runTest();
                        },
                  icon: state.isRunning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.speed),
                  label: Text(state.isRunning ? 'Testing…' : 'Start Test'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoBoostDisclaimer extends StatelessWidget {
  const _NoBoostDisclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.accentCyan.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.primaryBlue),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'This app measures and reports network conditions. It cannot '
              'and does not boost cellular signal.',
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdleOrRunningView extends StatelessWidget {
  const _IdleOrRunningView({
    required this.state,
    required this.errorText,
    required this.stageLabel,
  });

  final NetworkTestState state;
  final String? errorText;
  final String stageLabel;

  @override
  Widget build(BuildContext context) {
    if (errorText != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(errorText!, textAlign: TextAlign.center, style: AppTextStyles.body),
          ],
        ),
      );
    }
    if (state.isRunning) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(stageLabel, style: AppTextStyles.body),
          ],
        ),
      );
    }
    if (state.stage == TestStage.cancelled) {
      return const Padding(
        padding: EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(Icons.cancel_outlined, size: 48, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text(
              'Test cancelled. No measurement was saved.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          ],
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.network_check, size: 56, color: AppColors.primaryBlue),
          SizedBox(height: 16),
          Text(
            'Tap "Start Test" to measure your signal, speed and location.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.state});

  final NetworkTestState state;

  @override
  Widget build(BuildContext context) {
    final m = state.result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Result', style: AppTextStyles.title),
            const Spacer(),
            SignalBadge(quality: m.signalQuality),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            MetricTile(
              label: 'Operator',
              value: m.operatorName,
              icon: Icons.sim_card,
            ),
            MetricTile(
              label: 'Network Type',
              value: m.networkType,
              icon: Icons.network_cell,
            ),
            MetricTile(
              label: 'Signal Strength',
              value: m.signalDbm != null ? '${m.signalDbm} dBm' : null,
              icon: Icons.signal_cellular_alt,
            ),
            MetricTile(
              label: 'GPS Accuracy',
              value: m.gpsAccuracyMeters != null
                  ? '±${m.gpsAccuracyMeters!.toStringAsFixed(0)} m'
                  : null,
              icon: Icons.gps_fixed,
            ),
            MetricTile(
              label: 'Download',
              value: m.downloadMbps != null
                  ? '${m.downloadMbps!.toStringAsFixed(1)} Mbps'
                  : null,
              icon: Icons.arrow_downward,
            ),
            MetricTile(
              label: 'Upload',
              value: m.uploadMbps != null
                  ? '${m.uploadMbps!.toStringAsFixed(1)} Mbps'
                  : null,
              icon: Icons.arrow_upward,
            ),
            MetricTile(
              label: 'Ping',
              value: m.pingMs != null ? '${m.pingMs} ms' : null,
              icon: Icons.timer,
            ),
            MetricTile(
              label: 'Sync Status',
              value: m.syncStatus.name == 'synced' ? 'Synced' : 'Pending Sync',
              icon: Icons.sync,
            ),
          ],
        ),
      ],
    );
  }
}
