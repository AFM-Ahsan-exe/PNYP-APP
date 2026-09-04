import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/growth_point.dart';

class StatsGrid extends StatelessWidget {
  final DashboardStats stats;
  final GrowthPoint? oldest;

  const StatsGrid({super.key, required this.stats, this.oldest});

  double? _trend(int current, int? past) {
    if (past == null || past == 0) return null;
    return (current - past) / past * 100;
  }

  @override
  Widget build(BuildContext context) {
    final cards = <_StatItem>[
      _StatItem(
        label: 'Total Members',
        value: stats.totalMembers,
        icon: Icons.groups_rounded,
        accent: AppColors.accentBlue,
        trend: _trend(stats.totalMembers, oldest?.totalMembers),
      ),
      _StatItem(
        label: 'Pending Apps',
        value: stats.pendingApplications,
        icon: Icons.pending_actions_rounded,
        accent: AppColors.warning,
        trend: _trend(stats.pendingApplications, oldest?.pendingApplications),
      ),
      _StatItem(
        label: 'Volunteers',
        value: stats.totalVolunteers,
        icon: Icons.volunteer_activism_rounded,
        accent: AppColors.success,
        trend: _trend(stats.totalVolunteers, oldest?.totalVolunteers),
      ),
      _StatItem(
        label: 'Opportunities',
        value: stats.activeOpportunities,
        icon: Icons.event_available_rounded,
        accent: AppColors.navyDeep,
        trend: _trend(stats.activeOpportunities, oldest?.activeOpportunities),
      ),
      _StatItem(
        label: 'Coordinators',
        value: stats.totalCoordinators,
        icon: Icons.badge_rounded,
        accent: const Color(0xFF6D5BD0),
        trend: _trend(stats.totalCoordinators, oldest?.totalCoordinators),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900
            ? 5
            : width >= 600
            ? 3
            : width >= 400
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 2.2 : 1.35,
          ),
          itemBuilder: (context, index) => _CompactStatCard(item: cards[index]),
        );
      },
    );
  }
}

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color accent;
  final double? trend;
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.trend,
  });
}

class _CompactStatCard extends StatelessWidget {
  final _StatItem item;

  const _CompactStatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 20, color: item.accent),
          ),
          const SizedBox(height: 12),
          Text(item.label, style: AppTextStyles.statLabel),
          const SizedBox(height: 2),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: item.value),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) {
              return Text(
                '$animatedValue',
                style: AppTextStyles.statValue.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              );
            },
          ),
          if (item.trend != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  item.trend! >= 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 12,
                  color: item.trend! >= 0
                      ? AppColors.success
                      : AppColors.error,
                ),
                const SizedBox(width: 2),
                Text(
                  '${item.trend!.abs().toStringAsFixed(1)}%',
                  style: AppTextStyles.caption.copyWith(
                    color: item.trend! >= 0
                        ? AppColors.success
                        : AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}