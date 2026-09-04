import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/validators/registration_validators.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../providers/member_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _educationController = TextEditingController();
  final _employmentController = TextEditingController();
  final _skillsController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  File? _profilePicture;

  @override
  void dispose() {
    _phoneController.dispose();
    _educationController.dispose();
    _employmentController.dispose();
    _skillsController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(memberUserProvider);

    return Scaffold(
      appBar: const AppPageHeader(title: 'Edit Profile'),
      body: userAsync.when(
        loading: () => const AppLoadingState(message: 'Loading profile...'),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(memberUserProvider),
        ),
        data: (user) {
          if (user == null) {
            return const AppEmptyState(message: 'No profile data found');
          }
          _phoneController.text = user.phone ?? '';
          _educationController.text = user.education ?? '';
          _employmentController.text = user.employment ?? '';
          _skillsController.text = user.skills.join(', ');
          _emergencyNameController.text = user.emergencyContactName ?? '';
          _emergencyPhoneController.text = user.emergencyContactPhone ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 56,
                          backgroundColor: AppColors.navyDeep.withValues(
                            alpha: 0.1,
                          ),
                          child: _buildProfilePicture(user),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Colors.white,
                              ),
                              onPressed: _pickProfilePicture,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                              style: const TextStyle(color: AppColors.success),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+923001234567',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: RegistrationValidators.phone,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _educationController,
                    decoration: const InputDecoration(
                      labelText: 'Education',
                      hintText: 'BSc Computer Science',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _employmentController,
                    decoration: const InputDecoration(
                      labelText: 'Employment',
                      hintText: 'Software Engineer at XYZ',
                      prefixIcon: Icon(Icons.work_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _skillsController,
                    decoration: const InputDecoration(
                      labelText: 'Skills (comma separated)',
                      hintText: 'Flutter, Dart, Firebase',
                      prefixIcon: Icon(Icons.auto_awesome_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emergencyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Contact Name',
                      hintText: 'John Doe',
                      prefixIcon: Icon(Icons.contact_emergency_outlined),
                    ),
                    validator: (value) => RegistrationValidators.required(
                      value,
                      'Emergency contact name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emergencyPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Contact Phone',
                      hintText: '+923001234567',
                      prefixIcon: Icon(Icons.phone_callback_outlined),
                    ),
                    validator: RegistrationValidators.phone,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _saveProfile,
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
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfilePicture(AppUser user) {
    if (_profilePicture != null) {
      return ClipOval(
        child: Image.file(
          _profilePicture!,
          width: 112,
          height: 112,
          fit: BoxFit.cover,
        ),
      );
    }
    if (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          user.profilePictureUrl!,
          width: 112,
          height: 112,
          fit: BoxFit.cover,
          cacheWidth: 224,
          cacheHeight: 224,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.navyDeep,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Text(
              _getInitials(user),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDeep,
              ),
            );
          },
        ),
      );
    }
    return Text(
      _getInitials(user),
      style: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.navyDeep,
      ),
    );
  }

  Future<void> _pickProfilePicture() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _profilePicture = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('No authenticated user');

      String? profilePictureUrl;
      if (_profilePicture != null) {
        final bytes = await _profilePicture!.readAsBytes();
                final ref = FirebaseStorage.instance.ref().child(
          'profile_pictures/${user.uid}/profile.jpg',
        );
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        final uploadTask = ref.putData(bytes, metadata);
        final snapshot = await uploadTask;
        profilePictureUrl = await snapshot.ref.getDownloadURL();
      }

      final data = <String, dynamic>{
        'phone': _phoneController.text.trim(),
        'education': _educationController.text.trim(),
        'employment': _employmentController.text.trim(),
        'skills': _skillsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        'emergencyContactName': _emergencyNameController.text.trim(),
        'emergencyContactPhone': _emergencyPhoneController.text.trim(),
      };

      if (profilePictureUrl != null) {
        data['profilePictureUrl'] = profilePictureUrl;
      }

      await ref.read(profileRepositoryProvider).updateProfile(data);
      ref.invalidate(memberUserProvider);

      setState(() {
        _isLoading = false;
        _successMessage = 'Profile updated successfully';
        _profilePicture = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  String _getInitials(AppUser user) {
    final name = user.fullName ?? user.displayName;
    if (name != null && name.isNotEmpty) {
      final parts = name.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }
    final email = user.email;
    if (email != null && email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }
}
