import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../../core/services/onboarding_cache.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_colors.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  bool _isCompleting = false;

  static const _steps = [
    _OnboardingStepData(
      title: 'Welcome to PYNP',
      description:
          'Your platform for youth empowerment, events, and community engagement.',
      icon: Icons.volunteer_activism_rounded,
      color: AppColors.navyDeep,
    ),
    _OnboardingStepData(
      title: 'Stay Updated',
      description:
          'Get the latest news, event announcements, and important updates.',
      icon: Icons.notifications_active_rounded,
      color: AppColors.accentBlue,
    ),
    _OnboardingStepData(
      title: 'Get Involved',
      description:
          'Register for events, apply for volunteer opportunities, and grow with us.',
      icon: Icons.people_rounded,
      color: AppColors.success,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final data = _steps[_step];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: data.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(data.icon, size: 80, color: data.color),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      data.title,
                      style: AppTextStyles.headline.copyWith(
                        fontWeight: FontWeight.w800,
                        color: data.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      data.description,
                      style: AppTextStyles.body.copyWith(fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(_steps.length, (index) {
                  final isActive = index == _step;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isActive ? data.color : AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isCompleting ? null : () => _handleNext(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: data.color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isCompleting && _step == _steps.length - 1
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _step == _steps.length - 1 ? 'Get Started' : 'Continue',
                        ),
                ),
              ),
              if (_step < _steps.length - 1)
                TextButton(
                  onPressed: _isCompleting ? null : () => _skip(context),
                  child: const Text('Skip'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNext(BuildContext context) async {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
    } else {
      await _completeOnboarding(context);
    }
  }

  void _skip(BuildContext context) async {
    await _completeOnboarding(context);
  }

  // _handleNext's final step and _skip both used to independently run
  // the same Firestore write with no try/catch and no loading feedback -
  // on a slow or dropped connection, the write's exception propagated
  // out of an async void handler uncaught, and the user was stuck on
  // this screen with no way to proceed (and no visual indication
  // anything was happening while they waited). Onboarding completion is
  // a "don't show this again" flag, not something that should ever
  // block access to the app, so this now always advances - the local
  // cache write always happens, and a failed remote sync is logged but
  // not fatal (AuthController will still see the local flag next
  // launch; the Firestore field can catch up on a later profile update).
  Future<void> _completeOnboarding(BuildContext context) async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'onboardingCompleted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Failed to sync onboardingCompleted to Firestore: $e');
      }
    }
    try {
      await OnboardingCache.setOnboardingCompleted(true);
    } catch (e) {
      debugPrint('Failed to persist onboarding cache locally: $e');
    }

    if (!context.mounted) return;
    final authController = ref.read(authControllerProvider.notifier);
    final currentUser = ref.read(authControllerProvider).user;
    if (currentUser != null) {
      authController.updateUser(
        currentUser.copyWith(onboardingCompleted: true),
      );
    }
    final authState = ref.read(authControllerProvider);
    final target = authState.user?.isAdmin == true ? '/admin' : '/home';
    context.go(target);
  }
}

class _OnboardingStepData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _OnboardingStepData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
