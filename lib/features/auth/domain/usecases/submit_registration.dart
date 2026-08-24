import '../../domain/entities/app_user.dart';
import '../../domain/repositories/registration_repository.dart';

class SubmitRegistration {
  final RegistrationRepository repository;

  const SubmitRegistration(this.repository);

  Future<AppUser> call({required Map<String, dynamic> data}) {
    return repository.submitRegistration(data: data);
  }
}
