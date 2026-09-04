import '../../domain/repositories/news_repository.dart';
import '../entities/news_article.dart';

class SearchNews {
  final NewsRepository repository;
  SearchNews(this.repository);

  Future<List<NewsArticle>> call(String query) => repository.searchNews(query);
}
