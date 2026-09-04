import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/activity_logger.dart';
import '../../domain/entities/gallery_item.dart';
import '../providers/gallery_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';

class AdminGalleryScreen extends ConsumerStatefulWidget {
  const AdminGalleryScreen({super.key});

  @override
  ConsumerState<AdminGalleryScreen> createState() => _AdminGalleryScreenState();
}

class _AdminGalleryScreenState extends ConsumerState<AdminGalleryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final albumsAsync = ref.watch(albumsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/gallery/new'),
            tooltip: 'Create Album',
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
              onChanged: (value) =>
                  setState(() => _query = value.toLowerCase()),
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
                var filtered = albums;
                if (_query.isNotEmpty) {
                  filtered = filtered
                      .where(
                        (a) =>
                            a.title.toLowerCase().contains(_query) ||
                            a.description.toLowerCase().contains(_query),
                      )
                      .toList();
                }
                if (filtered.isEmpty) {
                  return const AppEmptyState(message: 'No albums yet');
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(albumsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _AdminAlbumTile(album: filtered[index]),
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

class _AdminAlbumTile extends ConsumerWidget {
  final Album album;

  const _AdminAlbumTile({required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = album.title;
    final isPublic = album.isPublic;

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
                      '${album.mediaCount} items • ${isPublic ? "Public" : "Private"}',
                      style: AppTextStyles.listSubtitle,
                    ),
                  ],
                ),
              ),
              StatusChip(label: isPublic ? 'Public' : 'Private', compact: true),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/gallery/${album.id}/edit'),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () async {
                  final confirm = await showAppConfirmDialog(
                    context,
                    title: 'Delete Album',
                    message:
                        'Delete "$title"? This will also delete all media in this album.',
                    isDestructive: true,
                  );
                  if (confirm == true && context.mounted) {
                    try {
                      await ref.read(deleteAlbumProvider).call(album.id);
                      ref.invalidate(albumsProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Album deleted')),
                        );
                      }
                      unawaited(
                        ActivityLogger.logAdmin(
                          title: 'Album deleted',
                          type: 'content',
                          subtitle: album.id,
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
