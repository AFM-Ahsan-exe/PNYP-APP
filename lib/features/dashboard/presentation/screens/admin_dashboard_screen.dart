import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';
import 'admin_members_screen.dart';
import '../widgets/admin_profile_menu.dart';
import '../widgets/breakdown_chart.dart';
import '../widgets/dashboard_sidebar.dart';
import '../widgets/dashboard_state_views.dart';
import '../widgets/quick_actions_panel.dart';
import '../widgets/recent_activity_list.dart';
import '../widgets/stats_grid.dart';

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
    if (index != 0) {
      // Only the Overview screen is implemented today. Being explicit
      // about this instead of silently doing nothing or faking a screen.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${dashboardNavItems[index].label} management isn\'t built yet.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < _mobileBreakpoint;
    final isDesktop = width >= _desktopBreakpoint;

    final content = _selectedIndex == 1
        ? const AdminMembersScreen()
        : _DashboardContent(selectedIndex: _selectedIndex);

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
        appBar: _DashboardAppBar(showMenuButton: true),
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
                _DashboardAppBar(showMenuButton: false),
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

  const _DashboardAppBar({required this.showMenuButton});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
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
              'Dashboard Overview',
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
        // No dedicated notifications feature/collection exists yet.
        // Being explicit about that instead of fabricating alert data.
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Notifications'),
            content: const Text(
              'Notifications aren\'t set up yet. Recent activity is shown '
              'on the dashboard below.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  final int selectedIndex;

  const _DashboardContent({required this.selectedIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedIndex != 0) {
      return Center(
        child: Text(
          '${dashboardNavItems[selectedIndex].label} coming soon',
          style: AppTextStyles.bodyMuted,
        ),
      );
    }

    final statsAsync = ref.watch(dashboardStatsProvider);
    final activityAsync = ref.watch(recentActivityProvider);
    final authState = ref.watch(authControllerProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(recentActivityProvider);
        await ref.read(dashboardStatsProvider.future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back${authState.user?.displayName != null ? ', ${authState.user!.displayName}' : ''}',
              style: AppTextStyles.title,
            ),
            const SizedBox(height: 4),
            Text(
              'Here\'s what\'s happening across PYNP today.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 24),
            statsAsync.when(
              data: (stats) => StatsGrid(stats: stats),
              loading: () => const DashboardLoadingView(height: 140),
              error: (error, _) => DashboardErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(dashboardStatsProvider),
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                final chart = statsAsync.when(
                  data: (stats) => BreakdownChart(stats: stats),
                  loading: () => const DashboardLoadingView(),
                  error: (error, _) => DashboardErrorView(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(dashboardStatsProvider),
                  ),
                );
                final activity = activityAsync.when(
                  data: (items) => RecentActivityList(items: items),
                  loading: () => const DashboardLoadingView(),
                  error: (error, _) => DashboardErrorView(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(recentActivityProvider),
                  ),
                );

                if (!wide) {
                  return Column(
                    children: [chart, const SizedBox(height: 20), activity],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: chart),
                    const SizedBox(width: 20),
                    Expanded(child: activity),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            QuickActionsPanel(
              actions: [
                QuickAction(
                  label: 'Review Applications',
                  icon: Icons.fact_check_rounded,
                  onTap: () => _notBuiltYet(context, 'Application review'),
                ),
                QuickAction(
                  label: 'Manage Opportunities',
                  icon: Icons.event_available_rounded,
                  onTap: () => _notBuiltYet(context, 'Opportunity management'),
                ),
                QuickAction(
                  label: 'Add Coordinator',
                  icon: Icons.person_add_alt_1_rounded,
                  onTap: () => _notBuiltYet(context, 'Adding coordinators'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _notBuiltYet(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature isn\'t built yet.')));
  }
}
