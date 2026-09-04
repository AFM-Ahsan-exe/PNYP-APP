import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/news_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_colors.dart';

class NewsDetailScreen extends ConsumerWidget {
  final String articleId;

  const NewsDetailScreen({super.key, required this.articleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articleAsync = ref.watch(newsDetailProvider(articleId));

    return Scaffold(
      appBar: AppBar(title: const Text('Article')),
      body: articleAsync.when(
        loading: () => const AppLoadingState(message: 'Loading article...'),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(newsDetailProvider(articleId)),
        ),
        data: (article) {
          if (article == null) {
            return const AppEmptyState(message: 'Article not found');
          }
          final title = article.title;
          final content = article.content ?? 'No content';
          final authorName = article.authorId ?? 'Unknown';
          final publishedAt = article.publishedAt?.toDate();
          final coverImageUrl = article.coverImageUrl;

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(newsDetailProvider(articleId)),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (coverImageUrl != null && coverImageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      coverImageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      cacheWidth: 1200,
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: AppTextStyles.title.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        authorName,
                        style: AppTextStyles.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      publishedAt != null
                          ? '${publishedAt.day.toString().padLeft(2, '0')}/${publishedAt.month.toString().padLeft(2, '0')}/${publishedAt.year}'
                          : 'Unknown date',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(content, style: AppTextStyles.body.copyWith(height: 1.6)),
              ],
            ),
          );
        },
      ),
    );
  }
}
