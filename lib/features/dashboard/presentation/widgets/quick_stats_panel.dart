import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../renewal/presentation/providers/renewal_providers.dart';
import '../providers/dashboard_providers.dart';

class QuickStatsPanel extends ConsumerWidget {
  const QuickStatsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final renewalsAsync = ref.watch(pendingRenewalsProvider);
    final unreadAsync = ref.watch(unreadNotificationCountStreamProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Stats', style: AppTextStyles.title),
            const SizedBox(height: 12),
            _StatRow(
              icon: Icons.fact_check_rounded,
              color: AppColors.warning,
              label: 'Pending Applications',
              value: statsAsync.asData?.value.pendingApplications,
              onTap: () => context.push('/admin/applications'),
            ),
            const Divider(height: 20),
            _StatRow(
              icon: Icons.refresh_rounded,
              color: AppColors.accentBlue,
              label: 'Pending Renewals',
              value: renewalsAsync.asData?.value.length,
              onTap: () => context.push('/admin/renewals'),
            ),
            const Divider(height: 20),
            _StatRow(
              icon: Icons.notifications_active_rounded,
              color: AppColors.success,
              label: 'Unread Notifications',
              value: unreadAsync.asData?.value,
              onTap: () => context.push('/admin/notifications'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int? value;
  final VoidCallback onTap;

  const _StatRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: AppTextStyles.body.copyWith(fontSize: 13)),
          ),
          value == null
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  '$value',
                  style: AppTextStyles.statValue.copyWith(fontSize: 18),
                ),
        ],
      ),
    );
  }
}