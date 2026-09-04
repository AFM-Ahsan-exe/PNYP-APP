import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  Map<String, bool> _preferences = {
    'events': true,
    'news': true,
    'documents': true,
    'opportunities': true,
    'volunteers': true,
    'payments': true,
  };

  @override
  void initState() {
    super.initState();
    // This screen previously always rendered its hardcoded defaults (all
    // switches on) regardless of what the user had actually saved -
    // reopening the screen silently discarded any preference they'd
    // turned off. AppUser.notificationPreferences is already loaded as
    // part of auth state, so merge it in here rather than doing a
    // redundant separate Firestore read.
    final saved = ref.read(authControllerProvider).user?.notificationPreferences;
    if (saved != null && saved.isNotEmpty) {
      _preferences = {..._preferences, ...saved};
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    if (!authState.isAuthenticated) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to manage notification preferences'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Choose what notifications you receive',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ..._preferences.entries.map(
            (entry) => Card(
              child: SwitchListTile(
                secondary: Icon(_getIconForCategory(entry.key)),
                title: Text(_getTitleForCategory(entry.key)),
                subtitle: Text(_getDescriptionForCategory(entry.key)),
                value: entry.value,
                onChanged: (value) {
                  setState(() {
                    _preferences[entry.key] = value;
                  });
                  _savePreference(context, entry.key, value);
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.restore_rounded),
            label: const Text('Reset to Defaults'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navyDarkest,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'events':
        return Icons.event_rounded;
      case 'news':
        return Icons.article_rounded;
      case 'documents':
        return Icons.description_rounded;
      case 'opportunities':
        return Icons.work_outline_rounded;
      case 'volunteers':
        return Icons.volunteer_activism_rounded;
      case 'payments':
        return Icons.payments_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _getTitleForCategory(String category) {
    switch (category) {
      case 'events':
        return 'Events';
      case 'news':
        return 'News & Announcements';
      case 'documents':
        return 'Documents';
      case 'opportunities':
        return 'Opportunities';
      case 'volunteers':
        return 'Volunteer Activities';
      case 'payments':
        return 'Payment Receipts';
      default:
        return category;
    }
  }

  String _getDescriptionForCategory(String category) {
    switch (category) {
      case 'events':
        return 'Event reminders, registration confirmations, and updates';
      case 'news':
        return 'New articles, announcements, and broadcast messages';
      case 'documents':
        return 'New document uploads and document-related notifications';
      case 'opportunities':
        return 'New opportunities and application status updates';
      case 'volunteers':
        return 'Volunteer application updates and opportunities';
      case 'payments':
        return 'Payment confirmations and receipts';
      default:
        return 'Notifications for $category';
    }
  }

  Future<void> _savePreference(
    BuildContext context,
    String category,
    bool value,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

                  await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'notificationPreferences': _preferences,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_getTitleForCategory(category)} notifications ${value ? 'enabled' : 'disabled'}',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving preferences: $e')));
    }
  }

  void _resetToDefaults() {
    setState(() {
      _preferences = {
        'events': true,
        'news': true,
        'documents': true,
        'opportunities': true,
        'volunteers': true,
        'payments': true,
      };
    });
  }
}
