import '../repositories/auth_repository.dart';

class ReloadUser {
  final AuthRepository repository;

  const ReloadUser(this.repository);

  Future<void> call() {
    return repository.reloadCurrentUser();
  }
}
