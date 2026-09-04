import '../../domain/entities/volunteer.dart' as app_volunteer;
import '../../domain/repositories/volunteer_repository.dart';

class UpdateVolunteerStatus {
  final VolunteerRepository repository;
  UpdateVolunteerStatus(this.repository);

  Future<app_volunteer.Volunteer> call({
    required String applicationId,
    required String status,
    String? reviewNotes,
  }) => repository.updateVolunteerStatus(
    applicationId: applicationId,
    status: status,
    reviewNotes: reviewNotes,
  );
}
