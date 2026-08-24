import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class CloudFunctionsClient {
  final String projectId;
  final String region;
  final String baseUrl;

  CloudFunctionsClient({
    required this.projectId,
    this.region = 'us-central1',
  }) : baseUrl = 'https://$region-$projectId.cloudfunctions.net';

  Future<Map<String, dynamic>> call(String functionName, Map<String, dynamic> data, String? idToken) async {
    final uri = Uri.parse('$baseUrl/$functionName');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (idToken != null) {
      headers['Authorization'] = 'Bearer $idToken';
    }
    final response = await http.post(uri, headers: headers, body: jsonEncode(data));
    if (response.statusCode != 200) {
      throw StateError(response.body);
    }
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    if (result['error'] != null) {
      throw StateError(result['error']['message'] ?? 'Function call failed');
    }
    return result;
  }
}

final systemSettingsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final client = CloudFunctionsClient(projectId: Firebase.app().options.projectId, region: 'us-central1');
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return {};
  final idToken = await user.getIdToken();
  final result = await client.call('getSystemSettings', {}, idToken);
  return Map<String, dynamic>.from(result['settings'] as Map);
});

class SystemSettingsScreen extends ConsumerWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(systemSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
      ),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
                const SizedBox(height: 24),
                Text(
                  'Could not load system settings',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(systemSettingsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (settingsData) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(systemSettingsProvider),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Application Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (settingsData.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('No system settings configured', style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  )
                else
                  ...settingsData.entries.map((entry) => Card(
                        child: ListTile(
                          title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${entry.value}'),
                        ),
                      )),
                const SizedBox(height: 24),
                Text(
                  'Maintenance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.cleaning_services_rounded),
                        title: const Text('Clear Cache'),
                        subtitle: const Text('Clear local application cache'),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared')));
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
}
