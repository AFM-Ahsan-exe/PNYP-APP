import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/cloud_functions_client.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/document_item.dart';
import '../providers/documents_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../app/theme/app_text_styles.dart';

class DocumentsListScreen extends ConsumerWidget {
  const DocumentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(documentsStreamProvider);
    final authState = ref.watch(authControllerProvider);
    final canManage =
        authState.user?.hasAtLeastRole('content_manager') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_rounded),
              onPressed: () => context.push('/admin/documents'),
              tooltip: 'Manage Documents',
            ),
        ],
      ),
      body: documents.when(
        loading: () => const AppLoadingState(message: 'Loading documents...'),
        error: (error, _) => AppErrorState(
          message: error.toString(),
                    onRetry: () => ref.invalidate(documentsStreamProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(message: 'No documents available');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(documentsStreamProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _DocumentTile(document: items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final DocumentItem document;

  const _DocumentTile({required this.document});

  @override
  Widget build(BuildContext context) {
    final title = document.title;
    final description = document.description ?? '';
    final category = document.category ?? 'General';
    final fileType = document.fileType ?? '';
    final downloadCount = document.downloadCount ?? 0;

    return Card(
      child: InkWell(
        onTap: () => context.push('/documents/${document.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.navyDeep.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _fileIcon(fileType),
                  color: AppColors.navyDeep,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
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
                      description.length > 80
                          ? '${description.substring(0, 80)}...'
                          : description,
                      style: AppTextStyles.listSubtitle,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$category • $downloadCount downloads',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_rounded),
                onPressed: () => _downloadDocument(
                  context,
                  document.id,
                  document.fileUrl ?? '',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _fileIcon(String fileType) {
    if (fileType.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (fileType.contains('image')) return Icons.image_rounded;
    if (fileType.contains('video')) return Icons.video_file_rounded;
    return Icons.description_rounded;
  }

  Future<void> _downloadDocument(
    BuildContext context,
    String documentId,
    String fileUrl,
  ) async {
    try {
      final uri = Uri.tryParse(fileUrl);
      if (uri == null || !await canLaunchUrl(uri)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot open this document')),
          );
        }
        return;
      }

      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      unawaited(_incrementDownloadCount(documentId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _incrementDownloadCount(String documentId) async {
    try {
      final client = CloudFunctionsClient(
        projectId: Firebase.app().options.projectId,
        region: 'us-central1',
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final idToken = await user.getIdToken();

      await client.call(
        'incrementDocumentDownload',
        {
          'documentId': documentId,
        },
        idToken,
      );
    } catch (e) {
      debugPrint('incrementDocumentDownload failed (non-fatal): $e');
    }
  }
}