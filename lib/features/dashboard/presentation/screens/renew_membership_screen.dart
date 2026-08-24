import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../app/theme/app_colors.dart';
import '../providers/member_providers.dart';

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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 24),
                Text(
                  'Could not load your profile',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(memberUserProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No profile data found'));
          }
          return SingleChildScrollView(
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Membership',
                            style: Theme.of(context).textTheme.titleMedium,
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
                  Text(
                    'Select Membership Type',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
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
                    validator: (value) => value == null
                        ? 'Please select a membership type'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Payment Proof',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
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
                    style: const TextStyle(fontSize: 12),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      final result = await FilePicker.platform.pickFiles(
        type: allowedExtensions.contains('pdf')
            ? FileType.custom
            : FileType.image,
        allowedExtensions: allowedExtensions,
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _documentBytes[key] = result.files.single.bytes!;
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('No authenticated user');

      final uploadPromises = <Future<String?>>[];
      if (_documentBytes['paymentProof'] != null) {
        uploadPromises.add(
          _uploadFile(
            'renewals/${user.uid}_${DateTime.now().millisecondsSinceEpoch}_payment.jpg',
            _documentBytes['paymentProof']!,
            'image/jpeg',
          ),
        );
      }

      final urls = await Future.wait(uploadPromises);
      final paymentProofUrl = urls.first;

      final now = DateTime.now();
      final expiryDate = DateTime(now.year + 1, now.month, now.day);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'membershipType': _selectedMembershipType,
            'membershipStartDate': FieldValue.serverTimestamp(),
            'membershipExpiryDate': Timestamp.fromDate(expiryDate),
            'status': 'pending',
            'paymentProofUrl': paymentProofUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await FirebaseFirestore.instance.collection('payments').add({
        'userId': user.uid,
        'paymentType': 'membership_renewal',
        'year': now.year,
        'amount': _amountController.text.trim(),
        'status': 'pending',
        'proofUrl': paymentProofUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ref.invalidate(memberUserProvider);

      setState(() {
        _isLoading = false;
        _successMessage = 'Renewal submitted for approval';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<String?> _uploadFile(
    String path,
    List<int> bytes,
    String contentType,
  ) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    final metadata = SettableMetadata(contentType: contentType);
    final uploadTask = ref.putData(Uint8List.fromList(bytes), metadata);
    final snapshot = await uploadTask;
    return snapshot.ref.fullPath;
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
