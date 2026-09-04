import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/registration_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/account_status_screen.dart';
import '../../features/auth/presentation/screens/password_reset_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/admin_members_screen.dart';
import '../../features/dashboard/presentation/screens/admin_volunteers_screen.dart';
import '../../features/dashboard/presentation/screens/admin_applications_screen.dart';
import '../../features/dashboard/presentation/screens/admin_renewals_screen.dart';
import '../../features/dashboard/presentation/screens/admin_notifications_screen.dart';
import '../../features/dashboard/presentation/screens/member_home_screen.dart';
import '../../features/dashboard/presentation/screens/profile_screen.dart';
import '../../features/dashboard/presentation/screens/edit_profile_screen.dart';
import '../../features/dashboard/presentation/screens/renew_membership_screen.dart';
import '../../features/dashboard/presentation/screens/notifications_screen.dart';
import '../../features/events/presentation/screens/events_list_screen.dart';
import '../../features/events/presentation/screens/event_detail_screen.dart';
import '../../features/events/presentation/screens/event_form_screen.dart';
import '../../features/events/presentation/screens/event_attendance_screen.dart';
import '../../features/news/presentation/screens/news_list_screen.dart';
import '../../features/news/presentation/screens/news_detail_screen.dart';
import '../../features/news/presentation/screens/news_form_screen.dart';
import '../../features/news/presentation/screens/admin_news_screen.dart';
import '../../features/documents/presentation/screens/documents_list_screen.dart';
import '../../features/documents/presentation/screens/document_detail_screen.dart';
import '../../features/documents/presentation/screens/document_form_screen.dart';
import '../../features/documents/presentation/screens/admin_documents_screen.dart';
import '../../features/gallery/presentation/screens/gallery_screen.dart';
import '../../features/gallery/presentation/screens/album_detail_screen.dart';
import '../../features/gallery/presentation/screens/album_form_screen.dart';
import '../../features/gallery/presentation/screens/media_upload_screen.dart';
import '../../features/gallery/presentation/screens/admin_gallery_screen.dart';
import '../../features/opportunities/presentation/screens/opportunities_list_screen.dart';
import '../../features/opportunities/presentation/screens/opportunity_detail_screen.dart';
import '../../features/opportunities/presentation/screens/opportunity_form_screen.dart';
import '../../features/opportunities/presentation/screens/admin_opportunities_screen.dart';
import '../../features/volunteers/presentation/screens/volunteer_applications_screen.dart';
import '../../features/analytics/presentation/screens/analytics_dashboard_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/reports/presentation/screens/reports_history_screen.dart';
import '../../features/profile/presentation/screens/member_directory_screen.dart';
import '../../features/notifications/presentation/screens/notification_detail_screen.dart';
import '../../features/roles/presentation/screens/role_management_screen.dart';
import '../../features/audit/presentation/screens/audit_log_screen.dart';
import '../../features/settings/presentation/screens/system_settings_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/settings/presentation/screens/notification_preferences_screen.dart';
import '../../features/activity/presentation/screens/user_activity_screen.dart';
import '../../features/admin/presentation/screens/admin_bulk_actions_screen.dart';

// GoRouter must not be recreated every time auth state changes: the old
// code did `final authState = ref.watch(authControllerProvider);` inside
// this Provider, which rebuilds the *entire* GoRouter (new navigator keys,
// lost navigation stack, mid-navigation cancellation) on every single auth
// state change - and AuthState changes multiple times per session (initial
// build, async role load, sign-in, sign-out, profile updates). This was a
// likely root cause of navigation glitches and the splash/admin dashboard
// appearing to "reset". Instead, GoRouter is built once and given a
// `refreshListenable` that just pings it to re-run `redirect` - the router
// instance itself is stable.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      notifyListeners();
    });
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _AuthRefreshListenable(ref);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      // Read (not watch) - `redirect` is re-run by refreshListenable
      // whenever auth state changes, so this always sees fresh state
      // without forcing the GoRouter object itself to be rebuilt.
      final authState = ref.read(authControllerProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isOnSplash = state.matchedLocation == '/splash';
      final isOnLogin = state.matchedLocation == '/login';
      final isOnRegister = state.matchedLocation == '/register';
      final isOnPasswordReset = state.matchedLocation == '/password-reset';
      final isOnEmailVerification = state.matchedLocation == '/email-verification';
      final isOnOnboarding = state.matchedLocation == '/onboarding';
      final isOnAccountStatus = state.matchedLocation.startsWith('/account/');
      final isOnRenewMembership = state.matchedLocation == '/renew-membership';
      final isOnAdmin = state.matchedLocation == '/admin';

      final user = authState.user;
      final isAdmin = user?.isAdmin ?? false;
      final status = user?.status;
      final onboardingCompleted = user?.onboardingCompleted ?? false;

      if (isOnSplash) return null;

      if (authState.isLoading) return null;

      if (!isLoggedIn) {
        if (isOnLogin ||
            isOnRegister ||
            isOnPasswordReset ||
            isOnOnboarding) {
          return null;
        }
        return '/login';
      }

      // Email verification and onboarding used to be two independent
      // checks, each redirecting to its own page whenever the user sat
      // on the OTHER page - since a brand-new user typically has BOTH
      // onboardingCompleted=false AND emailVerified=false at once, they
      // fought forever: /onboarding saw an unverified email and sent the
      // user to /email-verification, which still saw onboarding
      // incomplete and sent them right back - the exact
      // /onboarding -> /email-verification -> /onboarding loop. Making
      // these sequential stages (verify email, THEN onboard) rather than
      // two parallel gates removes the possibility of a loop entirely.
      if (!user!.emailVerified) {
        if (!isOnEmailVerification) return '/email-verification';
        return null;
      }

      if (!onboardingCompleted) {
        if (!isOnOnboarding) return '/onboarding';
        return null;
      }

      if (isOnOnboarding || isOnEmailVerification) {
        return isAdmin ? '/admin' : '/home';
      }

      if (status != AccountStatus.approved) {
        if (isOnAccountStatus || isOnEmailVerification) return null;
        if (status == AccountStatus.expired) {
          return '/renew-membership';
        }
        return '/account/${status?.name ?? AccountStatus.pending.name}';
      }

            if (isOnLogin ||
          isOnRegister ||
          isOnPasswordReset ||
          isOnOnboarding ||
          isOnEmailVerification ||
          isOnAccountStatus) {
        return isAdmin ? '/admin' : '/home';
      }

      if (isOnAdmin && !isAdmin) {
        return '/home';
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
      GoRoute(
        path: '/email-verification',
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MemberHomeScreen(),
      ),
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
        path: '/members',
        builder: (context, state) => const MemberDirectoryScreen(),
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
        path: '/notifications/:notificationId',
        builder: (context, state) => NotificationDetailScreen(
          notificationId: state.pathParameters['notificationId']!,
        ),
      ),
      GoRoute(
        path: '/events',
        builder: (context, state) => const EventsListScreen(),
      ),
      GoRoute(
        path: '/events/new',
        builder: (context, state) => const EventFormScreen(),
      ),
      GoRoute(
        path: '/events/:eventId/edit',
        builder: (context, state) =>
            EventFormScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: '/events/:eventId/attendance',
        builder: (context, state) =>
            EventAttendanceScreen(eventId: state.pathParameters['eventId']!),
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
        path: '/news/new',
        builder: (context, state) => const NewsFormScreen(),
      ),
      GoRoute(
        path: '/news/:articleId',
        builder: (context, state) {
          final articleId = state.pathParameters['articleId']!;
          return NewsDetailScreen(articleId: articleId);
        },
      ),
      GoRoute(
        path: '/news/:articleId/edit',
        builder: (context, state) {
          final articleId = state.pathParameters['articleId']!;
          return NewsFormScreen(articleId: articleId);
        },
      ),
      GoRoute(
        path: '/admin/gallery',
        builder: (context, state) => const AdminGalleryScreen(),
      ),
      GoRoute(
        path: '/admin/news',
        builder: (context, state) => const AdminNewsScreen(),
      ),
      GoRoute(
        path: '/admin/documents',
        builder: (context, state) => const AdminDocumentsScreen(),
      ),
      GoRoute(
        path: '/documents',
        builder: (context, state) => const DocumentsListScreen(),
      ),
      GoRoute(
        path: '/documents/upload',
        builder: (context, state) => const DocumentFormScreen(),
      ),
      GoRoute(
        path: '/documents/:documentId',
        builder: (context, state) {
          final documentId = state.pathParameters['documentId']!;
          return DocumentDetailScreen(documentId: documentId);
        },
      ),
      GoRoute(
        path: '/documents/:documentId/edit',
        builder: (context, state) {
          final documentId = state.pathParameters['documentId']!;
          return DocumentFormScreen(documentId: documentId);
        },
      ),
      GoRoute(
        path: '/gallery',
        builder: (context, state) => const GalleryScreen(),
      ),
      GoRoute(
        path: '/gallery/new',
        builder: (context, state) => const AlbumFormScreen(),
      ),
      GoRoute(
        path: '/gallery/:albumId',
        builder: (context, state) {
          final albumId = state.pathParameters['albumId']!;
          return AlbumDetailScreen(albumId: albumId);
        },
      ),
      GoRoute(
        path: '/gallery/:albumId/edit',
        builder: (context, state) {
          final albumId = state.pathParameters['albumId']!;
          return AlbumFormScreen(albumId: albumId);
        },
      ),
      GoRoute(
        path: '/gallery/:albumId/upload',
        builder: (context, state) {
          final albumId = state.pathParameters['albumId']!;
          return MediaUploadScreen(albumId: albumId);
        },
      ),
      GoRoute(
        path: '/opportunities',
        builder: (context, state) => const OpportunitiesListScreen(),
      ),
      GoRoute(
        path: '/opportunities/new',
        builder: (context, state) => const OpportunityFormScreen(),
      ),
      GoRoute(
        path: '/opportunities/:opportunityId',
        builder: (context, state) {
          final opportunityId = state.pathParameters['opportunityId']!;
          return OpportunityDetailScreen(opportunityId: opportunityId);
        },
      ),
      GoRoute(
        path: '/opportunities/:opportunityId/edit',
        builder: (context, state) {
          final opportunityId = state.pathParameters['opportunityId']!;
          return OpportunityFormScreen(opportunityId: opportunityId);
        },
      ),
      GoRoute(
        path: '/admin/opportunities',
        builder: (context, state) => const AdminOpportunitiesScreen(),
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
        path: '/reports/history',
        builder: (context, state) => const ReportsHistoryScreen(),
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
        path: '/admin/members',
        builder: (context, state) => const AdminMembersScreen(),
      ),
      GoRoute(
        path: '/admin/volunteers',
        builder: (context, state) => const AdminVolunteersScreen(),
      ),
      GoRoute(
        path: '/admin/applications',
        builder: (context, state) => const AdminApplicationsScreen(),
      ),
      GoRoute(
        path: '/admin/renewals',
        builder: (context, state) => const AdminRenewalsScreen(),
      ),
      GoRoute(
        path: '/admin/notifications',
        builder: (context, state) => const AdminNotificationsScreen(),
      ),
      GoRoute(
        path: '/admin/bulk-actions',
        builder: (context, state) => const AdminBulkActionsScreen(),
      ),
    ],
  );
});
