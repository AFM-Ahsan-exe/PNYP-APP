import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUser {
  final AuthRepository repository;

  const GetCurrentUser(this.repository);

  AppUser? call() {
    return repository.getCurrentUser();
  }

  Future<AppUser?> withRole() {
    return repository.getCurrentUserWithRole();
  }
}