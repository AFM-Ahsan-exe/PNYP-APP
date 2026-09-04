import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/cloud_functions_client.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class AdminBulkActionsScreen extends ConsumerStatefulWidget {
  const AdminBulkActionsScreen({super.key});

  @override
  ConsumerState<AdminBulkActionsScreen> createState() =>
      _AdminBulkActionsScreenState();
}

class _AdminBulkActionsScreenState
    extends ConsumerState<AdminBulkActionsScreen> {
  final _selectedUserIds = <String>{};
  bool _isLoading = false;
  String? _actionResult;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    if (!authState.isAuthenticated || authState.user?.isAdmin != true) {
      return const Scaffold(
        body: Center(child: Text('Administrator access required')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk User Actions'),
        actions: [
          if (_selectedUserIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _isLoading ? null : _confirmBulkDeleteUsers,
              tooltip: 'Delete Selected',
            ),
        ],
      ),
      body: Column(
        children: [
          if (_actionResult != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _actionResult!,
                style: const TextStyle(color: AppColors.success),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const AppLoadingState();
                }
                final users = snapshot.data!.docs;
                if (users.isEmpty) {
                  return const AppEmptyState(message: 'No users found');
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final data = user.data() as Map<String, dynamic>;
                    final email = data['email'] as String? ?? 'No email';
                    final fullName = data['fullName'] as String? ?? 'Unknown';
                    final isSelected = _selectedUserIds.contains(user.id);

                    return Card(
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedUserIds.add(user.id);
                            } else {
                              _selectedUserIds.remove(user.id);
                            }
                          });
                        },
                        title: Text(
                          fullName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(email),
                        secondary: CircleAvatar(
                          backgroundColor: AppColors.navyDeep.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(fullName[0]),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBulkDeleteUsers() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Users'),
        content: Text(
          'Permanently delete ${_selectedUserIds.length} selected users? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _bulkDeleteUsers();
    }
  }

  Future<void> _bulkDeleteUsers() async {
    setState(() {
      _isLoading = true;
      _actionResult = null;
    });

    try {
      final client = CloudFunctionsClient(
        projectId: Firebase.app().options.projectId,
        region: 'us-central1',
      );
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('No authenticated user');
      final idToken = await user.getIdToken();

      await client.call('bulkDeleteUsers', {
        'userIds': _selectedUserIds.toList(),
      }, idToken);

      setState(() {
        _isLoading = false;
        _actionResult = '${_selectedUserIds.length} users deleted successfully';
        _selectedUserIds.clear();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _actionResult = 'Error: $e';
      });
    }
  }
}
