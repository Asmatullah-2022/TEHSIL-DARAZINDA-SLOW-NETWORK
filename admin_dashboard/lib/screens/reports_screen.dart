import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/admin_models.dart';
import '../services/admin_repository.dart';

const List<String> _statuses = [
  'pending',
  'underReview',
  'inProgress',
  'resolved',
  'closed',
];

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.repo});
  final AdminRepository repo;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _statusFilter == null,
                onSelected: (_) => setState(() => _statusFilter = null),
              ),
              for (final s in _statuses)
                ChoiceChip(
                  label: Text(s),
                  selected: _statusFilter == s,
                  onSelected: (_) => setState(() => _statusFilter = s),
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AdminReport>>(
            stream: widget.repo.watchReports(statusFilter: _statusFilter),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Failed to load reports: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final reports = snapshot.data ?? [];
              if (reports.isEmpty) {
                return const Center(child: Text('No reports found.'));
              }
              return ListView.builder(
                itemCount: reports.length,
                itemBuilder: (context, i) {
                  final r = reports[i];
                  return ListTile(
                    title: Text('${r.id} — ${r.category}'),
                    subtitle: Text(
                      '${r.operatorName ?? 'Unknown operator'} · '
                      '${r.networkType ?? 'Unknown network'} · '
                      '${r.createdAt != null ? DateFormat.yMMMd().add_jm().format(r.createdAt!) : ''}',
                    ),
                    trailing: DropdownButton<String>(
                      value: r.status,
                      items: _statuses
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (newStatus) {
                        if (newStatus != null) {
                          widget.repo.updateReportStatus(r.id, newStatus);
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
