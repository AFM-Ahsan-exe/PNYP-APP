import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../app/theme/app_colors.dart';
import '../providers/opportunities_providers.dart';

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

class OpportunityDetailScreen extends ConsumerWidget {
  final String opportunityId;

  const OpportunityDetailScreen({super.key, required this.opportunityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunityAsync = ref.watch(opportunityDetailProvider(opportunityId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Opportunity Details'),
      ),
      body: opportunityAsync.when(
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
                  'Could not load opportunity details',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(opportunityDetailProvider(opportunityId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (opportunity) {
          if (opportunity.isEmpty) {
            return const Center(child: Text('Opportunity not found'));
          }
          final title = opportunity['title'] as String? ?? 'Untitled';
          final description = opportunity['description'] as String? ?? 'No description';
          final organization = opportunity['organization'] as String? ?? 'Unknown';
          final location = opportunity['location'] as String? ?? '';
          final isRemote = opportunity['isRemote'] as bool? ?? false;
          final applyUrl = opportunity['applyUrl'] as String? ?? '';
          final deadline = opportunity['deadline'] is Timestamp
              ? (opportunity['deadline'] as Timestamp).toDate()
              : null;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(opportunityDetailProvider(opportunityId)),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  organization,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.accentBlue),
                ),
                const SizedBox(height: 20),
                _InfoRow(icon: Icons.location_on_rounded, label: 'Location', value: isRemote ? 'Remote' : location),
                const SizedBox(height: 12),
                if (deadline != null)
                  _InfoRow(icon: Icons.calendar_today_rounded, label: 'Deadline', value: '${deadline.day}/${deadline.month}/${deadline.year}'),
                const SizedBox(height: 20),
                Text('Description', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)),
                const SizedBox(height: 24),
                if (applyUrl.isNotEmpty)
                  FilledButton.icon(
                    onPressed: () => _trackClickAndOpen(context, opportunityId, applyUrl),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Apply Now'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _trackClickAndOpen(BuildContext context, String opportunityId, String applyUrl) async {
    try {
      final client = CloudFunctionsClient(projectId: Firebase.app().options.projectId, region: 'us-central1');
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final idToken = await user.getIdToken();
        await client.call('trackOpportunityClick', {'opportunityId': opportunityId}, idToken);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening application link...')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.accentBlue),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
      ],
    );
  }
}
