import '../../domain/entities/volunteer.dart' as app_volunteer;
import '../../domain/repositories/volunteer_repository.dart';

class GetAllVolunteerApplications {
  final VolunteerRepository repository;
  GetAllVolunteerApplications(this.repository);

  Future<List<app_volunteer.Volunteer>> call({
    String? status,
    String? opportunityId,
  }) => repository.getAllApplications(
    status: status,
    opportunityId: opportunityId,
  );
}
