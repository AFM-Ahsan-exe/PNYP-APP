import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';
import '../providers/auth_providers.dart';

class AuthState {
  static const _unset = Object();

  final AppUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({
    Object? user = _unset,
    bool? isLoading,
    Object? error = _unset,
  }) {
    return AuthState(
      user: identical(user, _unset) ? this.user : user as AppUser?,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }

  bool get isAuthenticated => user != null;
}

class AuthController extends Notifier<AuthState> {
  SignIn get _signIn => ref.read(signInUseCaseProvider);
  SignUp get _signUp => ref.read(signUpUseCaseProvider);
  SignOut get _signOut => ref.read(signOutUseCaseProvider);
  GetCurrentUser get _getCurrentUser => ref.read(getCurrentUserUseCaseProvider);

  @override
  AuthState build() {
    final currentUser = _getCurrentUser();
    if (currentUser != null) {
      unawaited(_loadCurrentUserRole(currentUser.uid));
      unawaited(_registerFcmToken());
    }
    return AuthState(user: currentUser);
  }

  Future<void> _loadCurrentUserRole(String uid) async {
    final user = await _getCurrentUser.withRole();
    if (user != null && state.user?.uid == uid) {
      state = state.copyWith(user: user);
    }
  }

  Future<void> _registerFcmToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Non-blocking: FCM registration failure should not prevent login
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _signIn(email: email, password: password);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _signOut();
      state = state.copyWith(user: null, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
