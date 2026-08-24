import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/activity_item.dart';
import 'dashboard_state_views.dart';

class RecentActivityList extends StatelessWidget {
  final List<ActivityItem> items;

  const RecentActivityList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Activity', style: AppTextStyles.title),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const DashboardEmptyView(
              message: 'No recent activity yet.',
              icon: Icons.history_rounded,
            )
          else
            ...List.generate(items.length, (index) {
              final item = items[index];
              final isLast = index == items.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                child: _ActivityRow(item: item),
              );
            }),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final ActivityItem item;

  const _ActivityRow({required this.item});

  IconData get _icon {
    switch (item.type) {
      case ActivityType.member:
        return Icons.person_add_alt_1_rounded;
      case ActivityType.volunteer:
        return Icons.volunteer_activism_rounded;
      case ActivityType.coordinator:
        return Icons.badge_rounded;
      case ActivityType.application:
        return Icons.description_rounded;
      case ActivityType.opportunity:
        return Icons.event_available_rounded;
      case ActivityType.general:
        return Icons.notifications_none_rounded;
    }
  }

  String get _relativeTime {
    final diff = DateTime.now().difference(item.timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_icon, size: 17, color: AppColors.accentBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: AppTextStyles.body),
              if (item.subtitle != null)
                Text(item.subtitle!, style: AppTextStyles.caption),
            ],
          ),
        ),
        Text(_relativeTime, style: AppTextStyles.caption),
      ],
    );
  }
}