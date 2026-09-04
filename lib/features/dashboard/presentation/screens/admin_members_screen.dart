import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/activity_logger.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/admin_member.dart';
import '../providers/dashboard_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../app/theme/app_colors.dart';

class AdminMembersScreen extends ConsumerStatefulWidget {
  const AdminMembersScreen({super.key});

  @override
  ConsumerState<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends ConsumerState<AdminMembersScreen> {
  String _query = '';
  // Defaults to 'pending' to match the screen's original initial fetch.
  String _statusFilter = 'pending';

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    // Watching with _statusFilter means changing the dropdown now
    // genuinely re-fetches from the backend for that status, instead of
    // re-filtering an always-pending-only list.
    final membersAsync = ref.watch(pendingMembersProvider(_statusFilter));

    if (!authState.isAuthenticated || authState.user?.isAdmin != true) {
      return const Scaffold(
        body: Center(child: Text('Administrator access required')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Membership Applications')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by name, email or ID...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onChanged: (value) =>
                        setState(() => _query = value.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _statusFilter,
                  hint: const Text('Status'),
                  items: const [
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('Pending'),
                    ),
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text('Approved'),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text('Rejected'),
                    ),
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('All'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _statusFilter = value);
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: membersAsync.when(
              loading: () =>
                  const AppLoadingState(message: 'Loading members...'),
              error: (error, _) => AppErrorState(
                message: error.toString(),
                onRetry: () =>
                    ref.invalidate(pendingMembersProvider(_statusFilter)),
              ),
              data: (items) {
                var filtered = items;
                if (_query.isNotEmpty) {
                  filtered = filtered
                      .where(
                        (m) =>
                            m.name.toLowerCase().contains(_query) ||
                            m.email.toLowerCase().contains(_query) ||
                            m.uid.toLowerCase().contains(_query),
                      )
                      .toList();
                }

                // No more client-side status re-filtering here - the
                // fetch itself is now for the selected status (or every
                // status, for 'all'), so `items` already reflects
                // the right set.
                if (filtered.isEmpty) {
                  return const AppEmptyState(message: 'No members found.');
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(pendingMembersProvider(_statusFilter)),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final member = filtered[index];
                      return _MemberTile(
                        member: member,
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

class _MemberTile extends ConsumerStatefulWidget {
  final AdminMember member;
  final String? currentUserUid;

  const _MemberTile({
    required this.member,
    this.currentUserUid,
  });

  @override
  ConsumerState<_MemberTile> createState() => _MemberTileState();
}

class _MemberTileState extends ConsumerState<_MemberTile> {
  bool _isSubmitting = false;
  String? _rejectionReason;
  String? _selectedMembershipType;

  Future<void> _setStatus(BuildContext context, String status) async {
    if (_isSubmitting) return;

    final reason = status == 'rejected' ? _rejectionReason : null;

    if (status == 'rejected' &&
        (reason == null || reason.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a rejection reason'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(adminMemberRepositoryProvider).updateStatus(
            widget.member.uid,
            status,
            reason: reason,
            membershipType:
                status == 'approved' ? _selectedMembershipType : null,
          );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Member ${status == "approved" ? "approved" : "rejected"} successfully',
          ),
        ),
      );

      unawaited(
        ActivityLogger.logAdmin(
          title: 'Membership $status',
          type: 'membership',
          subtitle: widget.member.name.isEmpty
              ? widget.member.uid
              : widget.member.name,
          metadata: {
            'uid': widget.member.uid,
            'status': status,
            if (reason != null) ...{'reason': reason},
            if (_selectedMembershipType != null)
              ...{'membershipType': _selectedMembershipType},
          },
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().contains('Cloud function')
                ? 'Backend service unavailable. Contact support.'
                : 'Something went wrong. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _deleteUser(BuildContext context) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(adminMemberRepositoryProvider)
          .deleteUser(widget.member.uid);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User deleted successfully'),
        ),
      );

      unawaited(
        ActivityLogger.logAdmin(
          title: 'User deleted',
          type: 'membership',
          subtitle: widget.member.name.isEmpty
              ? widget.member.uid
              : widget.member.name,
          metadata: {
            'uid': widget.member.uid,
          },
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().contains('Cloud function')
                ? 'Backend service unavailable. Contact support.'
                : 'Something went wrong. Please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Permanently delete '
          '${widget.member.name.isEmpty ? 'this member' : widget.member.name}? '
          'This deletes their sign-in account and profile and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deleteUser(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSelf = widget.member.uid == widget.currentUserUid;
    final status = widget.member.status.name;

    return Card(
      child: InkWell(
        onTap: () => _showDetailDialog(context, widget.member),
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
                      widget.member.name.isEmpty
                          ? 'Unnamed member'
                          : widget.member.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.member.email,
                      style: AppTextStyles.listSubtitle,
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: _statusLabel(status),
                compact: true,
              ),
              const SizedBox(width: 8),

              if (!isSelf && status == 'pending') ...[
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

              if (!isSelf &&
                  (ref.watch(authControllerProvider).user?.hasAtLeastRole(
                        'super_admin',
                      ) ??
                      false))
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteDialog(context);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.error,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete user',
                            style: TextStyle(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      case 'suspended':
        return 'Suspended';
      case 'expired':
        return 'Expired';
      default:
        return status;
    }
  }

  void _showApproveDialog(BuildContext context) {
    _selectedMembershipType ??= 'youth_mpa';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Approve '
              '${widget.member.name.isEmpty ? 'member' : widget.member.name}?',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedMembershipType,
              decoration: const InputDecoration(
                labelText: 'Membership Type',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'youth_mpa',
                  child: Text('Youth MPA'),
                ),
                DropdownMenuItem(
                  value: 'youth_mna',
                  child: Text('Youth MNA'),
                ),
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
        title: const Text('Reject Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reject '
              '${widget.member.name.isEmpty ? 'member' : widget.member.name}?',
            ),
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
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(
    BuildContext context,
    AdminMember member,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          member.name.isEmpty ? 'Member Details' : member.name,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Email', member.email),
              _detailRow('UID', member.uid),
              _detailRow('Status', member.status.name),
              _detailRow('Role', member.role),
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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

