import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/activity_logger.dart';
import '../../../../core/network/cloud_functions_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../app/theme/app_colors.dart';

final adminApplicationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];
      final idToken = await user.getIdToken();
      final client = CloudFunctionsClient(
        projectId: Firebase.app().options.projectId,
        region: 'us-central1',
      );
      final result = await client.call('getPendingMembers', {
        'status': 'pending',
      }, idToken);
      final members = result['members'] as List<dynamic>? ?? [];
      return members.map((m) => Map<String, dynamic>.from(m as Map)).toList();
    });

class AdminApplicationsScreen extends ConsumerStatefulWidget {
  const AdminApplicationsScreen({super.key});

  @override
  ConsumerState<AdminApplicationsScreen> createState() =>
      _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState
    extends ConsumerState<AdminApplicationsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final applicationsAsync = ref.watch(adminApplicationsProvider);

    if (!authState.isAuthenticated || authState.user?.isAdmin != true) {
      return const Scaffold(
        body: Center(child: Text('Administrator access required')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Applications')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name, email or ID...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) =>
                  setState(() => _query = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: applicationsAsync.when(
              loading: () =>
                  const AppLoadingState(message: 'Loading applications...'),
              error: (error, _) => AppErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(adminApplicationsProvider),
              ),
              data: (items) {
                var filtered = items;
                if (_query.isNotEmpty) {
                  filtered = filtered.where((item) {
                    final name = (item['fullName'] as String? ?? '')
                        .toLowerCase();
                    final email = (item['email'] as String? ?? '')
                        .toLowerCase();
                    final id = (item['id'] as String? ?? '').toLowerCase();
                    return name.contains(_query) ||
                        email.contains(_query) ||
                        id.contains(_query);
                  }).toList();
                }
                if (filtered.isEmpty) {
                  return const AppEmptyState(
                    message: 'No pending applications',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(adminApplicationsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final application = filtered[index];
                      return _ApplicationTile(
                        application: application,
                        currentUserUid: authState.user?.uid,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationTile extends ConsumerStatefulWidget {
  final Map<String, dynamic> application;
  final String? currentUserUid;

  const _ApplicationTile({required this.application, this.currentUserUid});

  @override
  ConsumerState<_ApplicationTile> createState() => _ApplicationTileState();
}

class _ApplicationTileState extends ConsumerState<_ApplicationTile> {
  bool _isSubmitting = false;
  String? _rejectionReason;
  String? _selectedMembershipType;

  Future<void> _setStatus(BuildContext context, String status) async {
    if (_isSubmitting) return;
    final reason = status == 'rejected' ? _rejectionReason : null;
    if (status == 'rejected' && (reason == null || reason.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a rejection reason')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final docId = widget.application['id'] as String;
      await ref
          .read(adminMemberRepositoryProvider)
          .updateStatus(
            docId,
            status,
            reason: reason,
            membershipType: status == 'approved'
                ? _selectedMembershipType
                : null,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Application ${status == "approved" ? "approved" : "rejected"} successfully',
          ),
        ),
      );
      unawaited(
        ActivityLogger.logAdmin(
          title: 'Membership $status',
          type: 'membership',
          subtitle: widget.application['fullName'] ?? docId,
          metadata: {
            'uid': docId,
            'status': status,
            if (reason != null) ...{'reason': reason},
            if (_selectedMembershipType != null) ...{
              'membershipType': _selectedMembershipType,
            },
          },
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.application['email'] as String? ?? 'No email';
    final fullName = widget.application['fullName'] as String? ?? 'Unnamed';
    final isSelf = widget.application['id'] == widget.currentUserUid;

    return Card(
      child: InkWell(
        onTap: () => _showDetailDialog(context, widget.application),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(email, style: AppTextStyles.listSubtitle),
                  ],
                ),
              ),
              StatusChip(label: 'Pending', compact: true),
              const SizedBox(width: 8),
              if (!isSelf) ...[
                IconButton(
                  tooltip: 'Approve',
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                  ),
                  onPressed: _isSubmitting
                      ? null
                      : () => _showApproveDialog(context),
                ),
                IconButton(
                  tooltip: 'Reject',
                  icon: const Icon(
                    Icons.cancel_outlined,
                    color: AppColors.error,
                  ),
                  onPressed: _isSubmitting
                      ? null
                      : () => _showRejectDialog(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(
    BuildContext context,
    Map<String, dynamic> application,
  ) {
    final fullName = application['fullName'] as String? ?? 'Unnamed';
    final email = application['email'] as String? ?? 'No email';
    final phone = application['phone'] as String? ?? 'N/A';
    final createdAt = application['createdAt'] is Timestamp
        ? (application['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(fullName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Email', email),
              _detailRow('Phone', phone),
              _detailRow(
                'Applied',
                '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}',
              ),
              _detailRow(
                'Status',
                application['status'] as String? ?? 'pending',
              ),
            ],
          ),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showApproveDialog(BuildContext context) {
    _selectedMembershipType ??= 'youth_mpa';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Approve ${widget.application['fullName'] ?? 'application'}?'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedMembershipType,
              decoration: const InputDecoration(labelText: 'Membership Type'),
              items: const [
                DropdownMenuItem(value: 'youth_mpa', child: Text('Youth MPA')),
                DropdownMenuItem(value: 'youth_mna', child: Text('Youth MNA')),
                DropdownMenuItem(
                  value: 'youth_senator',
                  child: Text('Youth Senator'),
                ),
                DropdownMenuItem(
                  value: 'youth_judge',
                  child: Text('Youth Judge'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _selectedMembershipType = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _setStatus(context, 'approved');
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    _rejectionReason = null;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject ${widget.application['fullName'] ?? 'application'}?'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Rejection reason',
                hintText: 'Enter reason for rejection',
              ),
              onChanged: (value) => _rejectionReason = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (_rejectionReason == null ||
                  _rejectionReason!.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a rejection reason'),
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext);
              await _setStatus(context, 'rejected');
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
