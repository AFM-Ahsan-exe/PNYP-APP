import '../entities/news_article.dart';

abstract class NewsRepository {
  Future<List<NewsArticle>> getNews({int limit = 50});
  Stream<List<NewsArticle>> watchNews();
  Future<NewsArticle?> getNewsById(String newsId);
  Future<List<NewsArticle>> searchNews(String query);
  Future<NewsArticle> createNews(Map<String, dynamic> data);
  Future<NewsArticle> updateNews(String newsId, Map<String, dynamic> data);
  Future<void> deleteNews(String newsId);
}