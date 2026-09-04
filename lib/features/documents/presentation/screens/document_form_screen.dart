import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/activity_logger.dart';
import '../../../../core/validators/registration_validators.dart';
import '../providers/documents_providers.dart';

class DocumentFormScreen extends ConsumerStatefulWidget {
  final String? documentId;

  const DocumentFormScreen({super.key, this.documentId});

  @override
  ConsumerState<DocumentFormScreen> createState() => _DocumentFormScreenState();
}

class _DocumentFormScreenState extends ConsumerState<DocumentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagsController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  File? _documentFile;
  String? _accessLevel;
  bool _isEdit = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.documentId != null) {
      _isEdit = true;
      _loadDocument();
    }
  }

  Future<void> _loadDocument() async {
    setState(() => _isLoading = true);
    try {
      final document = await ref
          .read(documentRepositoryProvider)
          .getDocumentById(widget.documentId!);
      if (document != null && mounted) {
        setState(() {
          _titleController.text = document.title;
          _descriptionController.text = document.description ?? '';
          _categoryController.text = document.category ?? '';
          _tagsController.text = document.tags?.join(', ') ?? '';
          _accessLevel = document.accessLevel ?? 'public';
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
      appBar: AppPageHeader(
        title: _isEdit ? 'Edit Document' : 'Upload Document',
      ),
      body: _isLoading && _isEdit
          ? const AppLoadingState(message: 'Loading document...')
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
                    DropdownButtonFormField<String>(
                      initialValue: _accessLevel ?? 'public',
                      decoration: const InputDecoration(
                        labelText: 'Access Level',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'public',
                          child: Text('Public'),
                        ),
                        DropdownMenuItem(
                          value: 'members_only',
                          child: Text('Members Only'),
                        ),
                        DropdownMenuItem(
                          value: 'admin_only',
                          child: Text('Admin Only'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _accessLevel = value),
                       validator: (value) => RegistrationValidators.required(value, 'Access level'),
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
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: Icon(
                        _documentFile != null
                            ? Icons.check_circle_outline
                            : Icons.upload_file_outlined,
                      ),
                      label: Text(
                        _documentFile != null
                            ? 'File selected'
                            : 'Select Document File',
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _saveDocument,
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
                            : Text(
                                _isEdit ? 'Save Changes' : 'Upload Document',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      final path = file?.path;

      if (path != null) {
        setState(() => _documentFile = File(path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file: $e'),
          ),
        );
      }
    }
  }

  Future<String?> _uploadFile(String userId) async {
    if (_documentFile == null) return null;
    final bytes = await _documentFile!.readAsBytes();
    final fileName = _documentFile!.path.split('/').last;
    final ref = FirebaseStorage.instance.ref().child(
      'documents/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName',
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
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    return 'application/octet-stream';
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('No authenticated user');

      String? fileUrl;
      int? fileSize;
      String? fileType;
      if (_documentFile != null) {
        final bytes = await _documentFile!.readAsBytes();
        fileSize = bytes.length;
        fileUrl = await _uploadFile(user.uid);
        if (fileUrl == null) throw StateError('Failed to upload file');
        fileType = _getFileType(_documentFile!.path);
      } else if (_isEdit) {
        final existing = await ref
            .read(documentRepositoryProvider)
            .getDocumentById(widget.documentId!);
        if (existing != null) {
          fileUrl = existing.fileUrl;
          fileSize = existing.fileSize;
          fileType = existing.fileType;
        }
      }

      final data = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _categoryController.text.trim(),
        'accessLevel': _accessLevel ?? 'public',
        'tags': _tagsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      };

      if (fileUrl != null) data['fileUrl'] = fileUrl;
      if (fileSize != null) data['fileSize'] = fileSize;
      if (fileType != null) data['fileType'] = fileType;

      if (_isEdit) {
        await ref.read(updateDocumentProvider).call(widget.documentId!, data);
        unawaited(
          ActivityLogger.logAdmin(
            title: 'Document updated',
            type: 'content',
            subtitle: widget.documentId,
          ),
        );
      } else {
        if (fileUrl == null) {
          throw StateError('Please select a file to upload');
        }
        await ref.read(uploadDocumentProvider).call(data);
        unawaited(
          ActivityLogger.logAdmin(
            title: 'Document uploaded',
            type: 'content',
            subtitle: 'new',
          ),
        );
      }

      ref.invalidate(documentsProvider);

      setState(() {
        _isLoading = false;
        _successMessage = _isEdit ? 'Document updated' : 'Document uploaded';
        _documentFile = null;
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

  String _getFileType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) return 'word';
    return 'unknown';
  }
}