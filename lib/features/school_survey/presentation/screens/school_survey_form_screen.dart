import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../network_test/data/repositories/measurement_repository.dart';
import '../../../network_test/presentation/providers/network_test_provider.dart';
import '../../data/school_survey_repository.dart';

class SchoolSurveyFormScreen extends ConsumerStatefulWidget {
  const SchoolSurveyFormScreen({super.key});

  @override
  ConsumerState<SchoolSurveyFormScreen> createState() =>
      _SchoolSurveyFormScreenState();
}

class _SchoolSurveyFormScreenState
    extends ConsumerState<SchoolSurveyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _studentsController = TextEditingController();
  final _teachersController = TextEditingController();
  bool? _onlineLearningAccessible;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _studentsController.dispose();
    _teachersController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final locationResult =
        await ref.read(locationServiceProvider).getCurrentLocation();
    if (locationResult is! LocationSuccess) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get GPS location.')),
      );
      return;
    }

    final lastMeasurement = await ref.read(lastMeasurementProvider.future);

    await ref.read(schoolSurveyRepositoryProvider).submit(
          schoolName: _nameController.text.trim(),
          latitude: locationResult.position.latitude,
          longitude: locationResult.position.longitude,
          students: int.tryParse(_studentsController.text),
          teachers: int.tryParse(_teachersController.text),
          operatorName: lastMeasurement?.operatorName,
          networkType: lastMeasurement?.networkType,
          signalDbm: lastMeasurement?.signalDbm,
          downloadMbps: lastMeasurement?.downloadMbps,
          uploadMbps: lastMeasurement?.uploadMbps,
          pingMs: lastMeasurement?.pingMs,
          onlineLearningAccessible: _onlineLearningAccessible,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('School survey saved. Thank you!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('School Connectivity Survey')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'School name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _studentsController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Number of students'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _teachersController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Number of teachers'),
                ),
                const SizedBox(height: 16),
                const Text('Is online learning accessible here?'),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('Yes'),
                        value: true,
                        groupValue: _onlineLearningAccessible,
                        onChanged: (v) =>
                            setState(() => _onlineLearningAccessible = v),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('No'),
                        value: false,
                        groupValue: _onlineLearningAccessible,
                        onChanged: (v) =>
                            setState(() => _onlineLearningAccessible = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Operator, network type and signal will be attached '
                    'automatically from your most recent network test.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
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
                      : const Text('Save Survey'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
