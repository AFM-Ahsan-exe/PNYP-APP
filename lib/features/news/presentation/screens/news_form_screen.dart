import 'dart:async';
import 'dart:io';

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
import '../providers/news_providers.dart';

class NewsFormScreen extends ConsumerStatefulWidget {
  final String? articleId;

  const NewsFormScreen({super.key, this.articleId});

  @override
  ConsumerState<NewsFormScreen> createState() => _NewsFormScreenState();
}

class _NewsFormScreenState extends ConsumerState<NewsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _contentController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagsController = TextEditingController();
  final _targetAudienceController = TextEditingController();

  bool _isLoading = false;
  bool _isPublishing = false;
  String? _errorMessage;
  String? _successMessage;
  File? _coverImage;
  bool _isEdit = false;

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _targetAudienceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.articleId != null) {
      _isEdit = true;
      _loadArticle();
    }
  }

  Future<void> _loadArticle() async {
    setState(() => _isLoading = true);
    try {
      final article = await ref
          .read(newsRepositoryProvider)
          .getNewsById(widget.articleId!);
      if (article != null && mounted) {
        setState(() {
          _titleController.text = article.title;
          _summaryController.text = article.summary ?? '';
          _contentController.text = article.content ?? '';
          _categoryController.text = article.category ?? '';
          _tagsController.text = article.tags?.join(', ') ?? '';
          _targetAudienceController.text =
              article.targetAudience?.join(', ') ?? '';
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
      appBar: AppPageHeader(title: _isEdit ? 'Edit Article' : 'New Article'),
      body: _isLoading && _isEdit
          ? const AppLoadingState(message: 'Loading article...')
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
                      controller: _summaryController,
                      decoration: const InputDecoration(
                        labelText: 'Summary',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Content',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 8,
                       validator: (value) => RegistrationValidators.required(value, 'Content'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category',
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _targetAudienceController,
                      decoration: const InputDecoration(
                        labelText:
                            'Target Audience (comma separated provinces)',
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
                        onPressed: _isLoading ? null : _saveArticle,
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
                            : Text(_isEdit ? 'Save Changes' : 'Create Article'),
                      ),
                    ),
                    if (_isEdit)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: OutlinedButton(
                          onPressed: _isLoading || _isPublishing
                              ? null
                              : _publishArticle,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: const BorderSide(color: AppColors.success),
                          ),
                          child: _isPublishing
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: AppColors.success,
                                  ),
                                )
                              : Text(
                                  _isPublishing
                                      ? 'Publishing...'
                                      : 'Publish Now',
                                ),
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
      'news/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final uploadTask = ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _saveArticle({bool publish = false}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _isPublishing = publish;
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
        'content': _contentController.text.trim(),
        'summary': _summaryController.text.trim(),
        'category': _categoryController.text.trim(),
        'tags': _tagsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'targetAudience': _targetAudienceController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'isPublished': publish,
      };

      if (coverImageUrl != null) {
        data['coverImageUrl'] = coverImageUrl;
      }

      if (_isEdit) {
        await ref.read(updateNewsArticleProvider).call(widget.articleId!, data);
        ActivityLogger.logAdmin(
          title: 'News updated',
          type: 'content',
          subtitle: widget.articleId,
        );
      } else {
        await ref.read(createNewsArticleProvider).call(data);
        ActivityLogger.logAdmin(
          title: 'News created',
          type: 'content',
          subtitle: 'draft',
        );
      }

      ref.invalidate(newsProvider);

      setState(() {
        _isLoading = false;
        _successMessage = _isEdit ? 'Article updated' : 'Article created';
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

  Future<void> _publishArticle() async {
    await _saveArticle(publish: true);
  }
}
