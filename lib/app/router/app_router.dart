import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/registration_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/account_status_screen.dart';
import '../../features/auth/presentation/screens/password_reset_screen.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/member_home_screen.dart';
import '../../features/dashboard/presentation/screens/profile_screen.dart';
import '../../features/dashboard/presentation/screens/edit_profile_screen.dart';
import '../../features/dashboard/presentation/screens/renew_membership_screen.dart';
import '../../features/dashboard/presentation/screens/notifications_screen.dart';
import '../../features/events/presentation/screens/events_list_screen.dart';
import '../../features/events/presentation/screens/event_detail_screen.dart';
import '../../features/news/presentation/screens/news_list_screen.dart';
import '../../features/news/presentation/screens/news_detail_screen.dart';
import '../../features/documents/presentation/screens/documents_list_screen.dart';
import '../../features/gallery/presentation/screens/gallery_screen.dart';
import '../../features/opportunities/presentation/screens/opportunities_list_screen.dart';
import '../../features/opportunities/presentation/screens/opportunity_detail_screen.dart';
import '../../features/volunteers/presentation/screens/volunteer_applications_screen.dart';
import '../../features/analytics/presentation/screens/analytics_dashboard_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/roles/presentation/screens/role_management_screen.dart';
import '../../features/audit/presentation/screens/audit_log_screen.dart';
import '../../features/settings/presentation/screens/system_settings_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/settings/presentation/screens/notification_preferences_screen.dart';
import '../../features/activity/presentation/screens/user_activity_screen.dart';
import '../../features/admin/presentation/screens/admin_bulk_actions_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isOnSplash = state.matchedLocation == '/splash';
      final isOnLogin = state.matchedLocation == '/login';
      final isOnHome = state.matchedLocation == '/home';
      final isOnAdmin = state.matchedLocation == '/admin';
      final isOnAccountStatus = state.matchedLocation.startsWith('/account/');
      final isAdmin = authState.user?.role == UserRole.admin;
      final status = authState.user?.status;

      if (isOnSplash) return null;

      if (!isLoggedIn && (isOnAccountStatus || isOnHome || isOnAdmin)) {
        return '/login';
      }

      if (isLoggedIn &&
          status != AccountStatus.approved &&
          !isOnAccountStatus) {
        return '/account/${status?.name ?? AccountStatus.pending.name}';
      }

      if (!isLoggedIn && (isOnHome || isOnAdmin)) return '/login';

      if (isLoggedIn &&
          isOnAdmin &&
          (!isAdmin || status != AccountStatus.approved)) {
        return '/account/${status?.name ?? AccountStatus.pending.name}';
      }

      if (isLoggedIn && isOnLogin) {
        return status == AccountStatus.approved && isAdmin
            ? '/admin'
            : status == AccountStatus.approved
            ? '/home'
            : '/account/${status?.name ?? AccountStatus.pending.name}';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: '/password-reset',
        builder: (context, state) => const PasswordResetScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const MemberHomeScreen()),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/account/:status',
        builder: (context, state) {
          final status = AccountStatus.values.firstWhere(
            (value) => value.name == state.pathParameters['status'],
            orElse: () => AccountStatus.pending,
          );
          return AccountStatusScreen(status: status);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/renew-membership',
        builder: (context, state) => const RenewMembershipScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/events',
        builder: (context, state) => const EventsListScreen(),
      ),
      GoRoute(
        path: '/events/:eventId',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return EventDetailScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/news',
        builder: (context, state) => const NewsListScreen(),
      ),
      GoRoute(
        path: '/news/:articleId',
        builder: (context, state) {
          final articleId = state.pathParameters['articleId']!;
          return NewsDetailScreen(articleId: articleId);
        },
      ),
      GoRoute(
        path: '/documents',
        builder: (context, state) => const DocumentsListScreen(),
      ),
      GoRoute(
        path: '/gallery',
        builder: (context, state) => const GalleryScreen(),
      ),
      GoRoute(
        path: '/opportunities',
        builder: (context, state) => const OpportunitiesListScreen(),
      ),
      GoRoute(
        path: '/opportunities/:opportunityId',
        builder: (context, state) {
          final opportunityId = state.pathParameters['opportunityId']!;
          return OpportunityDetailScreen(opportunityId: opportunityId);
        },
      ),
      GoRoute(
        path: '/volunteers',
        builder: (context, state) => const VolunteerApplicationsScreen(),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsDashboardScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/roles',
        builder: (context, state) => const RoleManagementScreen(),
      ),
      GoRoute(
        path: '/audit-logs',
        builder: (context, state) => const AuditLogScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SystemSettingsScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/notification-preferences',
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
      GoRoute(
        path: '/activity',
        builder: (context, state) => const UserActivityScreen(),
      ),
      GoRoute(
        path: '/admin/bulk-actions',
        builder: (context, state) => const AdminBulkActionsScreen(),
      ),
    ],
  );
});
