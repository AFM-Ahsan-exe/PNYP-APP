import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/cloud_functions_client.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_empty_state.dart';

class ReportsHistoryScreen extends ConsumerWidget {
  const ReportsHistoryScreen({super.key});

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Map<String, dynamic>) {
      final seconds = value['seconds'] as int?;
      final nanoseconds = value['nanoseconds'] as int?;
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + (nanoseconds ?? 0) ~/ 1000000,
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
      (ref) async {
        final client = CloudFunctionsClient(
          projectId: Firebase.app().options.projectId,
          region: 'us-central1',
        );
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return [];
        final idToken = await user.getIdToken();
        final result = await client.call('getReportHistory', {}, idToken);
        final reports = result['reports'] as List<dynamic>? ?? [];
        return reports.map((r) => Map<String, dynamic>.from(r as Map)).toList();
      },
    );

    final reports = ref.watch(reportsAsync);

    return Scaffold(
      appBar: AppBar(title: const Text('Report History')),
      body: reports.when(
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
                  'Could not load reports',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(reportsAsync),
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
                message: 'No reports generated yet',
                icon: Icons.history_rounded,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final report = items[index];
              final reportType = report['reportType'] as String? ?? 'unknown';
              final status = report['status'] as String? ?? 'unknown';
              final generatedAt =
                  _parseTimestamp(report['generatedAt']) ?? DateTime.now();

              return Card(
                child: ListTile(
                  title: Text(
                    '${reportType[0].toUpperCase()}${reportType.substring(1)} Report',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Generated: ${generatedAt.day}/${generatedAt.month}/${generatedAt.year} • Status: $status',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: status == 'completed'
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(
                        color: status == 'completed'
                            ? AppColors.success
                            : AppColors.accentBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
