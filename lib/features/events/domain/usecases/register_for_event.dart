import '../../domain/repositories/event_repository.dart';

class RegisterForEvent {
  final EventRepository repository;
  RegisterForEvent(this.repository);

  Future<void> call(String eventId) => repository.registerForEvent(eventId);
}
