import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../sync/data/sync_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmDeleteData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all local data?'),
        content: const Text(
          'This permanently deletes all measurements, reports and '
          'surveys stored on this device. Data already synced to the '
          'community server is not affected by this action alone — '
          'contact support to request deletion of synced data too.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(appDatabaseProvider);
      await db.delete(db.measurements).go();
      await db.delete(db.reports).go();
      await db.delete(db.schoolSurveys).go();
      await db.delete(db.healthFacilitySurveys).go();
      await db.delete(db.syncQueueItems).go();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All local data deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Language'),
          RadioListTile<String>(
            title: const Text('English'),
            value: 'en',
            groupValue: locale.languageCode,
            onChanged: (v) => ref
                .read(localeProvider.notifier)
                .setLocale(const Locale('en')),
          ),
          RadioListTile<String>(
            title: const Text('اردو (Urdu)'),
            value: 'ur',
            groupValue: locale.languageCode,
            onChanged: (v) => ref
                .read(localeProvider.notifier)
                .setLocale(const Locale('ur')),
          ),
          const Divider(),
          const _SectionHeader('Privacy & Data'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            subtitle: const Text(AppConstants.privacyPolicyUrl),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.data_usage_outlined),
            title: const Text('What data do we collect?'),
            subtitle: const Text(
              'GPS location, network/operator info, and measurement '
              'results you generate. No contacts, SMS, or call history.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text('Delete Account / Data',
                style: TextStyle(color: AppColors.error)),
            onTap: () => _confirmDeleteData(context, ref),
          ),
          const Divider(),
          const _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Darazinda Connect'),
            subtitle: const Text(
              'Darazinda Connect measures and reports network conditions. '
              'It cannot and does not boost cellular signal.',
            ),
          ),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '—';
              return ListTile(
                leading: const Icon(Icons.numbers_outlined),
                title: const Text('App Version'),
                subtitle: Text(version),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.support_agent_outlined),
            title: const Text('Contact Support'),
            subtitle: const Text(AppConstants.supportEmail),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: AppTextStyles.caption),
    );
  }
}
