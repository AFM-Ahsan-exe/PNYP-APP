import '../../domain/repositories/event_repository.dart';

class GetRegistrationStatus {
  final EventRepository repository;
  GetRegistrationStatus(this.repository);

  Future<Map<String, dynamic>?> call(String eventId) =>
      repository.getRegistrationStatus(eventId);
}
