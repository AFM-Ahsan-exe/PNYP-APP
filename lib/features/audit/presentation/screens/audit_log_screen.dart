import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../app/theme/app_colors.dart';

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

final auditLogsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = CloudFunctionsClient(projectId: Firebase.app().options.projectId, region: 'us-central1');
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];
  final idToken = await user.getIdToken();
  final result = await client.call('getAuditLogs', {}, idToken);
  return List<Map<String, dynamic>>.from(result['logs'] as List);
});

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(auditLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
      ),
      body: logs.when(
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
                  'Could not load audit logs',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(auditLogsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No audit logs found'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(auditLogsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _LogTile(log: items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final Map<String, dynamic> log;

  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final actionType = log['actionType'] as String? ?? 'UNKNOWN';
    final targetCollection = log['targetCollection'] as String? ?? '';
    final timestamp = log['timestamp'] is Timestamp
        ? (log['timestamp'] as Timestamp).toDate()
        : DateTime.now();
    final userRole = log['userRole'] as String? ?? 'unknown';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _actionColor(actionType).withValues(alpha: 0.1),
          child: Icon(_actionIcon(actionType), color: _actionColor(actionType), size: 20),
        ),
        title: Text(
          '$actionType on $targetCollection',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(
          'By $userRole • ${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }

  IconData _actionIcon(String actionType) {
    switch (actionType) {
      case 'CREATE':
        return Icons.add_circle_outline_rounded;
      case 'UPDATE':
        return Icons.edit_outlined;
      case 'DELETE':
        return Icons.delete_outline_rounded;
      case 'APPROVE':
        return Icons.check_circle_outline_rounded;
      case 'REJECT':
        return Icons.cancel_outlined;
      case 'READ':
        return Icons.visibility_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _actionColor(String actionType) {
    switch (actionType) {
      case 'CREATE':
        return AppColors.success;
      case 'UPDATE':
        return AppColors.accentBlue;
      case 'DELETE':
        return AppColors.error;
      case 'APPROVE':
        return AppColors.success;
      case 'REJECT':
        return AppColors.error;
      case 'READ':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }
}
