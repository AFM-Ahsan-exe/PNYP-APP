import '../entities/event.dart';
import '../../domain/repositories/event_repository.dart';

class GetEvents {
  final EventRepository repository;
  GetEvents(this.repository);

  Future<List<Event>> call() => repository.getEvents();
}
