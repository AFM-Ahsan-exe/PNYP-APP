import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/activity_logger.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../renewal/domain/entities/renewal_request.dart';
import '../../../renewal/presentation/providers/renewal_providers.dart';
import '../providers/dashboard_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../app/theme/app_colors.dart';

class AdminRenewalsScreen extends ConsumerStatefulWidget {
  const AdminRenewalsScreen({super.key});

  @override
  ConsumerState<AdminRenewalsScreen> createState() =>
      _AdminRenewalsScreenState();
}

class _AdminRenewalsScreenState extends ConsumerState<AdminRenewalsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final renewalsAsync = ref.watch(pendingRenewalsProvider);

    if (!authState.isAuthenticated || authState.user?.isAdmin != true) {
      return const Scaffold(
        body: Center(child: Text('Administrator access required')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Renewals')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by user ID or membership type...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) =>
                  setState(() => _query = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: renewalsAsync.when(
              loading: () =>
                  const AppLoadingState(message: 'Loading renewals...'),
              error: (error, _) => AppErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(pendingRenewalsProvider),
              ),
              data: (items) {
                var filtered = items;
                if (_query.isNotEmpty) {
                  filtered = filtered
                      .where(
                        (r) =>
                            r.uid.toLowerCase().contains(_query) ||
                            r.membershipType.toLowerCase().contains(_query),
                      )
                      .toList();
                }
                if (filtered.isEmpty) {
                  return const AppEmptyState(message: 'No pending renewals');
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(pendingRenewalsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final renewal = filtered[index];
                      return _RenewalTile(
                        renewal: renewal,
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

class _RenewalTile extends ConsumerStatefulWidget {
  final RenewalRequest renewal;
  final String? currentUserUid;

  const _RenewalTile({required this.renewal, this.currentUserUid});

  @override
  ConsumerState<_RenewalTile> createState() => _RenewalTileState();
}

class _RenewalTileState extends ConsumerState<_RenewalTile> {
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
      final uid = widget.renewal.uid;
      await ref
          .read(adminMemberRepositoryProvider)
          .updateStatus(
            uid,
            status,
            reason: reason,
            membershipType: status == 'approved'
                ? _selectedMembershipType ?? widget.renewal.membershipType
                : null,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Renewal ${status == "approved" ? "approved" : "rejected"} successfully',
          ),
        ),
      );
      unawaited(
        ActivityLogger.logAdmin(
          title: 'Renewal $status',
          type: 'membership',
          subtitle: widget.renewal.uid,
          metadata: {
            'uid': uid,
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
    final renewal = widget.renewal;
    final isSelf = renewal.uid == widget.currentUserUid;

    return Card(
      child: InkWell(
        onTap: () => _showDetailDialog(context, renewal),
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
                      renewal.uid,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Type: ${renewal.membershipType}',
                      style: AppTextStyles.listSubtitle,
                    ),
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

  void _showDetailDialog(BuildContext context, RenewalRequest renewal) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Renewal: ${renewal.uid}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('UID', renewal.uid),
              _detailRow('Type', renewal.membershipType),
              _detailRow('Payment Proof', renewal.paymentProofUrl),
              _detailRow('Submitted', renewal.submittedAt.toString()),
              _detailRow('Status', renewal.status),
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
    _selectedMembershipType ??= widget.renewal.membershipType;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Renewal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Approve renewal for ${widget.renewal.uid}?'),
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
        title: const Text('Reject Renewal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject renewal for ${widget.renewal.uid}?'),
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
