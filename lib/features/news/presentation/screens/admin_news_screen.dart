import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/activity_logger.dart';
import '../../domain/entities/news_article.dart';
import '../providers/news_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';

class AdminNewsScreen extends ConsumerStatefulWidget {
  const AdminNewsScreen({super.key});

  @override
  ConsumerState<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends ConsumerState<AdminNewsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage News'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/news/new'),
            tooltip: 'Create Article',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search articles...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) =>
                  setState(() => _query = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: newsAsync.when(
              loading: () =>
                  const AppLoadingState(message: 'Loading articles...'),
              error: (error, _) => AppErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(newsProvider),
              ),
              data: (items) {
                var filtered = items;
                if (_query.isNotEmpty) {
                  filtered = filtered
                      .where(
                        (n) =>
                            n.title.toLowerCase().contains(_query) ||
                            (n.authorId ?? '').toLowerCase().contains(_query),
                      )
                      .toList();
                }
                if (filtered.isEmpty) {
                  return const AppEmptyState(message: 'No news articles yet');
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(newsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _AdminNewsTile(article: filtered[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminNewsTile extends ConsumerWidget {
  final NewsArticle article;

  const _AdminNewsTile({required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = article.title;
    final publishedAt = article.publishedAt?.toDate();
    final isPublished = article.isPublished ?? false;

    return Card(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPublished
                          ? 'Published: ${publishedAt != null ? '${publishedAt.day}/${publishedAt.month}/${publishedAt.year}' : 'Unknown date'}'
                          : 'Draft',
                      style: AppTextStyles.listSubtitle,
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: isPublished ? 'Published' : 'Draft',
                compact: true,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/news/${article.id}/edit'),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () async {
                  final confirm = await showAppConfirmDialog(
                    context,
                    title: 'Delete Article',
                    message: 'Delete "$title"?',
                    isDestructive: true,
                  );
                  if (confirm == true && context.mounted) {
                    try {
                      await ref
                          .read(deleteNewsArticleProvider)
                          .call(article.id);
                      ref.invalidate(newsProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Article deleted')),
                        );
                      }
                      unawaited(
                        ActivityLogger.logAdmin(
                          title: 'News deleted',
                          type: 'content',
                          subtitle: article.id,
                        ),
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    }
                  }
                },
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
