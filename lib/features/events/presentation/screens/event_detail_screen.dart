import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../app/theme/app_colors.dart';
import '../providers/events_providers.dart';

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

class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final regAsync = ref.watch(eventRegistrationStatusProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: eventAsync.when(
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
                  'Could not load event details',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(eventDetailProvider(eventId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (event) {
          if (event.isEmpty) {
            return const Center(child: Text('Event not found'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(eventDetailProvider(eventId));
              ref.invalidate(eventRegistrationStatusProvider(eventId));
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  event['title'] as String? ?? 'Untitled Event',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  event['eventType'] as String? ?? 'Event',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.accentBlue),
                ),
                const SizedBox(height: 20),
                if (event['coverImageUrl'] != null && (event['coverImageUrl'] as String).isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(event['coverImageUrl'] as String, width: double.infinity, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 20),
                _InfoRow(icon: Icons.calendar_today_rounded, label: 'Start', value: _formatDateTime((event['startDateTime'] as Timestamp?)?.toDate())),
                const SizedBox(height: 12),
                _InfoRow(icon: Icons.event_busy_rounded, label: 'End', value: _formatDateTime((event['endDateTime'] as Timestamp?)?.toDate())),
                const SizedBox(height: 12),
                if (event['location'] != null && (event['location'] as String).isNotEmpty)
                  _InfoRow(icon: Icons.location_on_rounded, label: 'Location', value: event['location'] as String),
                const SizedBox(height: 12),
                _InfoRow(icon: Icons.people_rounded, label: 'Participants', value: '${event['currentParticipants'] ?? 0}${event['maxParticipants'] != null && event['maxParticipants'] > 0 ? " / ${event['maxParticipants']}" : ""}'),
                const SizedBox(height: 20),
                Text('Description', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(event['description'] as String? ?? 'No description provided'),
                const SizedBox(height: 24),
                regAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => const SizedBox.shrink(),
                  data: (registration) {
                    final isRegistered = registration != null;
                    final isAttended = registration?['attended'] as bool? ?? false;
                    return Column(
                      children: [
                        if (isRegistered && !isAttended)
                          FilledButton.icon(
                            onPressed: () => _cancelRegistration(context, eventId),
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancel Registration'),
                            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                          ),
                        if (!isRegistered)
                          FilledButton.icon(
                            onPressed: () => _registerForEvent(context, eventId),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Register'),
                          ),
                        if (isAttended)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: AppColors.success),
                                SizedBox(width: 10),
                                Text('You have attended this event', style: TextStyle(color: AppColors.success)),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _registerForEvent(BuildContext context, String eventId) async {
    try {
      final client = CloudFunctionsClient(projectId: Firebase.app().options.projectId, region: 'us-central1');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('No authenticated user');
      final idToken = await user.getIdToken();
      await client.call('registerForEvent', {'eventId': eventId}, idToken);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registered successfully')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _cancelRegistration(BuildContext context, String eventId) async {
    try {
      final client = CloudFunctionsClient(projectId: Firebase.app().options.projectId, region: 'us-central1');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('No authenticated user');
      final idToken = await user.getIdToken();
      await client.call('cancelEventRegistration', {'eventId': eventId}, idToken);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration cancelled')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Not specified';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
