import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignUp {
  final AuthRepository repository;

  const SignUp(this.repository);

  Future<AppUser> call({
    required String email,
    required String password,
    required String name,
    required String organizationId,
  }) {
    return repository.signUp(
      email: email,
      password: password,
      name: name,
      organizationId: organizationId,
    );
  }
}
