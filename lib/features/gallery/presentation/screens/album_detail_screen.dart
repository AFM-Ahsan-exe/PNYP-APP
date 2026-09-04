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
import '../../../../core/widgets/app_confirm_dialog.dart';

class AlbumDetailScreen extends ConsumerWidget {
  final String albumId;

  const AlbumDetailScreen({super.key, required this.albumId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumAsync = ref.watch(albumDetailProvider(albumId));
    final mediaAsync = ref.watch(albumMediaProvider(albumId));
    final authState = ref.watch(authControllerProvider);
    final isAdmin = authState.user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: albumAsync.when(
          data: (album) => Text(album?.title ?? 'Album'),
          loading: () => const Text('Album'),
          error: (_, _) => const Text('Album'),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.upload_rounded),
              onPressed: () => context.push('/gallery/$albumId/upload'),
              tooltip: 'Upload Media',
            ),
        ],
      ),
      body: albumAsync.when(
        loading: () => const AppLoadingState(message: 'Loading album...'),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(albumDetailProvider(albumId)),
        ),
        data: (album) {
          if (album == null) {
            return const AppEmptyState(message: 'Album not found');
          }
          return Column(
            children: [
              if (album.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(album.description, style: AppTextStyles.body),
                ),
              Expanded(
                child: mediaAsync.when(
                  loading: () =>
                      const AppLoadingState(message: 'Loading media...'),
                  error: (error, _) => AppErrorState(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(albumMediaProvider(albumId)),
                  ),
                  data: (mediaItems) {
                    if (mediaItems.isEmpty) {
                      return const AppEmptyState(
                        message: 'No media in this album',
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(albumMediaProvider(albumId)),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.0,
                            ),
                        itemCount: mediaItems.length,
                        itemBuilder: (context, index) {
                          final media = mediaItems[index];
                          return _MediaCard(media: media, isAdmin: isAdmin);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MediaCard extends ConsumerWidget {
  final GalleryMedia media;
  final bool isAdmin;

  const _MediaCard({required this.media, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _previewMedia(context, media),
        child: GridTile(
          footer: GridTileBar(
            title: Text(
              media.caption.isEmpty ? 'Image' : media.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: isAdmin
                ? IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                    onPressed: () async {
                      final confirm = await showAppConfirmDialog(
                        context,
                        title: 'Delete Media',
                        message: 'Are you sure you want to delete this media?',
                        isDestructive: true,
                      );
                      if (confirm == true && context.mounted) {
                        try {
                          await ref.read(deleteMediaProvider).call(media.id);
                          ref.invalidate(albumMediaProvider(media.albumId));
                          ref.invalidate(albumsProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Media deleted')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('$e')));
                          }
                        }
                      }
                    },
                  )
                : null,
          ),
          child: Image.network(
            media.mediaUrl,
            width: double.infinity,
            fit: BoxFit.cover,
            cacheWidth: 1200,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const AppLoadingState();
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.navyDeep.withValues(alpha: 0.05),
                child: Icon(
                  Icons.broken_image_rounded,
                  size: 48,
                  color: Colors.grey[400],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _previewMedia(BuildContext context, GalleryMedia media) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  media.mediaUrl,
                  fit: BoxFit.contain,
                  cacheWidth: 1200,
                  cacheHeight: 1200,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const AppLoadingState();
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(40),
                      color: Colors.white,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        size: 64,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
