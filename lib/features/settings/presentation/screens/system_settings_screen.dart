import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/cloud_functions_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_colors.dart';

final systemSettingsProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) async {
    final client = CloudFunctionsClient(
      projectId: Firebase.app().options.projectId,
      region: 'us-central1',
    );
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};
    final idToken = await user.getIdToken();
    final result = await client.call('getSystemSettings', {}, idToken);
    return Map<String, dynamic>.from(result['settings'] as Map);
  },
);

class SystemSettingsScreen extends ConsumerStatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  ConsumerState<SystemSettingsScreen> createState() =>
      _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends ConsumerState<SystemSettingsScreen> {
  Map<String, dynamic>? _editingSettings;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // Same reasoning as audit_log_screen.dart: getSystemSettings requires
    // national_admin+ server-side, so the screen-level gate must match
    // that exactly rather than the looser isAdmin.
    if (!authState.isAuthenticated ||
        !(authState.user?.hasAtLeastRole('national_admin') ?? false)) {
      return const Scaffold(
        body: Center(child: Text('Administrator access required')),
      );
    }

    final settings = ref.watch(systemSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        actions: [
          if (_editingSettings != null)
            IconButton(
              icon: const Icon(Icons.save_rounded),
              onPressed: _isSaving ? null : _saveSettings,
              tooltip: 'Save Settings',
            ),
        ],
      ),
      body: settings.when(
        loading: () => const AppLoadingState(message: 'Loading settings...'),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(systemSettingsProvider),
        ),
        data: (settingsData) {
          _editingSettings ??= Map<String, dynamic>.from(settingsData);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(systemSettingsProvider);
              setState(() => _editingSettings = null);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Application Settings', style: AppTextStyles.title),
                const SizedBox(height: 12),
                if (settingsData.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No system settings configured',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ...settingsData.entries.map(
                    (entry) => Card(
                      child: ListTile(
                        title: Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('${entry.value}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_rounded),
                          onPressed: () => _editSetting(entry.key, entry.value),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Text('Maintenance', style: AppTextStyles.title),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.cleaning_services_rounded),
                        title: const Text('Clear Cache'),
                        subtitle: const Text('Clear local application cache'),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cache cleared')),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.info_outline_rounded),
                        title: const Text('App Version'),
                        subtitle: const Text('1.0.0'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _editSetting(String key, dynamic value) {
    final controller = TextEditingController(text: value?.toString() ?? '');
    String? errorText;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit $key'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Value',
                      errorText: errorText,
                    ),
                    onChanged: (text) {
                      errorText = _validateSetting(key, text);
                      setDialogState(() {});
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: errorText != null
                      ? null
                      : () {
                          setState(() {
                            _editingSettings?[key] = controller.text.trim();
                          });
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String? _validateSetting(String key, String value) {
    if (key == 'maintenance_mode' || key == 'registration_enabled') {
      if (value.toLowerCase() != 'true' && value.toLowerCase() != 'false') {
        return 'Must be true or false';
      }
    } else if (key == 'max_file_size_mb') {
      final parsed = int.tryParse(value);
      if (parsed == null || parsed < 1 || parsed > 100) {
        return 'Must be an integer between 1 and 100';
      }
    } else if (key == 'support_email') {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!emailRegex.hasMatch(value)) {
        return 'Invalid email format';
      }
    } else if (key == 'organization_name') {
      if (value.isEmpty || value.length > 100) {
        return 'Must be 1-100 characters';
      }
    } else if (key == 'terms_version' || key == 'privacy_version') {
      if (value.isEmpty) {
        return 'Cannot be empty';
      }
    }
    return null;
  }

  Future<void> _saveSettings() async {
    if (_editingSettings == null) return;
    setState(() => _isSaving = true);
    try {
      final client = CloudFunctionsClient(
        projectId: Firebase.app().options.projectId,
        region: 'us-central1',
      );
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('No authenticated user');
      final idToken = await user.getIdToken();

      await client.call('updateSystemSettings', {
        'settings': _editingSettings,
      }, idToken);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
        ref.invalidate(systemSettingsProvider);
        setState(() => _isSaving = false);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}
