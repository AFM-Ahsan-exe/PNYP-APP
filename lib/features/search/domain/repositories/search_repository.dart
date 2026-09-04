import '../entities/search_result.dart';

abstract class SearchRepository {
  Future<List<SearchResult>> search(
    String query, {
    String? cursor,
    int limit = 20,
  });
}
