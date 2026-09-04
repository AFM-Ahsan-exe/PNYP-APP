import 'package:cloud_firestore/cloud_firestore.dart';

class NewsArticle {
  final String id;
  final String title;
  final String? summary;
  final String? content;
  final String? coverImageUrl;
  final String? category;
  final Timestamp? publishedAt;
  final String? authorId;
  final String? authorName;
  final List<String>? tags;
  final List<String>? targetAudience;
  final bool? isPublished;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const NewsArticle({
    required this.id,
    required this.title,
    this.summary,
    this.content,
    this.coverImageUrl,
    this.category,
    this.publishedAt,
    this.authorId,
    this.authorName,
    this.tags,
    this.targetAudience,
    this.isPublished,
    this.createdAt,
    this.updatedAt,
  });

  factory NewsArticle.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return NewsArticle(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled',
      summary: data['summary'] as String?,
      content: data['content'] as String?,
      coverImageUrl: data['coverImageUrl'] as String?,
      category: data['category'] as String?,
      publishedAt: data['publishedAt'] as Timestamp?,
      authorId: data['authorId'] as String?,
      authorName: data['authorName'] as String?,
      tags: (data['tags'] as List<dynamic>?)?.cast<String>(),
      targetAudience: (data['targetAudience'] as List<dynamic>?)
          ?.cast<String>(),
      isPublished: data['isPublished'] as bool?,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }
}
