import '../../domain/entities/news_article.dart' as app_news;
import '../../domain/repositories/news_repository.dart';

class CreateNewsArticle {
  final NewsRepository repository;

  CreateNewsArticle(this.repository);

  Future<app_news.NewsArticle> call(Map<String, dynamic> data) {
    return repository.createNews(data);
  }
}
