import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/cloud_functions_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../app/theme/app_text_styles.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  String? _actionType;
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>>? _logs;
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // getAuditLogs requires national_admin+ server-side - gating the
    // screen on the looser isAdmin (true for district_coordinator and up)
    // let lower coordinator roles open this screen only to be rejected by
    // the backend a moment later ("Could not load data"), which is the
    // exact confusing dead end this was producing. Match the real
    // requirement here instead.
    if (!authState.isAuthenticated ||
        !(authState.user?.hasAtLeastRole('national_admin') ?? false)) {
      return const Scaffold(
        body: Center(child: Text('Administrator access required')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Audit Logs')),
      body: Column(
        children: [
          // The filter state (_actionType/_startDate/_endDate) was
          // already wired through to getAuditLogs, but no UI ever let
          // the admin actually set it - the filters section of this
          // screen was effectively dead, unreachable code.
          _buildFilterBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  static const _actionTypes = [
    'CREATE',
    'UPDATE',
    'DELETE',
    'APPROVE',
    'REJECT',
    'READ',
  ];

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: _actionType,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Action type',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All actions'),
                    ),
                    ..._actionTypes.map(
                      (type) =>
                          DropdownMenuItem<String?>(value: type, child: Text(type)),
                    ),
                  ],
                  onChanged: (value) => setState(() => _actionType = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(
                    _startDate == null
                        ? 'Start date'
                        : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDate: _startDate ?? DateTime.now(),
                    );
                    if (picked != null) setState(() => _startDate = picked);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(
                    _endDate == null
                        ? 'End date'
                        : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDate: _endDate ?? DateTime.now(),
                    );
                    if (picked != null) setState(() => _endDate = picked);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _loadLogs,
                  icon: const Icon(Icons.filter_alt_rounded, size: 18),
                  label: const Text('Apply filters'),
                ),
              ),
              if (_actionType != null || _startDate != null || _endDate != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _actionType = null;
                            _startDate = null;
                            _endDate = null;
                          });
                          _loadLogs();
                        },
                  child: const Text('Clear'),
                ),
              ],
            ],
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // Previously this screen had no loading indicator at all while
    // _loadLogs() was in flight - tapping "Load Logs" (or any filter
    // change) appeared to do nothing until the request resolved, which
    // reads as a broken/unresponsive button on a slow connection. It
    // also never showed a real error state - a failed request silently
    // fell back to the "apply filters" prompt with only a SnackBar,
    // which is easy to miss and gives no retry affordance.
    if (_isLoading) {
      return const AppLoadingState(message: 'Loading audit logs...');
    }
    if (_error != null) {
      return AppErrorState(message: _error!, onRetry: _loadLogs);
    }
    if (_logs == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history_rounded,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 24),
            Text(
              'Apply filters to load audit logs',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadLogs,
              icon: const Icon(Icons.filter_alt_rounded),
              label: const Text('Load Logs'),
            ),
          ],
        ),
      );
    }
    if (_logs!.isEmpty) {
      return AppEmptyState(
        message: 'No audit logs found',
        actionLabel: 'Reload',
        onAction: _loadLogs,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLogs,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _logs!.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _LogTile(log: _logs![index]),
      ),
    );
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final client = CloudFunctionsClient(
        projectId: Firebase.app().options.projectId,
        region: 'us-central1',
      );
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _error = 'No authenticated user';
        });
        return;
      }
      final idToken = await user.getIdToken();

      final filters = <String, dynamic>{};
      if (_actionType != null) filters['actionType'] = _actionType;
      // A raw cloud_firestore `Timestamp` has no toJson() and cannot be
      // JSON-encoded (jsonEncode would throw before the request is ever
      // sent). Cloud Functions can't receive Firestore Timestamp objects
      // over the callable HTTP transport anyway - send ISO 8601 strings,
      // which getAuditLogs now parses back into Timestamps server-side.
      if (_startDate != null) {
        filters['startDate'] = _startDate!.toIso8601String();
      }
      if (_endDate != null) {
        filters['endDate'] = _endDate!.toIso8601String();
      }

      final result = await client.call('getAuditLogs', filters, idToken);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _logs = List<Map<String, dynamic>>.from(result['logs'] as List);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }
}

class _LogTile extends StatelessWidget {
  final Map<String, dynamic> log;

  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final actionType = log['actionType'] as String? ?? 'UNKNOWN';
    final targetCollection = log['targetCollection'] as String? ?? '';
    final timestamp = log['timestamp'] is Timestamp
        ? (log['timestamp'] as Timestamp).toDate()
        : DateTime.now();
    final userRole = log['userRole'] as String? ?? 'unknown';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _actionColor(actionType).withValues(alpha: 0.1),
          child: Icon(
            _actionIcon(actionType),
            color: _actionColor(actionType),
            size: 20,
          ),
        ),
        title: Text(
          '$actionType on $targetCollection',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          'By $userRole • ${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }

  IconData _actionIcon(String actionType) {
    switch (actionType) {
      case 'CREATE':
        return Icons.add_circle_outline_rounded;
      case 'UPDATE':
        return Icons.edit_outlined;
      case 'DELETE':
        return Icons.delete_outline_rounded;
      case 'APPROVE':
        return Icons.check_circle_outline_rounded;
      case 'REJECT':
        return Icons.cancel_outlined;
      case 'READ':
        return Icons.visibility_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _actionColor(String actionType) {
    switch (actionType) {
      case 'CREATE':
        return AppColors.success;
      case 'UPDATE':
        return AppColors.accentBlue;
      case 'DELETE':
        return AppColors.error;
      case 'APPROVE':
        return AppColors.success;
      case 'REJECT':
        return AppColors.error;
      case 'READ':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }
}
