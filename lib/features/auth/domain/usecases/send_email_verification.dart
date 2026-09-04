import '../../domain/repositories/registration_repository.dart';

class SendEmailVerification {
  final RegistrationRepository repository;

  const SendEmailVerification(this.repository);

  Future<void> call() {
    return repository.sendEmailVerification();
  }
}
