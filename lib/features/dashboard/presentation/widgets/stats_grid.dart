import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/dashboard_stats.dart';

class StatsGrid extends StatelessWidget {
  final DashboardStats stats;

  const StatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final cards = <_StatItem>[
      _StatItem(
        label: 'Total Members',
        value: stats.totalMembers,
        icon: Icons.groups_rounded,
        accent: AppColors.accentBlue,
      ),
      _StatItem(
        label: 'Pending Apps',
        value: stats.pendingApplications,
        icon: Icons.pending_actions_rounded,
        accent: AppColors.warning,
      ),
      _StatItem(
        label: 'Volunteers',
        value: stats.totalVolunteers,
        icon: Icons.volunteer_activism_rounded,
        accent: AppColors.success,
      ),
      _StatItem(
        label: 'Opportunities',
        value: stats.activeOpportunities,
        icon: Icons.event_available_rounded,
        accent: AppColors.navyDeep,
      ),
      _StatItem(
        label: 'Coordinators',
        value: stats.totalCoordinators,
        icon: Icons.badge_rounded,
        accent: const Color(0xFF6D5BD0),
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
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });
}

class _CompactStatCard extends StatelessWidget {
  final _StatItem item;

  const _CompactStatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 18, color: item.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.label, style: AppTextStyles.statLabel),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: item.value),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedValue, _) {
                    return Text(
                      '$animatedValue',
                      style: AppTextStyles.statValue.copyWith(fontSize: 22),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
