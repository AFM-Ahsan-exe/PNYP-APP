import '../repositories/auth_repository.dart';

class SendVerificationEmail {
  final AuthRepository repository;

  const SendVerificationEmail(this.repository);

  Future<void> call() {
    return repository.sendEmailVerification();
  }
}
