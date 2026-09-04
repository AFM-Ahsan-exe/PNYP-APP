import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';
import '../../domain/usecases/send_verification_email.dart';
import '../../domain/usecases/reload_user.dart';
import '../controllers/auth_controller.dart';

// Firebase Auth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// DataSource
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    ref.watch(firebaseAuthProvider),
    FirebaseFirestore.instance,
  );
});

// Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

// Use Cases
final signInUseCaseProvider = Provider<SignIn>((ref) {
  return SignIn(ref.watch(authRepositoryProvider));
});

final signUpUseCaseProvider = Provider<SignUp>((ref) {
  return SignUp(ref.watch(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOut>((ref) {
  return SignOut(ref.watch(authRepositoryProvider));
});

final getCurrentUserUseCaseProvider = Provider<GetCurrentUser>((ref) {
  return GetCurrentUser(ref.watch(authRepositoryProvider));
});

final sendVerificationEmailUseCaseProvider = Provider<SendVerificationEmail>((
  ref,
) {
  return SendVerificationEmail(ref.watch(authRepositoryProvider));
});

final reloadUserUseCaseProvider = Provider<ReloadUser>((ref) {
  return ReloadUser(ref.watch(authRepositoryProvider));
});

// AuthController (Notifier)
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

// Current user stream
final authStateChangesProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges().asyncMap((
    firebaseUser,
  ) async {
    if (firebaseUser == null) return null;
    try {
      return await ref
              .watch(authRemoteDataSourceProvider)
              .getCurrentUserWithRole() ??
          ref.watch(authRemoteDataSourceProvider).getCurrentUser();
    } catch (e) {
      return AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email,
        displayName: firebaseUser.displayName,
        emailVerified: firebaseUser.emailVerified,
        onboardingCompleted: null,
      );
    }
  });
});
