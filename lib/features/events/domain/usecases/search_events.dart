import '../entities/event.dart';
import '../../domain/repositories/event_repository.dart';

class SearchEvents {
  final EventRepository repository;
  SearchEvents(this.repository);

  Future<List<Event>> call(String query) => repository.searchEvents(query);
}
