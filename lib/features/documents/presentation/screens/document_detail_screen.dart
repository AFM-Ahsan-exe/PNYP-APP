import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/cloud_functions_client.dart';
import '../../domain/entities/document_item.dart';
import '../providers/documents_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../app/theme/app_text_styles.dart';

class DocumentDetailScreen extends ConsumerWidget {
  final String documentId;

  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentAsync = ref.watch(documentDetailProvider(documentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Document Details')),
      body: documentAsync.when(
        loading: () => const AppLoadingState(message: 'Loading document...'),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(documentDetailProvider(documentId)),
        ),
        data: (document) {
          if (document == null) {
            return const AppEmptyState(message: 'Document not found');
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.navyDeep.withValues(
                                alpha: 0.1,
                              ),
                              child: Icon(
                                _fileIcon(document.fileType),
                                color: AppColors.navyDeep,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                document.title,
                                style: AppTextStyles.title.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (document.description != null &&
                            document.description!.isNotEmpty) ...[
                          Text(
                            'Description',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(document.description!),
                          const SizedBox(height: 16),
                        ],
                        _DetailRow(
                          label: 'Category',
                          value: document.category ?? 'General',
                        ),
                        _DetailRow(
                          label: 'Access',
                          value: _accessLabel(document.accessLevel),
                        ),
                        _DetailRow(
                          label: 'File Type',
                          value: document.fileType ?? 'Unknown',
                        ),
                        if (document.fileSize != null)
                          _DetailRow(
                            label: 'File Size',
                            value: _formatSize(document.fileSize!),
                          ),
                        _DetailRow(
                          label: 'Downloads',
                          value: '${document.downloadCount ?? 0}',
                        ),
                        _DetailRow(
                          label: 'Uploaded By',
                          value: document.uploaderName ?? 'Unknown',
                        ),
                        if (document.tags != null &&
                            document.tags!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Tags',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: document.tags!
                                .map(
                                  (tag) => Chip(
                                    label: Text(
                                      tag,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: AppColors.navyDeep
                                        .withValues(alpha: 0.1),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => _openDocument(context, document),
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Open Document'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.navyDarkest,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

    Future<void> _openDocument(
    BuildContext context,
    DocumentItem document,
  ) async {
    try {
      if (document.fileUrl == null || document.fileUrl!.isEmpty) return;
      final uri = Uri.tryParse(document.fileUrl!);
      if (uri == null || !await canLaunchUrl(uri)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot open this document')),
          );
        }
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      unawaited(_incrementDownloadCount(document.id));
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
      await client.call('incrementDocumentDownload', {
        'documentId': documentId,
      }, idToken);
    } catch (e) {
      debugPrint('incrementDocumentDownload failed (non-fatal): $e');
    }
  }

  IconData _fileIcon(String? fileType) {
    if (fileType == null) return Icons.description_rounded;
    final lower = fileType.toLowerCase();
    if (lower.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (lower.contains('image')) return Icons.image_rounded;
    if (lower.contains('video')) return Icons.video_file_rounded;
    if (lower.contains('word') || lower.contains('doc')) {
      return Icons.description_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  String _accessLabel(String? accessLevel) {
    switch (accessLevel) {
      case 'public':
        return 'Public';
      case 'members_only':
        return 'Members Only';
      case 'admin_only':
        return 'Admin Only';
      default:
        return accessLevel ?? 'Unknown';
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
