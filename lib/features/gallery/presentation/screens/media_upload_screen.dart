import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/activity_logger.dart';
import '../providers/gallery_providers.dart';

class MediaUploadScreen extends ConsumerStatefulWidget {
  final String albumId;

  const MediaUploadScreen({super.key, required this.albumId});

  @override
  ConsumerState<MediaUploadScreen> createState() => _MediaUploadScreenState();
}

class _MediaUploadScreenState extends ConsumerState<MediaUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final _tagsController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  File? _mediaFile;
  String? _mediaType;

  @override
  void dispose() {
    _captionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Media')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickMedia,
                icon: Icon(
                  _mediaFile != null
                      ? Icons.check_circle_outline
                      : Icons.image_outlined,
                ),
                label: Text(
                  _mediaFile != null ? 'Media selected' : 'Select Image/Video',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _captionController,
                decoration: const InputDecoration(
                  labelText: 'Caption',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _uploadMedia,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navyDarkest,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Upload Media'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickMedia() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickMedia();
      if (picked != null) {
        final file = File(picked.path);
        final ext = picked.path.split('.').last.toLowerCase();
        setState(() {
          _mediaFile = file;
          _mediaType = ext == 'mp4' || ext == 'mov' ? 'video' : 'image';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick media: $e')));
      }
    }
  }

  Future<String?> _uploadMediaFile(String albumId) async {
    if (_mediaFile == null) return null;
    final bytes = await _mediaFile!.readAsBytes();
    final fileName = _mediaFile!.path.split('/').last;
    final ref = FirebaseStorage.instance.ref().child(
      'gallery/$albumId/${DateTime.now().millisecondsSinceEpoch}_$fileName',
    );
    final contentType = _getContentType(fileName);
    final uploadTask = ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  String _getContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    return 'application/octet-stream';
  }

  Future<void> _uploadMedia() async {
    if (_mediaFile == null) {
      setState(() => _errorMessage = 'Please select media to upload');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('No authenticated user');

      final mediaUrl = await _uploadMediaFile(widget.albumId);
      if (mediaUrl == null) throw StateError('Failed to upload media');

      final data = <String, dynamic>{
        'albumId': widget.albumId,
        'mediaUrl': mediaUrl,
        'mediaType': _mediaType ?? 'image',
        'caption': _captionController.text.trim(),
        'tags': _tagsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      };

      await ref.read(addMediaProvider).call(data);
      ActivityLogger.logAdmin(
        title: 'Media uploaded',
        type: 'content',
        subtitle: widget.albumId,
      );

      ref.invalidate(albumMediaProvider(widget.albumId));
      ref.invalidate(albumsProvider);

      setState(() {
        _isLoading = false;
        _successMessage = 'Media uploaded successfully';
        _mediaFile = null;
        _mediaType = null;
        _captionController.clear();
        _tagsController.clear();
      });

      if (mounted) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) context.pop();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }
}
