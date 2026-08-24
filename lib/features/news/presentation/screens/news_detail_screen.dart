import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final newsDetailProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final articleId = ref.watch(_articleIdProvider);
  if (articleId == null) return {};
  final doc = await FirebaseFirestore.instance.collection('news').doc(articleId).get();
  if (!doc.exists) return {};
  return {'id': doc.id, ...doc.data()!};
});

final _articleIdProvider = Provider<String?>((ref) => null);

class NewsDetailScreen extends ConsumerWidget {
  final String articleId;

  const NewsDetailScreen({super.key, required this.articleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articleAsync = ref.watch(newsDetailProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
      ),
      body: articleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
                const SizedBox(height: 24),
                Text(
                  'Could not load article',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(newsDetailProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (article) {
          if (article.isEmpty) {
            return const Center(child: Text('Article not found'));
          }
          final title = article['title'] as String? ?? 'Untitled';
          final content = article['content'] as String? ?? 'No content';
          final authorName = article['authorName'] as String? ?? 'Unknown';
          final publishedAt = article['publishedAt'] is Timestamp
              ? (article['publishedAt'] as Timestamp).toDate()
              : null;
          final coverImageUrl = article['coverImageUrl'] as String?;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(newsDetailProvider),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (coverImageUrl != null && coverImageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(coverImageUrl, width: double.infinity, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(authorName, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time_rounded, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      publishedAt != null
                          ? '${publishedAt.day.toString().padLeft(2, '0')}/${publishedAt.month.toString().padLeft(2, '0')}/${publishedAt.year}'
                          : 'Unknown date',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(content, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6)),
              ],
            ),
          );
        },
      ),
    );
  }
}
