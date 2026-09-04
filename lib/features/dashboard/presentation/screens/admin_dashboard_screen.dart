import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';
import 'admin_members_screen.dart';
import 'admin_volunteers_screen.dart';
import 'admin_coordinators_screen.dart';
import 'admin_applications_screen.dart';
import 'admin_renewals_screen.dart';
import '../../../opportunities/presentation/screens/admin_opportunities_screen.dart';
import 'admin_notifications_screen.dart';
import '../widgets/admin_profile_menu.dart';
import '../../../../features/audit/presentation/screens/audit_log_screen.dart';
import '../../../../features/settings/presentation/screens/system_settings_screen.dart';
import '../widgets/breakdown_chart.dart';
import '../widgets/dashboard_sidebar.dart';
import '../widgets/dashboard_state_views.dart';
import '../widgets/stats_grid.dart';
import '../widgets/recent_activity_list.dart';
import '../../../../core/widgets/app_loading_state.dart';

const double _mobileBreakpoint = 700;
const double _desktopBreakpoint = 1100;

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  void _selectNav(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < _mobileBreakpoint;
    final isDesktop = width >= _desktopBreakpoint;

    final content = switch (_selectedIndex) {
      0 => const _DashboardOverview(),
      1 => const AdminMembersScreen(),
      2 => const AdminVolunteersScreen(),
      3 => const AdminCoordinatorsScreen(),
      4 => const AdminApplicationsScreen(),
      5 => const AdminRenewalsScreen(),
      6 => const AdminOpportunitiesScreen(),
      7 => const AdminNotificationsScreen(),
      8 => const AuditLogScreen(),
      9 => const SystemSettingsScreen(),
      _ => const _DashboardOverview(),
    };

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        drawer: Drawer(
          width: 260,
          child: DashboardSidebar(
            selectedIndex: _selectedIndex,
            onSelect: (i) {
              Navigator.of(context).pop();
              _selectNav(i);
            },
          ),
        ),
        appBar: _DashboardAppBar(
          showMenuButton: true,
          selectedIndex: _selectedIndex,
        ),
        body: content,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Row(
        children: [
          SizedBox(
            width: isDesktop ? 240 : 76,
            child: DashboardSidebar(
              selectedIndex: _selectedIndex,
              onSelect: _selectNav,
              extended: isDesktop,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _DashboardAppBar(
                  showMenuButton: false,
                  selectedIndex: _selectedIndex,
                ),
                Expanded(child: content),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showMenuButton;
  final int selectedIndex;

  const _DashboardAppBar({
    required this.showMenuButton,
    required this.selectedIndex,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final titles = const [
      'Dashboard Overview',
      'Members',
      'Volunteers',
      'Coordinators',
      'Applications',
      'Renewals',
      'Opportunities',
      'Notifications',
      'Audit Logs',
      'Settings',
    ];
    final title = titles[selectedIndex];

    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.headline,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const _NotificationsBell(),
          const SizedBox(width: 12),
          const AdminProfileMenu(),
        ],
      ),
    );
  }
}

class _NotificationsBell extends ConsumerWidget {
  const _NotificationsBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Notifications',
      icon: const Icon(Icons.notifications_none_rounded),
      onPressed: () {
        context.push('/admin/notifications');
      },
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final String name;
  final String roleLabel;

  const _WelcomeBanner({required this.name, required this.roleLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyDarkest, AppColors.navyDeep],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to PYNP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roleLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Here's what's happening across PYNP today.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardOverview extends ConsumerWidget {
  const _DashboardOverview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    if (!authState.isAuthenticated || authState.user?.isAdmin != true) {
      return const Center(child: Text('Administrator access required'));
    }

    final statsAsync = ref.watch(dashboardStatsProvider);
    final activityAsync = ref.watch(recentActivityProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(recentActivityProvider);
        await ref.read(dashboardStatsProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _WelcomeBanner(
            name: authState.user?.fullName?.trim().isNotEmpty == true
                ? authState.user!.fullName!.trim()
                : (authState.user?.displayName ?? 'Administrator'),
            roleLabel: authState.user?.role.displayName ?? 'Administrator',
          ),
          const SizedBox(height: 16),
          statsAsync.when(
            data: (stats) => StatsGrid(stats: stats),
            loading: () => const _CompactLoading(height: 120),
            error: (error, _) => DashboardErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(dashboardStatsProvider),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;

              final chart = statsAsync.when(
                data: (stats) => BreakdownChart(stats: stats),
                loading: () => const _CompactLoading(height: 200),
                error: (error, _) => DashboardErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(dashboardStatsProvider),
                ),
              );

              final activity = activityAsync.when(
                data: (items) => RecentActivityList(items: items),
                loading: () => const _CompactLoading(height: 200),
                error: (error, _) => DashboardErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(recentActivityProvider),
                ),
              );

              if (!wide) {
                return Column(
                  children: [
                    chart,
                    const SizedBox(height: 12),
                    activity,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: chart),
                  const SizedBox(width: 16),
                  Expanded(child: activity),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _QuickActionsRow(
            actions: [
              _QuickActionItem(
                label: 'Review Applications',
                icon: Icons.fact_check_rounded,
                onTap: () => context.push('/admin/applications'),
              ),
              _QuickActionItem(
                label: 'Manage Opportunities',
                icon: Icons.event_available_rounded,
                onTap: () => context.push('/admin/opportunities'),
              ),
              _QuickActionItem(
                label: 'Volunteers',
                icon: Icons.volunteer_activism_rounded,
                onTap: () => context.push('/admin/volunteers'),
              ),
              _QuickActionItem(
                label: 'Renewals',
                icon: Icons.refresh_rounded,
                onTap: () => context.push('/admin/renewals'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactLoading extends StatelessWidget {
  final double height;

  const _CompactLoading({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const AppLoadingState(),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final List<_QuickActionItem> actions;

  const _QuickActionsRow({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions', style: AppTextStyles.title),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = width >= 900
                    ? 4
                    : width >= 500
                    ? 2
                    : 1;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.8,
                  ),
                  itemCount: actions.length,
                  itemBuilder: (context, index) =>
                      _QuickActionChip(action: actions[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class _QuickActionChip extends StatelessWidget {
  final _QuickActionItem action;

  const _QuickActionChip({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              action.icon,
              size: 18,
              color: AppColors.navyDeep,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                action.label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

