import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../network_test/presentation/providers/network_test_provider.dart';
import '../../data/report_repository.dart';
import '../../domain/entities/problem_category.dart';

class ReportProblemScreen extends ConsumerStatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  ConsumerState<ReportProblemScreen> createState() =>
      _ReportProblemScreenState();
}

class _ReportProblemScreenState extends ConsumerState<ReportProblemScreen> {
  ProblemCategory? _category;
  final _descriptionController = TextEditingController();
  XFile? _photo;
  bool _isSubmitting = false;
  String? _submittedReportId;
  String? _errorText;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (file != null) setState(() => _photo = file);
  }

  Future<void> _submit() async {
    if (_category == null) {
      setState(() => _errorText = 'Please select a problem category.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final locationResult = await ref.read(locationServiceProvider).getCurrentLocation();
    if (locationResult is! LocationSuccess) {
      setState(() {
        _isSubmitting = false;
        _errorText = 'Could not get your GPS location. Please enable '
            'location services and try again.';
      });
      return;
    }

    final lastMeasurement = await ref.read(lastMeasurementProvider.future);

    final report = await ref.read(reportRepositoryProvider).submitReport(
          category: _category!,
          latitude: locationResult.position.latitude,
          longitude: locationResult.position.longitude,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          photoLocalPath: _photo?.path,
          operatorName: lastMeasurement?.operatorName,
          networkType: lastMeasurement?.networkType,
          linkedMeasurementId: lastMeasurement?.id,
        );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _submittedReportId = report.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_submittedReportId != null) {
      return _SubmittedView(reportId: _submittedReportId!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Report a Problem')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'This report is saved as community evidence in '
                  'Darazinda Connect. It is not automatically submitted '
                  'to any telecom operator or government authority.',
                  style: TextStyle(fontSize: 12.5),
                ),
              ),
              const SizedBox(height: 16),
              Text('Problem category', style: AppTextStyles.title),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in ProblemCategory.values)
                    ChoiceChip(
                      label: Text(c.label),
                      selected: _category == c,
                      onSelected: (selected) =>
                          setState(() => _category = selected ? c : null),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Description (optional)', style: AppTextStyles.title),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe what you are experiencing…',
                ),
              ),
              const SizedBox(height: 20),
              Text('Photo (optional)', style: AppTextStyles.title),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(_photo == null ? 'Add Photo' : 'Photo added'),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(_errorText!, style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmittedView extends StatelessWidget {
  const _SubmittedView({required this.reportId});
  final String reportId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Submitted')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle,
                  size: 64, color: AppColors.signalGood),
              const SizedBox(height: 16),
              const Text('Your report has been saved',
                  style: AppTextStyles.title),
              const SizedBox(height: 8),
              Text('Report ID: $reportId', style: AppTextStyles.body),
              const SizedBox(height: 8),
              Text(
                'You can track its status under "My Reports". It will '
                'sync automatically once you are online.',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
