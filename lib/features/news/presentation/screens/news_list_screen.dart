import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/news_article.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../providers/news_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_colors.dart';

class NewsListScreen extends ConsumerWidget {
  const NewsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final news = ref.watch(newsStreamProvider);
    final authState = ref.watch(authControllerProvider);
    final isAdmin = authState.user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('News & Updates'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_rounded),
              onPressed: () => context.push('/admin/news'),
              tooltip: 'Manage News',
            ),
        ],
      ),
      body: news.when(
        loading: () => const AppLoadingState(message: 'Loading news...'),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(newsStreamProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(message: 'No news articles yet');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(newsStreamProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _NewsTile(article: items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _NewsTile extends StatelessWidget {
  final NewsArticle article;

  const _NewsTile({required this.article});

  @override
  Widget build(BuildContext context) {
    final title = article.title;
    final summary = article.summary ?? article.content ?? '';
    final publishedAt = article.publishedAt?.toDate();
    final authorName = article.authorId ?? 'Unknown';
    final coverImageUrl = article.coverImageUrl;

    return Card(
      child: InkWell(
        onTap: () => context.push('/news/${article.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Semantics(
          label: '$title, by $authorName',
          button: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (coverImageUrl != null && coverImageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    coverImageUrl,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    cacheWidth: 800,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.listTitle),
                    const SizedBox(height: 6),
                    Text(
                      summary.length > 120
                          ? '${summary.substring(0, 120)}...'
                          : summary,
                      style: AppTextStyles.listSubtitle,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 10),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}