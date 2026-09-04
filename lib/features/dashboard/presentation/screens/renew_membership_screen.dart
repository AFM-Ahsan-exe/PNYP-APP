import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/activity_logger.dart';
import '../../../../features/renewal/presentation/providers/renewal_providers.dart';
import '../providers/member_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/validators/registration_validators.dart';
import '../../../../app/theme/app_text_styles.dart';

class RenewMembershipScreen extends ConsumerStatefulWidget {
  const RenewMembershipScreen({super.key});

  @override
  ConsumerState<RenewMembershipScreen> createState() =>
      _RenewMembershipScreenState();
}

class _RenewMembershipScreenState extends ConsumerState<RenewMembershipScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedMembershipType;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  final Map<String, List<int>> _documentBytes = {};

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(memberUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Renew Membership')),
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
          return SingleChildScrollView(
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
                              style: const TextStyle(color: AppColors.success),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Membership',
                            style: AppTextStyles.title,
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            label: 'Member ID',
                            value: user.membershipId ?? 'Not assigned',
                          ),
                          _DetailRow(
                            label: 'Type',
                            value: _membershipTypeLabel(user.membershipType),
                          ),
                          _DetailRow(
                            label: 'Expires',
                            value: _formatDate(
                              user.membershipExpiryDate?.toDate(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Select Membership Type', style: AppTextStyles.title),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue:
                        _selectedMembershipType ?? user.membershipType,
                    decoration: const InputDecoration(
                      labelText: 'Membership Type',
                      prefixIcon: Icon(Icons.card_membership_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'youth_mpa',
                        child: Text('Youth MPA'),
                      ),
                      DropdownMenuItem(
                        value: 'youth_mna',
                        child: Text('Youth MNA'),
                      ),
                      DropdownMenuItem(
                        value: 'youth_senator',
                        child: Text('Youth Senator'),
                      ),
                      DropdownMenuItem(
                        value: 'youth_judge',
                        child: Text('Youth Judge'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedMembershipType = value),
                     validator: (value) => RegistrationValidators.required(value, 'Membership type'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (PKR)',
                      hintText: 'Enter payment amount',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter the payment amount';
                      }
                      final amount = int.tryParse(value.trim());
                      if (amount == null || amount <= 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Text('Payment Proof', style: AppTextStyles.title),
                  const SizedBox(height: 12),
                  _uploadTile('Payment proof (JPG/PNG/PDF)', 'paymentProof', [
                    'png',
                    'jpg',
                    'jpeg',
                    'pdf',
                  ]),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _submitRenewal,
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
                        : const Text('Submit Renewal'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _uploadTile(String title, String key, List<String> allowedExtensions) {
    final hasFile = _documentBytes.containsKey(key);
    return OutlinedButton.icon(
      onPressed: () => _pickFile(key, title, allowedExtensions),
      icon: Icon(
        hasFile ? Icons.check_circle_outline : Icons.upload_file_outlined,
      ),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    hasFile ? 'File selected' : 'Tap to upload',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasFile
                  ? Icons.remove_circle_outline
                  : Icons.attach_file_outlined,
            ),
          ],
        ),
      ),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        side: BorderSide(color: hasFile ? AppColors.success : AppColors.border),
      ),
    );
  }

  Future<void> _pickFile(
    String key,
    String title,
    List<String> allowedExtensions,
  ) async {
    try {
      final result = await FilePicker.pickFiles(
        type: allowedExtensions.contains('pdf')
            ? FileType.custom
            : FileType.image,
        allowedExtensions: allowedExtensions,
      );
      if (result.isNotEmpty) {
        final bytes = await result.single.readAsBytes();
        setState(() {
          _documentBytes[key] = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick $title: $e')));
      }
    }
  }

  Future<String?> _uploadPaymentProof(
    String userId,
    List<int> bytes,
    String fileName,
  ) async {
    final ext = fileName.split('.').last.toLowerCase();
    final contentType = ext == 'pdf' ? 'application/pdf' : 'image/jpeg';
    final ref = FirebaseStorage.instance.ref().child(
      'renewals/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName',
    );
    final metadata = SettableMetadata(contentType: contentType);
    final uploadTask = ref.putData(Uint8List.fromList(bytes), metadata);
    final snapshot = await uploadTask;
    return snapshot.ref.fullPath;
  }

  Future<void> _submitRenewal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_documentBytes.isEmpty) {
      setState(() => _errorMessage = 'Please upload payment proof');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final userAsync = ref.read(memberUserProvider);
      final user = userAsync.value;
      if (user == null) throw StateError('No profile data');

      final pickedFile = _documentBytes['paymentProof'];
      if (pickedFile == null) {
        throw StateError('Payment proof is required');
      }

      final originalName = pickedFile.isNotEmpty
          ? 'payment_proof.jpg'
          : 'payment_proof.pdf';
      final paymentProofUrl = await _uploadPaymentProof(
        user.uid,
        pickedFile,
        originalName,
      );
      if (paymentProofUrl == null) {
        throw StateError('Failed to upload payment proof');
      }

      await ref
          .read(submitRenewalProvider)
          .call(
            userId: user.uid,
            membershipType:
                _selectedMembershipType ?? user.membershipType ?? 'youth_mpa',
            paymentProofUrl: paymentProofUrl,
          );

      unawaited(
        ActivityLogger.log(
          userId: user.uid,
          action: 'renew_membership',
          details: 'Type: $_selectedMembershipType',
        ),
      );
      unawaited(
        ActivityLogger.logAdmin(
          title: 'Membership renewal',
          type: 'member',
          subtitle: '${user.email} renewed $_selectedMembershipType',
        ),
      );

      ref.invalidate(memberUserProvider);

      setState(() {
        _isLoading = false;
        _successMessage = 'Renewal submitted for approval';
        _documentBytes.clear();
        _amountController.clear();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  String _membershipTypeLabel(String? type) {
    switch (type) {
      case 'youth_mpa':
        return 'Youth MPA';
      case 'youth_mna':
        return 'Youth MNA';
      case 'youth_senator':
        return 'Youth Senator';
      case 'youth_judge':
        return 'Youth Judge';
      default:
        return type ?? 'Not assigned';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not provided';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
