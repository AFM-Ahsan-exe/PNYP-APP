import '../entities/volunteer.dart';

abstract class VolunteerRepository {
  Future<List<Volunteer>> getMyApplications(String userId);
  Future<List<Volunteer>> getAllApplications({
    String? status,
    String? opportunityId,
  });
  Future<Volunteer> applyAsVolunteer({
    required String opportunityId,
    required String motivation,
    required String availability,
    required List<String> skills,
  });
  Future<Volunteer> updateVolunteerStatus({
    required String applicationId,
    required String status,
    String? reviewNotes,
  });
  Future<void> withdrawApplication(String applicationId);
}
