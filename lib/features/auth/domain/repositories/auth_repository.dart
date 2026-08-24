import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
    required String organizationId,
  });

  Future<void> signOut();

  AppUser? getCurrentUser();

  Future<AppUser?> getCurrentUserWithRole();
}
