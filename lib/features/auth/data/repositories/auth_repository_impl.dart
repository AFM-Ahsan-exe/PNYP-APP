import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  const AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<AppUser> signIn({required String email, required String password}) {
    return remoteDataSource.signIn(email: email, password: password);
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
    required String organizationId,
  }) {
    return remoteDataSource.signUp(
      email: email,
      password: password,
      name: name,
      organizationId: organizationId,
    );
  }

  @override
  Future<void> signOut() {
    return remoteDataSource.signOut();
  }

  @override
  AppUser? getCurrentUser() {
    return remoteDataSource.getCurrentUser();
  }

  @override
  Future<AppUser?> getCurrentUserWithRole() {
    return remoteDataSource.getCurrentUserWithRole();
  }

  @override
  Future<void> sendEmailVerification() {
    return remoteDataSource.sendEmailVerification();
  }

  @override
  Future<void> reloadCurrentUser() {
    return remoteDataSource.reloadCurrentUser();
  }
}
