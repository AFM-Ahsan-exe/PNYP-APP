import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/app_user.dart';
import '../providers/auth_providers.dart';
import '../../../../app/theme/app_colors.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _isSending = false;
  bool _isChecking = false;
  String? _errorMessage;
  String? _successMessage;

  Future<void> _sendVerification() async {
    final authController = ref.read(authControllerProvider.notifier);
    setState(() {
      _isSending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    await authController.sendVerificationEmail();
    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    setState(() {
      _isSending = false;
      _errorMessage = authState.error;
      _successMessage = authState.verificationEmailSent
          ? 'Verification email sent. Check your inbox.'
          : null;
    });
  }

  Future<void> _recheckStatus() async {
    final authController = ref.read(authControllerProvider.notifier);
    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final isVerified = await authController.recheckEmailVerification();
    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    setState(() {
      _isChecking = false;
      _errorMessage = authState.error;
    });

    if (isVerified) {
      final user = authState.user;
      debugPrint('[EMAIL_VERIFY] Verified user: ${user?.uid}, status: ${user?.status}, isAdmin: ${user?.isAdmin}');
      if (user == null) return;
      if (user.status != AccountStatus.approved) {
        context.go('/account/${user.status.name}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified successfully!')),
        );
        context.go(user.isAdmin ? '/admin' : '/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final isLoading = _isSending || _isChecking;

    return Scaffold(
      appBar: AppBar(title: const Text('Email verification')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 56,
                    color: AppColors.navyDarkest,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Verify your email',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'A verification link was sent to ${user?.email ?? 'your email'}. '
                  'Please check your inbox and click the link to verify your email address.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_successMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: const TextStyle(color: AppColors.success),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                FilledButton.icon(
                  onPressed: isLoading ? null : _sendVerification,
                  icon: _isSending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: const Text('Resend verification email'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navyDarkest,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.navyDarkest.withValues(
                      alpha: 0.65,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isLoading ? null : _recheckStatus,
                  icon: _isChecking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: const Text('I have verified - check status'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navyDarkest,
                    side: const BorderSide(color: AppColors.navyDarkest),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).signOut();
                    if (context.mounted) context.go('/login');
                  },
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
