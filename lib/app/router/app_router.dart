import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/screens/home_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/registration_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/account_status_screen.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard_screen.dart';

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
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
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
    ],
  );
});
