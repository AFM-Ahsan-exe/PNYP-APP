import '../../domain/entities/volunteer.dart' as app_volunteer;
import '../../domain/repositories/volunteer_repository.dart';

class ApplyAsVolunteer {
  final VolunteerRepository repository;
  ApplyAsVolunteer(this.repository);

  Future<app_volunteer.Volunteer> call({
    required String opportunityId,
    required String motivation,
    required String availability,
    required List<String> skills,
  }) => repository.applyAsVolunteer(
    opportunityId: opportunityId,
    motivation: motivation,
    availability: availability,
    skills: skills,
  );
}
