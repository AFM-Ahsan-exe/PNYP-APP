import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/validators/registration_validators.dart';
import '../../domain/entities/report_result.dart';
import '../providers/reports_providers.dart';
import '../../../../app/theme/app_text_styles.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String? _selectedReportType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  ReportResult? _reportResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.push('/reports/history'),
            tooltip: 'Report History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedReportType,
              decoration: const InputDecoration(
                labelText: 'Report Type',
                prefixIcon: Icon(Icons.analytics_rounded),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'membership',
                  child: Text('Membership Report'),
                ),
                DropdownMenuItem(value: 'events', child: Text('Events Report')),
                DropdownMenuItem(
                  value: 'volunteers',
                  child: Text('Volunteers Report'),
                ),
                DropdownMenuItem(
                  value: 'payments',
                  child: Text('Payments Report'),
                ),
                DropdownMenuItem(
                  value: 'engagement',
                  child: Text('Engagement Report'),
                ),
              ],
              onChanged: (value) => setState(() => _selectedReportType = value),
              validator: (value) => RegistrationValidators.required(value, 'Report type'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Start Date',
                prefixIcon: Icon(Icons.calendar_today_rounded),
              ),
              controller: TextEditingController(
                text: _startDate != null
                    ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                    : '',
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _startDate = picked);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'End Date',
                prefixIcon: Icon(Icons.calendar_today_rounded),
              ),
              controller: TextEditingController(
                text: _endDate != null
                    ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                    : '',
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _endDate = picked);
                }
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _generateReport,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navyDarkest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Generate Report'),
            ),
            if (_reportResult != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _exportCsv,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Export CSV'),
              ),
            ],
            const SizedBox(height: 24),
            if (_reportResult != null) ...[
              Text('Report Results', style: AppTextStyles.title),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...(_reportResult!.content.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key, style: AppTextStyles.body),
                              Text(
                                '${entry.value}',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generateReport() async {
    if (_selectedReportType == null || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select all fields')));
      return;
    }

    setState(() {
      _isLoading = true;
      _reportResult = null;
    });

    try {
      final result = await ref
          .read(generateReportProvider)
          .call(
            reportType: _selectedReportType!,
            startDate: _startDate!,
            endDate: _endDate!,
          );

      setState(() {
        _isLoading = false;
        _reportResult = result;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Cloud function')
                  ? 'Backend service unavailable. Contact support.'
                  : 'Something went wrong. Please try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _exportCsv() async {
    if (_reportResult == null) return;
    final rows = <String>[];
    rows.add('Metric,Value');
    for (final entry in _reportResult!.content.entries) {
      rows.add('${entry.key},${entry.value}');
    }
    final csv = rows.join('\n');
    if (mounted) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('CSV Export'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CSV generated successfully.'),
              const SizedBox(height: 12),
              SelectableText(
                csv,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}
