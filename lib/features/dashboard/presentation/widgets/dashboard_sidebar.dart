import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

class DashboardNavItem {
  final String label;
  final IconData icon;

  const DashboardNavItem(this.label, this.icon);
}

const List<DashboardNavItem> dashboardNavItems = [
  DashboardNavItem('Overview', Icons.dashboard_rounded),
  DashboardNavItem('Members', Icons.groups_rounded),
  DashboardNavItem('Volunteers', Icons.volunteer_activism_rounded),
  DashboardNavItem('Coordinators', Icons.badge_rounded),
  DashboardNavItem('Applications', Icons.description_rounded),
  DashboardNavItem('Renewals', Icons.refresh_rounded),
  DashboardNavItem('Opportunities', Icons.event_available_rounded),
  DashboardNavItem('Notifications', Icons.notifications_rounded),
  DashboardNavItem('Audit Logs', Icons.history_rounded),
  DashboardNavItem('Settings', Icons.settings_rounded),
];

class DashboardSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool extended;

  const DashboardSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    this.extended = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navyDarkest,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'P',
                        style: TextStyle(
                          color: AppColors.navyDarkest,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  if (extended) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'PYNP Admin',
                        style: TextStyle(
                          color: AppColors.textOnDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: dashboardNavItems.length,
                itemBuilder: (context, index) {
                  final item = dashboardNavItems[index];
                  final selected = index == selectedIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => onSelect(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 20,
                                color: selected
                                    ? AppColors.accentBlueLight
                                    : AppColors.textOnDarkMuted,
                              ),
                              if (extended) ...[
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: AppTextStyles.body.copyWith(
                                      color: selected
                                          ? AppColors.textOnDark
                                          : AppColors.textOnDarkMuted,
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
