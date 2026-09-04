import '../entities/event.dart';
import '../../domain/repositories/event_repository.dart';

class GetEventDetail {
  final EventRepository repository;
  GetEventDetail(this.repository);

  Future<Event?> call(String eventId) => repository.getEventById(eventId);
}
