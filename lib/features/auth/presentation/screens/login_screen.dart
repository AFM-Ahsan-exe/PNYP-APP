import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/validators/registration_validators.dart';
import '../../domain/entities/app_user.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _setError(String? message) {
    setState(() {
      _errorMessage = message;
    });
  }

  Future<void> _submit() async {
    debugPrint('[LOGIN] Sign-in button pressed');
    if (!_formKey.currentState!.validate()) {
      debugPrint('[LOGIN] Form validation failed');
      return;
    }

    FocusScope.of(context).unfocus();
    _setError(null);

    final authController = ref.read(authControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    debugPrint('[LOGIN] Calling signIn with email: $email');

    try {
      final success = await authController.signIn(
        email: email,
        password: password,
      );

      debugPrint('[LOGIN] signIn returned: $success');

      if (!mounted) return;

      if (success) {
        final authState = ref.read(authControllerProvider);
        final user = authState.user;
        debugPrint('[LOGIN] Post-sign-in user: ${user?.uid}, role: ${user?.roleName}, status: ${user?.status}, isAdmin: ${user?.isAdmin}');

        if (user == null) {
          debugPrint('[LOGIN] User is null after successful sign-in');
          return;
        }
        if (user.onboardingCompleted == false) {
          debugPrint('[LOGIN] Redirecting to onboarding');
          context.go('/onboarding');
          return;
        }
        if (!user.emailVerified) {
          debugPrint('[LOGIN] Redirecting to email verification');
          context.go('/email-verification');
          return;
        }
        if (user.status != AccountStatus.approved) {
          debugPrint('[LOGIN] Redirecting to account status: ${user.status.name}');
          context.go('/account/${user.status.name}');
        } else {
          final route = user.isAdmin ? '/admin' : '/home';
          debugPrint('[LOGIN] Redirecting to: $route');
          context.go(route);
        }
      } else {
        final authState = ref.read(authControllerProvider);
        final error = authState.error;
        debugPrint('[LOGIN] Sign-in failed with error: $error');
        if (error != null) {
          _setError(error);
        }
      }
    } catch (e) {
      debugPrint('[LOGIN] Unexpected exception: $e');
      if (!mounted) return;
      final message = e.toString();
      _setError(message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.business,
                              size: 50,
                              color: Color(0xFF1A1A2E),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'P N Y P',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome Back!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            'Sign in to your PYNP account.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Semantics(
                            textField: true,
                            label: 'Email',
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) {
                                FocusScope.of(
                                  context,
                                ).requestFocus(_passwordFocusNode);
                              },
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'you@example.com',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: RegistrationValidators.email,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Semantics(
                            textField: true,
                            label: 'Password',
                            child: TextFormField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: RegistrationValidators.password,
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
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
                                      style: const TextStyle(
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton.icon(
                              onPressed: authState.isLoading ? null : _submit,
                              icon: authState.isLoading
                                  ? const SizedBox.shrink()
                                  : const Icon(Icons.login_rounded),
                              label: authState.isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                   : const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => context.push('/password-reset'),
                            icon: const Icon(Icons.lock_reset_outlined),
                            label: const Text('Forgot password?'),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                                onPressed: authState.isLoading
                                    ? null
                                    : () => context.push('/register'),
                                icon: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                ),
                                label: const Text(
                                  'Register as a new member',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                 ),
                               ),
                             ),
                          const SizedBox(height: 8),
                          Text(
                            'Administrator access is verified securely and cannot be selected during signup.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
