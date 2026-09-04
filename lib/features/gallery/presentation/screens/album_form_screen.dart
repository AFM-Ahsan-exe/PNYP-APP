import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/activity_logger.dart';
import '../../../../core/validators/registration_validators.dart';
import '../providers/gallery_providers.dart';

class AlbumFormScreen extends ConsumerStatefulWidget {
  final String? albumId;

  const AlbumFormScreen({super.key, this.albumId});

  @override
  ConsumerState<AlbumFormScreen> createState() => _AlbumFormScreenState();
}

class _AlbumFormScreenState extends ConsumerState<AlbumFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  File? _coverImage;
  bool _isEdit = false;
  bool _isPublic = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.albumId != null) {
      _isEdit = true;
      _loadAlbum();
    }
  }

  Future<void> _loadAlbum() async {
    setState(() => _isLoading = true);
    try {
      final album = await ref
          .read(galleryRepositoryProvider)
          .getAlbumById(widget.albumId!);
      if (album != null && mounted) {
        setState(() {
          _titleController.text = album.title;
          _descriptionController.text = album.description;
          _tagsController.text = album.tags.join(', ');
          _isPublic = album.isPublic;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppPageHeader(title: _isEdit ? 'Edit Album' : 'Create Album'),
      body: _isLoading && _isEdit
          ? const AppLoadingState(message: 'Loading album...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_successMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: const TextStyle(
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                       validator: (value) => RegistrationValidators.required(value, 'Title'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Public Album'),
                      subtitle: const Text(
                        'Allow all members to view this album',
                      ),
                      value: _isPublic,
                      onChanged: (value) => setState(() => _isPublic = value),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags (comma separated)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickCoverImage,
                      icon: Icon(
                        _coverImage != null
                            ? Icons.check_circle_outline
                            : Icons.image_outlined,
                      ),
                      label: Text(
                        _coverImage != null
                            ? 'Cover image selected'
                            : 'Select Cover Image',
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _saveAlbum,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.navyDarkest,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
                            : Text(_isEdit ? 'Save Changes' : 'Create Album'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _pickCoverImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _coverImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<String?> _uploadCoverImage(String userId) async {
    if (_coverImage == null) return null;
    final bytes = await _coverImage!.readAsBytes();
    final ref = FirebaseStorage.instance.ref().child(
  'gallery/${widget.albumId}/${DateTime.now().millisecondsSinceEpoch}.jpg',
);
    final uploadTask = ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _saveAlbum() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('No authenticated user');

      String? coverImageUrl;
      if (_coverImage != null) {
        coverImageUrl = await _uploadCoverImage(user.uid);
      }

      final data = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'isPublic': _isPublic,
        'tags': _tagsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      };

      if (coverImageUrl != null) {
        data['coverImageUrl'] = coverImageUrl;
      }

      if (_isEdit) {
        // This used to call createAlbumProvider here too - editing an
        // album silently created a brand-new duplicate album document
        // instead of updating the existing one, leaving the original
        // unchanged and orphaned. updateAlbum existed and was fully
        // implemented server-side; nothing on the client ever called it.
        await ref
            .read(updateAlbumProvider)
            .call(widget.albumId!, data);
        ActivityLogger.logAdmin(
          title: 'Album updated',
          type: 'content',
          subtitle: widget.albumId,
        );
      } else {
        await ref.read(createAlbumProvider).call(data);
        ActivityLogger.logAdmin(
          title: 'Album created',
          type: 'content',
          subtitle: 'new',
        );
      }

      ref.invalidate(albumsProvider);

      setState(() {
        _isLoading = false;
        _successMessage = _isEdit ? 'Album updated' : 'Album created';
        _coverImage = null;
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
