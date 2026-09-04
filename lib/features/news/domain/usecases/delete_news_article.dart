import '../../domain/repositories/news_repository.dart';

class DeleteNewsArticle {
  final NewsRepository repository;

  DeleteNewsArticle(this.repository);

  Future<void> call(String newsId) {
    return repository.deleteNews(newsId);
  }
}
