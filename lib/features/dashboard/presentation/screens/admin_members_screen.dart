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
            itemBuilder: (context, index) => _MemberTile(
              member: items[index],
              onStatusChanged: () => ref.invalidate(pendingMembersProvider),
            ),
          ),
        );
      },
    );
  }
}

class _MemberTile extends ConsumerWidget {
  final AdminMember member;
  final VoidCallback onStatusChanged;

  const _MemberTile({required this.member, required this.onStatusChanged});

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    String status,
  ) async {
    try {
      await ref
          .read(adminMemberRepositoryProvider)
          .updateStatus(member.uid, status);
      onStatusChanged();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        title: Text(member.name.isEmpty ? 'Unnamed member' : member.name),
        subtitle: Text(member.email),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Approve member',
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              onPressed: () => _setStatus(context, ref, 'approved'),
            ),
            IconButton(
              tooltip: 'Reject member',
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              onPressed: () => _setStatus(context, ref, 'rejected'),
            ),
          ],
        ),
      ),
    );
  }
}
