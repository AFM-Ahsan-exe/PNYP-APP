import '../../domain/repositories/news_repository.dart';
import '../entities/news_article.dart';

class GetNewsDetail {
  final NewsRepository repository;
  GetNewsDetail(this.repository);

  Future<NewsArticle?> call(String newsId) => repository.getNewsById(newsId);
}
