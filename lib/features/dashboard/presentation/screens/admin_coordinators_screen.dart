import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/cloud_functions_client.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final adminCoordinatorsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];
      final idToken = await user.getIdToken();
      final client = CloudFunctionsClient(
        projectId: Firebase.app().options.projectId,
        region: 'us-central1',
      );
      // getPendingMembers only filters by status when the `status` key is
      // present and truthy - passing the literal string 'all' made it do
      // `.where('status', '==', 'all')`, which matches zero documents
      // (no user ever has status: 'all') and left the Coordinators screen
      // permanently empty regardless of how many actually exist. Omitting
      // the key entirely is what "no filter, return everyone" means here.
      final result = await client.call('getPendingMembers', {}, idToken);
      final members = result['members'] as List<dynamic>? ?? [];
      return members
          .where((m) {
            final data = m as Map<String, dynamic>;
            final role = data['role'] as String? ?? '';
            return role == 'admin' ||
                role == 'coordinator' ||
                role == 'district_coordinator' ||
                role == 'regional_coordinator' ||
                role == 'content_manager' ||
                role == 'opportunity_manager' ||
                role == 'national_admin' ||
                role == 'president' ||
                role == 'super_admin';
          })
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList();
    });

class AdminCoordinatorsScreen extends ConsumerWidget {
  const AdminCoordinatorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    if (!authState.isAuthenticated || authState.user?.isAdmin != true) {
      return const Scaffold(
        body: Center(child: Text('Administrator access required')),
      );
    }

    final coordinators = ref.watch(adminCoordinatorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coordinators'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _showSearch(context, coordinators.value ?? []),
          ),
        ],
      ),
      body: coordinators.when(
        loading: () => const AppLoadingState(),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 24),
                Text(
                  'Could not load coordinators',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(adminCoordinatorsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.badge_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No coordinators found',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminCoordinatorsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == items.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: () =>
                            ref.invalidate(adminCoordinatorsProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ),
                  );
                }
                return _CoordinatorTile(
                  coordinator: items[index],
                  onTap: () => _showDetailDialog(context, items[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showSearch(BuildContext context, List<Map<String, dynamic>> items) {
    showSearch(context: context, delegate: _CoordinatorSearchDelegate(items));
  }

  void _showDetailDialog(
    BuildContext context,
    Map<String, dynamic> coordinator,
  ) {
    final fullName = coordinator['fullName'] as String? ?? 'Unnamed';
    final email = coordinator['email'] as String? ?? 'No email';
    final role = coordinator['role'] as String? ?? 'user';
    final status = coordinator['status'] as String? ?? 'unknown';
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
              _detailRow('Role', role),
              _detailRow('Status', status),
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
}

class _CoordinatorTile extends StatelessWidget {
  final Map<String, dynamic> coordinator;
  final VoidCallback? onTap;

  const _CoordinatorTile({required this.coordinator, this.onTap});

  @override
  Widget build(BuildContext context) {
    final email = coordinator['email'] as String? ?? 'No email';
    final fullName = coordinator['fullName'] as String? ?? 'Unnamed';
    final role = coordinator['role'] as String? ?? 'user';
    final status = coordinator['status'] as String? ?? 'unknown';

    return Card(
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: role == 'admin'
                ? AppColors.accentBlue.withValues(alpha: 0.12)
                : AppColors.success.withValues(alpha: 0.12),
            child: Icon(
              role == 'admin'
                  ? Icons.admin_panel_settings_rounded
                  : Icons.badge_rounded,
              color: role == 'admin' ? AppColors.accentBlue : AppColors.success,
            ),
          ),
          title: Text(
            fullName,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text('$email\nRole: $role • Status: $status'),
          isThreeLine: true,
          trailing: Chip(
            label: Text(
              role == 'admin' ? 'Admin' : 'Coordinator',
              style: TextStyle(
                color: role == 'admin'
                    ? AppColors.accentBlue
                    : AppColors.success,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: role == 'admin'
                ? AppColors.accentBlue.withValues(alpha: 0.1)
                : AppColors.success.withValues(alpha: 0.1),
          ),
        ),
      ),
    );
  }
}

class _CoordinatorSearchDelegate extends SearchDelegate<Map<String, dynamic>> {
  final List<Map<String, dynamic>> items;

  _CoordinatorSearchDelegate(this.items);

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, items.first),
  );

  @override
  Widget buildResults(BuildContext context) => _buildResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildResults();

  Widget _buildResults() {
    final q = query.toLowerCase();
    final filtered = items.where((item) {
      final name = (item['fullName'] as String? ?? '').toLowerCase();
      final email = (item['email'] as String? ?? '').toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
    if (filtered.isEmpty) return const AppEmptyState(message: 'No results');
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(filtered[index]['fullName'] as String? ?? 'Unnamed'),
        subtitle: Text(filtered[index]['email'] as String? ?? ''),
        onTap: () => close(context, filtered[index]),
      ),
    );
  }
}
