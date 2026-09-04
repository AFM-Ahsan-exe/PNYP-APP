import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/activity_logger.dart';
import '../../domain/entities/document_item.dart';
import '../providers/documents_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';

class AdminDocumentsScreen extends ConsumerStatefulWidget {
  const AdminDocumentsScreen({super.key});

  @override
  ConsumerState<AdminDocumentsScreen> createState() =>
      _AdminDocumentsScreenState();
}

class _AdminDocumentsScreenState extends ConsumerState<AdminDocumentsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final documentsAsync = ref.watch(documentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_rounded),
            onPressed: () => context.push('/documents/upload'),
            tooltip: 'Upload Document',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search documents...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) =>
                  setState(() => _query = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: documentsAsync.when(
              loading: () =>
                  const AppLoadingState(message: 'Loading documents...'),
              error: (error, _) => AppErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(documentsProvider),
              ),
              data: (items) {
                var filtered = items;
                if (_query.isNotEmpty) {
                  filtered = filtered
                      .where(
                        (d) =>
                            d.title.toLowerCase().contains(_query) ||
                            (d.category ?? '').toLowerCase().contains(_query),
                      )
                      .toList();
                }
                if (filtered.isEmpty) {
                  return const AppEmptyState(message: 'No documents yet');
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(documentsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _AdminDocumentTile(document: filtered[index]),
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

class _AdminDocumentTile extends ConsumerWidget {
  final DocumentItem document;

  const _AdminDocumentTile({required this.document});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = document.title;
    final accessLevel = document.accessLevel ?? 'public';
    final isPublished = accessLevel != 'admin_only';

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
                      '${document.category ?? 'General'} • ${document.downloadCount ?? 0} downloads',
                      style: AppTextStyles.listSubtitle,
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: isPublished ? 'Public' : 'Admin Only',
                compact: true,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/documents/${document.id}/edit'),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () async {
                  final confirm = await showAppConfirmDialog(
                    context,
                    title: 'Delete Document',
                    message: 'Delete "$title"?',
                    isDestructive: true,
                  );
                  if (confirm == true && context.mounted) {
                    try {
                      await ref.read(deleteDocumentProvider).call(document.id);
                      ref.invalidate(documentsProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Document deleted')),
                        );
                      }
                      unawaited(
                        ActivityLogger.logAdmin(
                          title: 'Document deleted',
                          type: 'content',
                          subtitle: document.id,
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
