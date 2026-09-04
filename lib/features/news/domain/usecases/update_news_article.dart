import '../../domain/entities/news_article.dart' as app_news;
import '../../domain/repositories/news_repository.dart';

class UpdateNewsArticle {
  final NewsRepository repository;

  UpdateNewsArticle(this.repository);

  Future<app_news.NewsArticle> call(String newsId, Map<String, dynamic> data) {
    return repository.updateNews(newsId, data);
  }
}
