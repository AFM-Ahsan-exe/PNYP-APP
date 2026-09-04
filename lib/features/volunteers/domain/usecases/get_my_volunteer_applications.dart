import '../../domain/entities/volunteer.dart' as app_volunteer;
import '../../domain/repositories/volunteer_repository.dart';

class GetMyVolunteerApplications {
  final VolunteerRepository repository;
  GetMyVolunteerApplications(this.repository);

  Future<List<app_volunteer.Volunteer>> call(String userId) =>
      repository.getMyApplications(userId);
}
