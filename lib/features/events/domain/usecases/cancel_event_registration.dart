import '../../domain/repositories/event_repository.dart';

class CancelEventRegistration {
  final EventRepository repository;
  CancelEventRegistration(this.repository);

  Future<void> call(String eventId) =>
      repository.cancelEventRegistration(eventId);
}
