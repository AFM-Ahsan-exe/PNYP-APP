import '../../domain/repositories/event_repository.dart';

class CreateEvent {
  final EventRepository repository;
  CreateEvent(this.repository);

  Future<String> call(Map<String, dynamic> eventData) =>
      repository.createEvent(eventData);
}
