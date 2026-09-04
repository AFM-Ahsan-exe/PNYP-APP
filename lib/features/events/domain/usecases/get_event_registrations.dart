import '../../domain/repositories/event_repository.dart';

class GetEventRegistrations {
  final EventRepository repository;
  GetEventRegistrations(this.repository);

  Future<List<EventRegistration>> call(String eventId) =>
      repository.getEventRegistrations(eventId);
}
