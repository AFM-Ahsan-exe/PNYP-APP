import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../providers/analytics_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(analyticsStatsProvider);
    final aggregatesAsync = ref.watch(analyticsAggregatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics Dashboard')),
      body: statsAsync.when(
        loading: () => const AppLoadingState(message: 'Loading analytics...'),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(analyticsStatsProvider),
        ),
        data: (stats) {
          if (stats.isAllZero) {
            return const AppEmptyState(
              message: 'No analytics data available yet',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(analyticsStatsProvider);
              ref.invalidate(analyticsAggregatesProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Overview', style: AppTextStyles.title),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _StatCard(
                      label: 'Total Users',
                      value: '${stats.totalUsers}',
                      icon: Icons.people_rounded,
                      color: AppColors.accentBlue,
                    ),
                    _StatCard(
                      label: 'Approved Members',
                      value: '${stats.approvedMembers}',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.success,
                    ),
                    _StatCard(
                      label: 'Pending Members',
                      value: '${stats.pendingMembers}',
                      icon: Icons.pending_rounded,
                      color: AppColors.warning,
                    ),
                    _StatCard(
                      label: 'Total Events',
                      value: '${stats.totalEvents}',
                      icon: Icons.event_rounded,
                      color: AppColors.accentBlue,
                    ),
                    _StatCard(
                      label: 'Documents',
                      value: '${stats.totalDocuments}',
                      icon: Icons.description_rounded,
                      color: AppColors.textSecondary,
                    ),
                    _StatCard(
                      label: 'News Articles',
                      value: '${stats.totalNews}',
                      icon: Icons.article_rounded,
                      color: AppColors.navyDeep,
                    ),
                    _StatCard(
                      label: 'Volunteers',
                      value: '${stats.totalVolunteers}',
                      icon: Icons.volunteer_activism_rounded,
                      color: AppColors.success,
                    ),
                    _StatCard(
                      label: 'Payments',
                      value: '${stats.totalPayments}',
                      icon: Icons.payments_rounded,
                      color: AppColors.accentBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Recent Trends', style: AppTextStyles.title),
                const SizedBox(height: 12),
                aggregatesAsync.when(
                  loading: () =>
                      const AppLoadingState(message: 'Loading trends...'),
                  error: (error, _) => AppErrorState(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(analyticsAggregatesProvider),
                  ),
                  data: (aggregates) {
                    if (aggregates.isEmpty) {
                      return const AppEmptyState(
                        message: 'No trend data available yet',
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: aggregates.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final agg = aggregates[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${agg.date.day}/${agg.date.month}/${agg.date.year}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    _TrendChip(
                                      label: 'Users',
                                      value: '${agg.totalUsers}',
                                      color: AppColors.accentBlue,
                                    ),
                                    _TrendChip(
                                      label: 'Members',
                                      value: '${agg.activeMembers}',
                                      color: AppColors.success,
                                    ),
                                    _TrendChip(
                                      label: 'Events',
                                      value: '${agg.totalEvents}',
                                      color: AppColors.accentBlue,
                                    ),
                                    _TrendChip(
                                      label: 'Volunteers',
                                      value: '${agg.totalVolunteers}',
                                      color: AppColors.success,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTextStyles.statValue.copyWith(
                fontSize: 20,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.statLabel),
          ],
        ),
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TrendChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
