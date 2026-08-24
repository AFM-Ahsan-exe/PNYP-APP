import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/dashboard_stats.dart';
import 'stat_card.dart';

class StatsGrid extends StatelessWidget {
  final DashboardStats stats;

  const StatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final cards = <StatCard>[
      StatCard(
        label: 'Total Members',
        value: stats.totalMembers,
        icon: Icons.groups_rounded,
        accent: AppColors.accentBlue,
      ),
      StatCard(
        label: 'Volunteers',
        value: stats.totalVolunteers,
        icon: Icons.volunteer_activism_rounded,
        accent: AppColors.success,
      ),
      StatCard(
        label: 'Coordinators',
        value: stats.totalCoordinators,
        icon: Icons.badge_rounded,
        accent: const Color(0xFF6D5BD0),
      ),
      StatCard(
        label: 'Pending Applications',
        value: stats.pendingApplications,
        icon: Icons.pending_actions_rounded,
        accent: AppColors.warning,
      ),
      StatCard(
        label: 'Active Opportunities',
        value: stats.activeOpportunities,
        icon: Icons.event_available_rounded,
        accent: AppColors.error,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100
            ? 5
            : width >= 800
                ? 3
                : width >= 520
                    ? 2
                    : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: columns == 1 ? 2.6 : 1.35,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }
}
