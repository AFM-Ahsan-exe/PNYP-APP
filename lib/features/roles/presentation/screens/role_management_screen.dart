import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/cloud_functions_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../app/theme/app_text_styles.dart';

final usersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final client = CloudFunctionsClient(
    projectId: Firebase.app().options.projectId,
    region: 'us-central1',
  );
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];
  final idToken = await user.getIdToken();
  final result = await client.call('getPendingMembers', {
    'status': '',
  }, idToken);
  final members = result['members'] as List<dynamic>? ?? [];
  return members.map((m) => Map<String, dynamic>.from(m as Map)).toList();
});

class RoleManagementScreen extends ConsumerWidget {
  const RoleManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    if (!authState.isAuthenticated || authState.user?.isAdmin != true) {
      return const Scaffold(
        body: Center(child: Text('Administrator access required')),
      );
    }

    final users = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Role Management')),
      body: users.when(
        loading: () => const AppLoadingState(message: 'Loading users...'),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(usersProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(message: 'No users found');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(usersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _UserTile(user: items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _UserTile extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;

  const _UserTile({required this.user});

  @override
  ConsumerState<_UserTile> createState() => _UserTileState();
}

class _UserTileState extends ConsumerState<_UserTile> {
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    final uid =
        widget.user['uid'] as String? ?? widget.user['id'] as String? ?? '';
    final email = widget.user['email'] as String? ?? 'No email';
    final fullName = widget.user['fullName'] as String? ?? 'Unknown';
    final currentRole = widget.user['role'] as String? ?? 'member';

    return Card(
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
            DropdownButton<String>(
              value: _selectedRole ?? currentRole,
              items: const [
                DropdownMenuItem(value: 'member', child: Text('Member')),
                DropdownMenuItem(
                  value: 'district_coordinator',
                  child: Text('District Coordinator'),
                ),
                DropdownMenuItem(
                  value: 'regional_coordinator',
                  child: Text('Regional Coordinator'),
                ),
                DropdownMenuItem(
                  value: 'content_manager',
                  child: Text('Content Manager'),
                ),
                DropdownMenuItem(
                  value: 'opportunity_manager',
                  child: Text('Opportunity Manager'),
                ),
                DropdownMenuItem(
                  value: 'national_admin',
                  child: Text('National Admin'),
                ),
                DropdownMenuItem(value: 'president', child: Text('President')),
                DropdownMenuItem(
                  value: 'super_admin',
                  child: Text('Super Admin'),
                ),
              ],
              onChanged: (value) async {
                if (value == null || value == currentRole) return;
                setState(() => _selectedRole = value);
                try {
                  final client = CloudFunctionsClient(
                    projectId: Firebase.app().options.projectId,
                    region: 'us-central1',
                  );
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) throw StateError('No authenticated user');
                  final idToken = await user.getIdToken();
                  await client.call('updateUserRole', {
                    'uid': uid,
                    'role': value,
                  }, idToken);
                  if (!context.mounted) return;
                  {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Role updated to $value')),
                    );
                    ref.invalidate(usersProvider);
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
