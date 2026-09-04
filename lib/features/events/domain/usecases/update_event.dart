import '../../domain/repositories/event_repository.dart';

class UpdateEvent {
  final EventRepository repository;
  UpdateEvent(this.repository);

  Future<void> call(String eventId, Map<String, dynamic> eventData) =>
      repository.updateEvent(eventId, eventData);
}
