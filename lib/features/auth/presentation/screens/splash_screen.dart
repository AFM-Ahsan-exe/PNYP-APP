import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/app_user.dart';
import '../providers/auth_providers.dart';
import '../../../../core/services/onboarding_cache.dart';
import '../controllers/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hasNavigated || !mounted) return;
      _checkAuthAndNavigate();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkAuthAndNavigate() {
    if (_hasNavigated || !mounted) return;

    final authState = ref.read(authControllerProvider);
    if (!authState.isLoading) {
      _navigate(authState);
    }
    // If still loading, do nothing here - the listener registered in
    // build() will call _navigate() once loading finishes.
  }

  Future<void> _navigate(AuthState authState) async {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    if (authState.isAuthenticated) {
      final user = authState.user;
      if (user != null) {
        final cachedOnboarding = await OnboardingCache.isOnboardingCompleted();
        final onboardingCompleted =
            user.onboardingCompleted ?? cachedOnboarding;
        if (!onboardingCompleted) {
          if (mounted) context.go('/onboarding');
          return;
        }
        if (!user.emailVerified) {
          if (mounted) context.go('/email-verification');
          return;
        }
        if (user.status != AccountStatus.approved) {
          if (mounted) context.go('/account/${user.status.name}');
        } else {
          if (mounted) context.go(user.isAdmin ? '/admin' : '/home');
        }
      } else {
        if (mounted) context.go('/login');
      }
    } else {
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // `ref.listen` is only valid inside build(), unlike the previous
    // implementation which called it from a post-frame callback. Registering
    // it here (it's safe/idempotent to call on every build) lets us react
    // to the auth role finishing its async load without the assertion
    // error that used to strand users on this screen.
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (_hasNavigated || !mounted) return;
      if (!next.isLoading) {
        _navigate(next);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo fades in
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.business,
                        size: 80,
                        color: Color(0xFF1A1A2E),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // App name slides up
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: child,
                );
              },
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'P N Y P',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 8,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Tagline
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Mobile Management',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 2,
                ),
              ),
            ),

            const SizedBox(height: 60),

            // Loading bar at bottom
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: 150,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _controller.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
