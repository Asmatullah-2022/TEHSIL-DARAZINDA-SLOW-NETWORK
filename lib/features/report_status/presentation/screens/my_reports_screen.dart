import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../pdf_report/data/pdf_report_generator.dart';
import '../../../report_problem/data/report_repository.dart';
import '../../../report_problem/domain/entities/problem_category.dart';
import '../../../report_problem/domain/entities/problem_report.dart';

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(myReportsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: reportsAsync.when(
        data: (reports) => reports.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                      'You have not submitted any reports yet.',
                      textAlign: TextAlign.center),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: reports.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _ReportCard(report: reports[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Could not load reports.')),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});
  final ProblemReport report;

  Color _statusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return AppColors.pendingSync;
      case ReportStatus.underReview:
        return AppColors.signalModerate;
      case ReportStatus.inProgress:
        return AppColors.primaryBlue;
      case ReportStatus.resolved:
        return AppColors.signalGood;
      case ReportStatus.closed:
        return AppColors.textSecondary;
    }
  }

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
                child: Text(report.id,
                    style: AppTextStyles.title.copyWith(fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(report.status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.status.label,
                  style: TextStyle(
                    color: _statusColor(report.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(report.category.label, style: AppTextStyles.body),
          const SizedBox(height: 4),
          Text(
            DateFormat.yMMMd().add_jm().format(report.createdAt),
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Export PDF'),
              onPressed: () async {
                final bytes = await PdfReportGenerator().generate(report);
                await Printing.sharePdf(
                  bytes: bytes,
                  filename: '${report.id}.pdf',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
