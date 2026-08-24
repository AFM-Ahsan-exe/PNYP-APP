import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';

final analyticsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
  final eventsSnapshot = await FirebaseFirestore.instance.collection('events').get();
  final documentsSnapshot = await FirebaseFirestore.instance.collection('documents').get();
  final newsSnapshot = await FirebaseFirestore.instance.collection('news').get();

  final totalUsers = usersSnapshot.size;
  final approvedMembers = usersSnapshot.docs.where((doc) => doc.data()['status'] == 'approved').length;
  final pendingMembers = usersSnapshot.docs.where((doc) => doc.data()['status'] == 'pending').length;
  final totalEvents = eventsSnapshot.size;
  final totalDocuments = documentsSnapshot.size;
  final totalNews = newsSnapshot.size;

  return {
    'totalUsers': totalUsers,
    'approvedMembers': approvedMembers,
    'pendingMembers': pendingMembers,
    'totalEvents': totalEvents,
    'totalDocuments': totalDocuments,
    'totalNews': totalNews,
  };
});

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
      ),
      body: analytics.when(
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
                  'Could not load analytics',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(analyticsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (stats) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(analyticsProvider),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _StatCard(label: 'Total Users', value: '${stats['totalUsers']}', icon: Icons.people_rounded, color: AppColors.accentBlue),
                    _StatCard(label: 'Approved Members', value: '${stats['approvedMembers']}', icon: Icons.check_circle_rounded, color: AppColors.success),
                    _StatCard(label: 'Pending Members', value: '${stats['pendingMembers']}', icon: Icons.pending_rounded, color: AppColors.accentBlue),
                    _StatCard(label: 'Total Events', value: '${stats['totalEvents']}', icon: Icons.event_rounded, color: AppColors.accentBlue),
                    _StatCard(label: 'Documents', value: '${stats['totalDocuments']}', icon: Icons.description_rounded, color: AppColors.textSecondary),
                    _StatCard(label: 'News Articles', value: '${stats['totalNews']}', icon: Icons.article_rounded, color: AppColors.navyDeep),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
