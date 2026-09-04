import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/news_repository_impl.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/repositories/news_repository.dart';
import '../../domain/usecases/create_news_article.dart';
import '../../domain/usecases/delete_news_article.dart';
import '../../domain/usecases/get_news.dart';
import '../../domain/usecases/get_news_detail.dart';
import '../../domain/usecases/search_news.dart';
import '../../domain/usecases/update_news_article.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return NewsRepositoryImpl(ref.watch(firestoreProvider));
});

final getNewsProvider = Provider<GetNews>((ref) {
  return GetNews(ref.watch(newsRepositoryProvider));
});

final getNewsDetailProvider = Provider<GetNewsDetail>((ref) {
  return GetNewsDetail(ref.watch(newsRepositoryProvider));
});

final searchNewsProvider = Provider<SearchNews>((ref) {
  return SearchNews(ref.watch(newsRepositoryProvider));
});

final createNewsArticleProvider = Provider<CreateNewsArticle>((ref) {
  return CreateNewsArticle(ref.watch(newsRepositoryProvider));
});

final updateNewsArticleProvider = Provider<UpdateNewsArticle>((ref) {
  return UpdateNewsArticle(ref.watch(newsRepositoryProvider));
});

final deleteNewsArticleProvider = Provider<DeleteNewsArticle>((ref) {
  return DeleteNewsArticle(ref.watch(newsRepositoryProvider));
});

final newsProvider = FutureProvider.autoDispose<List<NewsArticle>>((ref) async {
  return ref.watch(getNewsProvider)();
});

final newsStreamProvider = StreamProvider.autoDispose<List<NewsArticle>>((ref) {
  return ref.watch(newsRepositoryProvider).watchNews();
});

final newsDetailProvider = FutureProvider.autoDispose
    .family<NewsArticle?, String>((ref, newsId) async {
      return ref.watch(getNewsDetailProvider)(newsId);
    });

final newsSearchProvider = FutureProvider.autoDispose
    .family<List<NewsArticle>, String>((ref, query) async {
      return ref.watch(searchNewsProvider)(query);
    });