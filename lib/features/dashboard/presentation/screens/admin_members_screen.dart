import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/admin_member.dart';
import '../providers/dashboard_providers.dart';

class AdminMembersScreen extends ConsumerWidget {
  const AdminMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(pendingMembersProvider);
    return members.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: TextButton.icon(
          onPressed: () => ref.invalidate(pendingMembersProvider),
          icon: const Icon(Icons.refresh),
          label: Text('Could not load members: $error'),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No pending members.'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(pendingMembersProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _MemberTile(member: items[index]),
          ),
        );
      },
    );
  }
}

class _MemberTile extends ConsumerStatefulWidget {
  final AdminMember member;

  const _MemberTile({required this.member});

  @override
  ConsumerState<_MemberTile> createState() => _MemberTileState();
}

class _MemberTileState extends ConsumerState<_MemberTile> {
  bool _isExpanded = false;
  String? _rejectionReason;
  String? _selectedMembershipType;

  Future<void> _setStatus(BuildContext context, String status) async {
    try {
      final reason = status == 'rejected' ? _rejectionReason : null;
      if (status == 'rejected' && (reason == null || reason.trim().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a rejection reason')),
        );
        return;
      }
      await ref
          .read(adminMemberRepositoryProvider)
          .updateStatus(widget.member.uid, status, reason: reason);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Member ${status == "approved" ? "approved" : "rejected"} successfully',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionPanelList(
        expansionCallback: (panelIndex, isExpanded) {
          setState(() => _isExpanded = !isExpanded);
        },
        children: [
          ExpansionPanel(
            isExpanded: _isExpanded,
            headerBuilder: (context, isExpanded) {
              return ListTile(
                title: Text(
                  widget.member.name.isEmpty
                      ? 'Unnamed member'
                      : widget.member.name,
                ),
                subtitle: Text(widget.member.email),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Approve member',
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      onPressed: () => _showApproveDialog(context),
                    ),
                    IconButton(
                      tooltip: 'Reject member',
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: Colors.red,
                      ),
                      onPressed: () => _showRejectDialog(context),
                    ),
                  ],
                ),
              );
            },
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showApproveDialog(context),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRejectDialog(context),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
            Text('Approve ${widget.member.name}?'),
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
        title: const Text('Reject Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reject ${widget.member.name}?'),
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
