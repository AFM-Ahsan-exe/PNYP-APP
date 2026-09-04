import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_empty_state.dart';

final userActivityProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return Stream.value([]);
      return FirebaseFirestore.instance
          .collection('user_activity')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList(),
          );
    });

class UserActivityScreen extends ConsumerWidget {
  const UserActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(userActivityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Activity Log')),
      body: activityAsync.when(
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
                  'Could not load activity',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(userActivityProvider),
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
              child: const AppEmptyState(
                message: 'No activity yet',
                icon: Icons.history_rounded,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userActivityProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _ActivityTile(
                activity: items[index],
                onTap: () => _showDetailDialog(context, items[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDetailDialog(BuildContext context, Map<String, dynamic> activity) {
    final action = activity['action'] as String? ?? 'unknown';
    final details = activity['details'] as String? ?? '';
    final timestamp = activity['timestamp'] is Timestamp
        ? (activity['timestamp'] as Timestamp).toDate()
        : DateTime.now();
    final metadata = activity['metadata'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_formatAction(action)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (details.isNotEmpty) ...[
                Text('Details', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(details),
                const SizedBox(height: 16),
              ],
              Text('Time: ${_formatTimestamp(timestamp)}'),
              if (metadata != null && metadata.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Additional Info',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                ...metadata.entries.map((e) => Text('${e.key}: ${e.value}')),
              ],
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
}

String _formatAction(String action) {
  switch (action) {
    case 'login':
      return 'Logged in';
    case 'logout':
      return 'Logged out';
    case 'update_profile':
      return 'Updated profile';
    case 'register_event':
      return 'Registered for event';
    case 'apply_volunteer':
      return 'Applied as volunteer';
    default:
      return action.replaceAll('_', ' ').toUpperCase();
  }
}

String _formatTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
}

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> activity;
  final VoidCallback? onTap;

  const _ActivityTile({required this.activity, this.onTap});

  @override
  Widget build(BuildContext context) {
    final action = activity['action'] as String? ?? 'unknown';
    final timestamp = activity['timestamp'] is Timestamp
        ? (activity['timestamp'] as Timestamp).toDate()
        : DateTime.now();
    final details = activity['details'] as String? ?? '';

    return Card(
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _actionColor(action).withValues(alpha: 0.1),
            child: Icon(
              _actionIcon(action),
              color: _actionColor(action),
              size: 20,
            ),
          ),
          title: Text(
            _formatAction(action),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text('$details • ${_formatTimestamp(timestamp)}'),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'login':
        return Icons.login_rounded;
      case 'logout':
        return Icons.logout_rounded;
      case 'update_profile':
        return Icons.edit_rounded;
      case 'register_event':
        return Icons.event_rounded;
      case 'apply_volunteer':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'login':
        return AppColors.success;
      case 'logout':
        return AppColors.textSecondary;
      case 'update_profile':
        return AppColors.accentBlue;
      case 'register_event':
        return AppColors.accentBlue;
      case 'apply_volunteer':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }
}
