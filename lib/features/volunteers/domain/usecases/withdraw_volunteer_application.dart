import '../../domain/repositories/volunteer_repository.dart';

class WithdrawVolunteerApplication {
  final VolunteerRepository repository;
  WithdrawVolunteerApplication(this.repository);

  Future<void> call(String applicationId) =>
      repository.withdrawApplication(applicationId);
}
