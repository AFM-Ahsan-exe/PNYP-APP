import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/search_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_list_tile.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _query = '';
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = value);
    });
  }

  void _onClear() {
    _onQueryChanged('');
  }

  Future<void> _loadMore() async {
    final async = ref.read(searchProvider(_query));
    if (async.value == null || !async.value!.hasMore) return;
    final nextCursor = async.value!.nextCursor;
    if (nextCursor == null) return;
    await ref.read(searchContentProvider)(_query, cursor: nextCursor);
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = _query.isEmpty
        ? null
        : ref.watch(searchProvider(_query));

    return Scaffold(
      appBar: AppBar(title: Text('Search', style: AppTextStyles.headline)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppSearchBar(
              hintText: 'Search events, news, opportunities...',
              onChanged: _onQueryChanged,
              query: _query,
              onClear: _onClear,
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),

                        const SizedBox(height: 16),
                        Text(
                          'Search for events, news, and opportunities',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : _buildResults(searchAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(AsyncValue<SearchPage>? async) {
    if (async == null) {
      return const SizedBox.shrink();
    }

    if (async.isLoading) {
      return const AppLoadingState(message: 'Searching...');
    }

    if (async.hasError) {
      return AppErrorState(
        message: async.error.toString(),
        onRetry: () => ref.invalidate(searchProvider(_query)),
      );
    }

    final page = async.value;
    if (page == null || page.results.isEmpty) {
      return const AppEmptyState(message: 'No results found');
    }

    final events = page.results.where((r) => r.type == 'event').toList();
    final news = page.results.where((r) => r.type == 'news').toList();
    final opportunities = page.results
        .where((r) => r.type == 'opportunity')
        .toList();

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
          _loadMore();
        }
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (events.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: const Text('Events', style: AppTextStyles.title),
            ),
            ...events.map(
              (event) => _SearchResultTile(
                title: event.title,
                subtitle: event.subtitle,
                icon: Icons.event_rounded,
                color: AppColors.accentBlue,
              ),
            ),
          ],
          if (news.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: const Text('News', style: AppTextStyles.title),
            ),
            ...news.map(
              (article) => _SearchResultTile(
                title: article.title,
                subtitle: article.subtitle,
                icon: Icons.article_rounded,
                color: AppColors.success,
              ),
            ),
          ],
          if (opportunities.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: const Text('Opportunities', style: AppTextStyles.title),
            ),
            ...opportunities.map(
              (opportunity) => _SearchResultTile(
                title: opportunity.title,
                subtitle: opportunity.subtitle,
                icon: Icons.work_outline_rounded,
                color: AppColors.navyDeep,
              ),
            ),
          ],
          if (page.hasMore)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: TextButton.icon(
                  onPressed: _loadMore,
                  icon: const Icon(Icons.expand_more_rounded),
                  label: const Text('Load More'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SearchResultTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      title: title,
      subtitle: subtitle,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: AppColors.textSecondary,
      ),
    );
  }
}
