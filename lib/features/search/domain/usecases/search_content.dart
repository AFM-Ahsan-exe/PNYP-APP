import '../../domain/repositories/search_repository.dart';
import '../../domain/entities/search_result.dart';

class SearchContent {
  final SearchRepository repository;
  SearchContent(this.repository);

  Future<List<SearchResult>> call(
    String query, {
    String? cursor,
    int limit = 20,
  }) {
    return repository.search(query, cursor: cursor, limit: limit);
  }
}
