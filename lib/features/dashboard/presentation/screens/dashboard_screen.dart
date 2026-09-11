import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/connectivity_service.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/signal_badge.dart';
import '../../../network_test/presentation/providers/network_test_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastMeasurement = ref.watch(lastMeasurementProvider);
    final isOnline = ref.watch(isOnlineProvider).value ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Darazinda Connect'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(lastMeasurementProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ConnectivityStatusBanner(isOnline: isOnline),
              const SizedBox(height: 16),
              lastMeasurement.when(
                data: (m) => _StatusCard(measurement: m),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, st) => const _StatusCard(measurement: null),
              ),
              const SizedBox(height: 20),
              const Text('Quick Actions', style: AppTextStyles.title),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _ActionCard(
                    icon: Icons.speed,
                    label: 'Quick Test',
                    color: AppColors.primaryBlue,
                    onTap: () => context.push(AppRoutes.networkTest),
                  ),
                  _ActionCard(
                    icon: Icons.map_outlined,
                    label: 'Signal Map',
                    color: AppColors.accentCyan,
                    onTap: () => context.push(AppRoutes.signalMap),
                  ),
                  _ActionCard(
                    icon: Icons.report_problem_outlined,
                    label: 'Report Problem',
                    color: AppColors.signalWeak,
                    onTap: () => context.push(AppRoutes.reportProblem),
                  ),
                  _ActionCard(
                    icon: Icons.bar_chart,
                    label: 'Statistics',
                    color: AppColors.signalGood,
                    onTap: () => context.push(AppRoutes.statistics),
                  ),
                  _ActionCard(
                    icon: Icons.assignment_outlined,
                    label: 'My Reports',
                    color: AppColors.pendingSync,
                    onTap: () => context.push(AppRoutes.myReports),
                  ),
                  _ActionCard(
                    icon: Icons.compare_arrows,
                    label: 'Operators',
                    color: AppColors.primaryBlueDark,
                    onTap: () => context.push(AppRoutes.operatorComparison),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Community Surveys', style: AppTextStyles.title),
              const SizedBox(height: 12),
              _SurveyRow(
                icon: Icons.school_outlined,
                label: 'School Connectivity Survey',
                onTap: () => context.push(AppRoutes.schoolSurvey),
              ),
              const SizedBox(height: 8),
              _SurveyRow(
                icon: Icons.local_hospital_outlined,
                label: 'Health Facility Survey',
                onTap: () => context.push(AppRoutes.healthSurvey),
              ),
              const SizedBox(height: 8),
              _SurveyRow(
                icon: Icons.warning_amber_outlined,
                label: 'Probable Dead Zones',
                onTap: () => context.push(AppRoutes.deadZones),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectivityStatusBanner extends StatelessWidget {
  const _ConnectivityStatusBanner({required this.isOnline});
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    if (isOnline) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.pendingSync.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off, size: 18, color: AppColors.pendingSync),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'You are offline. Measurements and reports will be saved '
              'locally and synced automatically when you reconnect.',
              style: TextStyle(fontSize: 12.5, color: AppColors.pendingSync),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.measurement});
  final dynamic measurement;

  @override
  Widget build(BuildContext context) {
    final m = measurement;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.primaryBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current Status',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          if (m == null)
            const Text(
              'No measurements yet. Run a quick test to get started.',
              style: TextStyle(color: Colors.white, fontSize: 15),
            )
          else ...[
            Row(
              children: [
                Text(m.operatorName ?? 'Operator unknown',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                if (m.networkType != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(m.networkType,
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            SignalBadge(quality: m.signalQuality),
            const SizedBox(height: 10),
            Text(
              'Last measured: ${DateFormat.yMMMd().add_jm().format(m.measuredAt)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const Spacer(),
            Text(label, style: AppTextStyles.title.copyWith(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _SurveyRow extends StatelessWidget {
  const _SurveyRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryBlue),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppTextStyles.body)),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
