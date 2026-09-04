import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/gallery_item.dart';
import '../providers/gallery_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../app/theme/app_text_styles.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final albumsAsync = ref.watch(albumsProvider);
    final authState = ref.watch(authControllerProvider);
    final isAdmin = authState.user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_rounded),
              onPressed: () => context.push('/admin/gallery'),
              tooltip: 'Manage Gallery',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search albums...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: albumsAsync.when(
              loading: () =>
                  const AppLoadingState(message: 'Loading gallery...'),
              error: (error, _) => AppErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(albumsProvider),
              ),
              data: (albums) {
                final filtered = _searchQuery.isEmpty
                    ? albums
                    : albums.where((album) {
                        final query = _searchQuery.toLowerCase();
                        return album.title.toLowerCase().contains(query) ||
                            album.description.toLowerCase().contains(query) ||
                            album.tags.any(
                              (tag) => tag.toLowerCase().contains(query),
                            );
                      }).toList();

                if (filtered.isEmpty) {
                  return const AppEmptyState(message: 'No albums found');
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(albumsProvider),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.0,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final album = filtered[index];
                      return _AlbumCard(album: album);
                    },
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

class _AlbumCard extends StatelessWidget {
  final Album album;

  const _AlbumCard({required this.album});

  @override
  Widget build(BuildContext context) {
    final coverUrl = album.coverImageUrl;
    final title = album.title;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/gallery/${album.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: coverUrl.isNotEmpty
                  ? Image.network(
                      coverUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      cacheWidth: 800,
                    )
                  : Container(
                      color: AppColors.navyDeep.withValues(alpha: 0.05),
                      child: Icon(
                        Icons.photo_rounded,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.listTitle),
                  const SizedBox(height: 2),
                  Text(
                    '${album.mediaCount} items',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
