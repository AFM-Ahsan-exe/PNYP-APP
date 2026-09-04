import '../../domain/repositories/news_repository.dart';
import '../entities/news_article.dart';

class GetNews {
  final NewsRepository repository;
  GetNews(this.repository);

  Future<List<NewsArticle>> call({int limit = 50}) =>
      repository.getNews(limit: limit);
}
