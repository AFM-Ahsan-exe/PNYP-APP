import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/activity_logger.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';
import '../../domain/usecases/send_verification_email.dart';
import '../../domain/usecases/reload_user.dart';
import '../providers/auth_providers.dart';

class AuthState {
  static const _unset = Object();

  final AppUser? user;
  final bool isLoading;
  final String? error;
  final bool verificationEmailSent;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.verificationEmailSent = false,
  });

  AuthState copyWith({
    Object? user = _unset,
    bool? isLoading,
    Object? error = _unset,
    bool? verificationEmailSent,
  }) {
    return AuthState(
      user: identical(user, _unset) ? this.user : user as AppUser?,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      verificationEmailSent:
          verificationEmailSent ?? this.verificationEmailSent,
    );
  }

  bool get isAuthenticated => user != null;
}

class AuthController extends Notifier<AuthState> {
  SignIn get _signIn => ref.read(signInUseCaseProvider);
  SignUp get _signUp => ref.read(signUpUseCaseProvider);
  SignOut get _signOut => ref.read(signOutUseCaseProvider);
  GetCurrentUser get _getCurrentUser => ref.read(getCurrentUserUseCaseProvider);
  SendVerificationEmail get _sendVerificationEmail =>
      ref.read(sendVerificationEmailUseCaseProvider);
  ReloadUser get _reloadUser => ref.read(reloadUserUseCaseProvider);

  @override
  AuthState build() {
    final currentUser = _getCurrentUser();
    if (currentUser != null) {
      state = AuthState(user: currentUser, isLoading: true);
      unawaited(_loadCurrentUserRole(currentUser.uid));
      unawaited(_registerFcmToken());
      return state;
    }
    return const AuthState();
  }

  Future<void> _loadCurrentUserRole(String uid) async {
    final user = await _getCurrentUser.withRole();
    if (user != null && state.user?.uid == uid) {
      state = state.copyWith(user: user, isLoading: false);
    }
  }

   Future<void> _registerFcmToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'fcmToken': newToken,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('FCM token refresh update failed: $e');
        }
      });
    } catch (e) {
      debugPrint('FCM registration failed: $e');
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    debugPrint('[AUTH_CTRL] signIn started for email: $email');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _signIn(email: email, password: password);
      debugPrint('[AUTH_CTRL] signIn succeeded for uid: ${user.uid}, role: ${user.roleName}, status: ${user.status}');
      state = state.copyWith(user: user, isLoading: false);
      unawaited(
        ActivityLogger.log(
          userId: user.uid,
          action: 'login',
          details: 'Email sign-in',
        ),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AUTH_CTRL] FirebaseAuthException: ${e.code} - ${e.message}');
      state = state.copyWith(
        isLoading: false,
        error: _getFriendlyFirebaseError(e),
      );
      return false;
    } catch (e) {
      debugPrint('[AUTH_CTRL] Unexpected error in signIn: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    String organizationId = 'unassigned',
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _signUp(
        email: email,
        password: password,
        name: name,
        organizationId: organizationId,
      );
      state = state.copyWith(user: user, isLoading: false);
      unawaited(
        ActivityLogger.log(
          userId: user.uid,
          action: 'register',
          details: 'Account created',
        ),
      );
      // NOTE: previously also called ActivityLogger.logAdmin() here to
      // write to the admin-only `activity_logs` collection, but a brand
      // new (non-admin) registrant can never satisfy that Firestore rule,
      // so the write always failed silently. The dashboard "Recent
      // Activity" feed now gets this entry from the `submitRegistration`
      // Cloud Function instead, which runs with admin privileges.
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getFriendlyFirebaseError(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final uid = state.user?.uid;
      try {
        await FirebaseMessaging.instance.deleteToken();
        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'fcmToken': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {
        // Non-blocking: token cleanup failure should not prevent logout
      }
      await _signOut();
      state = state.copyWith(
        user: null,
        isLoading: false,
        verificationEmailSent: false,
      );
      if (uid != null) {
        unawaited(
          ActivityLogger.log(
            userId: uid,
            action: 'logout',
            details: 'User signed out',
          ),
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> sendVerificationEmail() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _sendVerificationEmail();
      state = state.copyWith(isLoading: false, verificationEmailSent: true);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getFriendlyFirebaseError(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send verification email.',
      );
    }
  }

  Future<bool> recheckEmailVerification() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _reloadUser();
      final currentUser = _getCurrentUser();
      final isVerified = currentUser?.emailVerified ?? false;
      if (currentUser != null) {
        // Refresh the role data too since we have a fresh user
        final userWithRole = await _getCurrentUser.withRole();
        state = state.copyWith(
          user: userWithRole ?? currentUser,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
      return isVerified;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _getFriendlyFirebaseError(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to refresh verification status.',
      );
      return false;
    }
  }

  void updateUser(AppUser updatedUser) {
    state = state.copyWith(user: updatedUser);
  }

  String _getFriendlyFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid email or password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }

  void clearError() {
    state = state.copyWith(error: null, verificationEmailSent: false);
  }
}
