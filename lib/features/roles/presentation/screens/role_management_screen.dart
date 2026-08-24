import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
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

final usersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final snapshot = await FirebaseFirestore.instance.collection('users').limit(100).get();
  return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
});

class RoleManagementScreen extends ConsumerWidget {
  const RoleManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Role Management'),
      ),
      body: users.when(
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
                  'Could not load users',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(usersProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No users found'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(usersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
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
    final uid = widget.user['uid'] as String? ?? widget.user['id'] as String? ?? '';
    final email = widget.user['email'] as String? ?? 'No email';
    final fullName = widget.user['fullName'] as String? ?? 'Unknown';
    final currentRole = widget.user['role'] as String? ?? 'member';

    return Card(
      child: ListTile(
        title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(email),
        trailing: DropdownButton<String>(
          value: _selectedRole ?? currentRole,
          items: const [
            DropdownMenuItem(value: 'member', child: Text('Member')),
            DropdownMenuItem(value: 'district_coordinator', child: Text('District Coordinator')),
            DropdownMenuItem(value: 'regional_coordinator', child: Text('Regional Coordinator')),
            DropdownMenuItem(value: 'content_manager', child: Text('Content Manager')),
            DropdownMenuItem(value: 'opportunity_manager', child: Text('Opportunity Manager')),
            DropdownMenuItem(value: 'national_admin', child: Text('National Admin')),
            DropdownMenuItem(value: 'president', child: Text('President')),
            DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
          ],
          onChanged: (value) async {
            if (value == null || value == currentRole) return;
            setState(() => _selectedRole = value);
            try {
              final client = CloudFunctionsClient(projectId: Firebase.app().options.projectId, region: 'us-central1');
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) throw StateError('No authenticated user');
              final idToken = await user.getIdToken();
              await client.call('updateUserRole', {'uid': uid, 'role': value}, idToken);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Role updated to $value')));
                ref.invalidate(usersProvider);
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
            }
          },
        ),
      ),
    );
  }
}
