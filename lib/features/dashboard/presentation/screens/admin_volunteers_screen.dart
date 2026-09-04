import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/activity_logger.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../volunteers/domain/entities/volunteer.dart';
import '../../../volunteers/presentation/providers/volunteers_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../app/theme/app_colors.dart';

class AdminVolunteersScreen extends ConsumerStatefulWidget {
  const AdminVolunteersScreen({super.key});

  @override
  ConsumerState<AdminVolunteersScreen> createState() =>
      _AdminVolunteersScreenState();
}

class _AdminVolunteersScreenState extends ConsumerState<AdminVolunteersScreen> {
  String _query = '';
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final applicationsAsync = ref.watch(adminVolunteersProvider);

    if (!authState.isAuthenticated || authState.user?.isAdmin != true) {
      return const Scaffold(
        body: Center(child: Text('Administrator access required')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Volunteer Applications')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by user or opportunity...',
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
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                      value: 'accepted',
                      child: Text('Accepted'),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text('Rejected'),
                    ),
                    DropdownMenuItem(value: 'all', child: Text('All')),
                  ],
                  onChanged: (value) => setState(() => _statusFilter = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: applicationsAsync.when(
              loading: () =>
                  const AppLoadingState(message: 'Loading applications...'),
              error: (error, _) => AppErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(adminVolunteersProvider),
              ),
              data: (items) {
                var filtered = items;
                if (_query.isNotEmpty) {
                  filtered = filtered
                      .where(
                        (v) =>
                            v.userId.toLowerCase().contains(_query) ||
                            v.opportunityId.toLowerCase().contains(_query),
                      )
                      .toList();
                }
                if (_statusFilter != null && _statusFilter != 'all') {
                  filtered = filtered
                      .where((v) => v.status == _statusFilter)
                      .toList();
                }
                if (filtered.isEmpty) {
                  return const AppEmptyState(
                    message: 'No volunteer applications found.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(adminVolunteersProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final volunteer = filtered[index];
                      return _VolunteerTile(volunteer: volunteer);
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

class _VolunteerTile extends ConsumerStatefulWidget {
  final Volunteer volunteer;

  const _VolunteerTile({required this.volunteer});

  @override
  ConsumerState<_VolunteerTile> createState() => _VolunteerTileState();
}

class _VolunteerTileState extends ConsumerState<_VolunteerTile> {
  bool _isSubmitting = false;
  String? _reviewNotes;

  Future<void> _setStatus(BuildContext context, String status) async {
    if (_isSubmitting) return;
    final notes = status == 'rejected' ? _reviewNotes : null;
    if (status == 'rejected' && (notes == null || notes.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a review note')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(updateVolunteerStatusProvider)
          .call(
            applicationId: widget.volunteer.id,
            status: status,
            reviewNotes: notes,
          );
      ref.invalidate(adminVolunteersProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Volunteer ${status == 'accepted' ? 'accepted' : 'rejected'} successfully',
          ),
        ),
      );
      unawaited(
        ActivityLogger.logAdmin(
          title: 'Volunteer application $status',
          type: 'volunteer',
          subtitle: widget.volunteer.id,
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.volunteer.userId;
    final opportunityId = widget.volunteer.opportunityId;
    final status = widget.volunteer.status;

    return Card(
      child: InkWell(
        onTap: () => _showDetailDialog(context, widget.volunteer),
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
                      'Volunteer: ${userId.isEmpty ? 'Unknown' : userId.substring(0, userId.length < 10 ? userId.length : 10)}...',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Opportunity: ${opportunityId.isEmpty ? 'N/A' : opportunityId.substring(0, opportunityId.length < 10 ? opportunityId.length : 10)}...',
                      style: AppTextStyles.listSubtitle,
                    ),
                  ],
                ),
              ),
              StatusChip(label: _statusLabel(status), compact: true),
              const SizedBox(width: 8),
              if (status == 'pending') ...[
                IconButton(
                  tooltip: 'Accept',
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                  ),
                  onPressed: _isSubmitting
                      ? null
                      : () => _showAcceptDialog(context),
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

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  void _showDetailDialog(BuildContext context, Volunteer volunteer) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Volunteer Application'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('User ID', volunteer.userId),
              _detailRow('Opportunity', volunteer.opportunityId),
              _detailRow('Motivation', volunteer.motivation),
              _detailRow('Availability', volunteer.availability),
              if (volunteer.skills.isNotEmpty)
                _detailRow('Skills', volunteer.skills.join(', ')),
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

  void _showAcceptDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Accept Volunteer'),
        content: Text(
          'Accept volunteer application for ${widget.volunteer.userId}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _setStatus(context, 'accepted');
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    _reviewNotes = null;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Volunteer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reject volunteer application for ${widget.volunteer.userId}?',
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Review notes',
                hintText: 'Enter reason for rejection',
              ),
              onChanged: (value) => _reviewNotes = value,
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
              if (_reviewNotes == null || _reviewNotes!.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please enter a review note')),
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
