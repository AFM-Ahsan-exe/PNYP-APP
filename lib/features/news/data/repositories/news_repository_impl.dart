import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/network/cloud_functions_client.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/repositories/news_repository.dart';

class NewsRepositoryImpl implements NewsRepository {
  final FirebaseFirestore _firestore;
  final int _limit;

  NewsRepositoryImpl(this._firestore, {int limit = 50}) : _limit = limit;

  Future<Map<String, dynamic>?> _callFunction(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated user');
    final idToken = await user.getIdToken();
    final client = CloudFunctionsClient(
      projectId: Firebase.app().options.projectId,
      region: 'us-central1',
    );
    return client.call(functionName, data, idToken);
  }

  @override
  Future<List<NewsArticle>> getNews({int limit = 50}) async {
        final effectiveLimit = limit < _limit ? limit : _limit;

    final snapshot = await _firestore
        .collection('news')
        .where('isPublished', isEqualTo: true)
        .orderBy('publishedAt', descending: true)
        .limit(effectiveLimit)
        .get();
    return snapshot.docs.map(NewsArticle.fromFirestore).toList();
  }

  @override
  Stream<List<NewsArticle>> watchNews() {
    return _firestore
        .collection('news')
        .where('isPublished', isEqualTo: true)
        .orderBy('publishedAt', descending: true)
        .limit(_limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(NewsArticle.fromFirestore).toList());
  }

  @override
  Future<NewsArticle?> getNewsById(String newsId) async {
    final doc = await _firestore.collection('news').doc(newsId).get();
    if (!doc.exists) return null;
    return NewsArticle.fromFirestore(doc);
  }

  @override
  Future<List<NewsArticle>> searchNews(String query) async {
    final lower = query.toLowerCase();
    final snapshot = await _firestore
        .collection('news')
        .orderBy('publishedAt', descending: true)
        .limit(_limit)
        .get();
    final results = <NewsArticle>[];
    for (final doc in snapshot.docs) {
      final article = NewsArticle.fromFirestore(doc);
      if (article.title.toLowerCase().contains(lower) ||
          (article.summary?.toLowerCase().contains(lower) ?? false) ||
          (article.category?.toLowerCase().contains(lower) ?? false)) {
        results.add(article);
      }
    }
    return results;
  }

  @override
  Future<NewsArticle> createNews(Map<String, dynamic> data) async {
    final result = await _callFunction('createNewsArticle', data);
    final articleId = result?['articleId'] as String?;
    if (articleId == null) throw StateError('Failed to create article');
    final doc = await _firestore.collection('news').doc(articleId).get();
    if (!doc.exists) throw StateError('Failed to load created article');
    return NewsArticle.fromFirestore(doc);
  }

  @override
  Future<NewsArticle> updateNews(
    String newsId,
    Map<String, dynamic> data,
  ) async {
    await _callFunction('updateNewsArticle', {...data, 'articleId': newsId});
    final doc = await _firestore.collection('news').doc(newsId).get();
    if (!doc.exists) throw StateError('Failed to load updated article');
    return NewsArticle.fromFirestore(doc);
  }

  @override
  Future<void> deleteNews(String newsId) async {
    await _callFunction('deleteNewsArticle', {'articleId': newsId});
  }
}