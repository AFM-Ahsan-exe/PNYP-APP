import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

final volunteersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];
  final snapshot = await FirebaseFirestore.instance
      .collection('volunteers')
      .where('userId', isEqualTo: user.uid)
      .orderBy('appliedAt', descending: true)
      .limit(50)
      .get();
  return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
});

class VolunteerApplicationsScreen extends ConsumerWidget {
  const VolunteerApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(volunteersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Volunteer Applications'),
      ),
      body: applications.when(
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
                  'Could not load applications',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(volunteersProvider),
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
                  Icon(Icons.volunteer_activism_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No volunteer applications yet', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(volunteersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _ApplicationTile(application: items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _ApplicationTile extends StatelessWidget {
  final Map<String, dynamic> application;

  const _ApplicationTile({required this.application});

  @override
  Widget build(BuildContext context) {
    final opportunityId = application['opportunityId'] as String? ?? '';
    final status = application['status'] as String? ?? 'pending';
    final appliedAt = application['appliedAt'] is Timestamp
        ? (application['appliedAt'] as Timestamp).toDate()
        : DateTime.now();

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(status).withValues(alpha: 0.1),
          child: Icon(Icons.volunteer_activism_rounded, color: _statusColor(status)),
        ),
        title: Text(
          'Opportunity: ${opportunityId.isEmpty ? 'Unknown' : opportunityId.substring(0, 8)}...',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'Applied: ${appliedAt.day.toString().padLeft(2, '0')}/${appliedAt.month.toString().padLeft(2, '0')}/${appliedAt.year} • Status: ${_statusLabel(status)}',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor(status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _statusLabel(status),
            style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.accentBlue;
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'completed':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }
}
