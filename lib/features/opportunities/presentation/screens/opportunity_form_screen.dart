import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/activity_logger.dart';
import '../../../../core/validators/registration_validators.dart';
import '../providers/opportunities_providers.dart';

class OpportunityFormScreen extends ConsumerStatefulWidget {
  final String? opportunityId;

  const OpportunityFormScreen({super.key, this.opportunityId});

  @override
  ConsumerState<OpportunityFormScreen> createState() =>
      _OpportunityFormScreenState();
}

class _OpportunityFormScreenState extends ConsumerState<OpportunityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _organizationController = TextEditingController();
  final _locationController = TextEditingController();
  final _applyUrlController = TextEditingController();
  final _tagsController = TextEditingController();
  final _targetAudienceController = TextEditingController();
  final _maxParticipantsController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isEdit = false;
  bool _isRemote = false;
  String _status = 'active';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _organizationController.dispose();
    _locationController.dispose();
    _applyUrlController.dispose();
    _tagsController.dispose();
    _targetAudienceController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.opportunityId != null) {
      _isEdit = true;
      _loadOpportunity();
    }
  }

  Future<void> _loadOpportunity() async {
    setState(() => _isLoading = true);
    try {
      final opportunity = await ref
          .read(opportunityRepositoryProvider)
          .getOpportunityById(widget.opportunityId!);
      if (opportunity != null && mounted) {
        setState(() {
          _titleController.text = opportunity.title;
          _descriptionController.text = opportunity.description ?? '';
          _organizationController.text = opportunity.organization ?? '';
          _locationController.text = opportunity.location ?? '';
          _applyUrlController.text = opportunity.applyUrl ?? '';
          _tagsController.text = opportunity.tags?.join(', ') ?? '';
          _targetAudienceController.text =
              opportunity.targetAudience?.join(', ') ?? '';
          _isRemote = opportunity.isRemote;
          _status = opportunity.status ?? 'active';
          if (opportunity.maxParticipants != null) {
            _maxParticipantsController.text = opportunity.maxParticipants
                .toString();
          }
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
        title: _isEdit ? 'Edit Opportunity' : 'New Opportunity',
      ),
      body: _isLoading && _isEdit
          ? const AppLoadingState(message: 'Loading opportunity...')
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
                      controller: _organizationController,
                      decoration: const InputDecoration(
                        labelText: 'Organization',
                        border: OutlineInputBorder(),
                      ),
                       validator: (value) => RegistrationValidators.required(value, 'Organization'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Description is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _applyUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Application URL',
                        border: OutlineInputBorder(),
                      ),
                       validator: (value) => RegistrationValidators.required(value, 'Application URL'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Remote Opportunity'),
                      subtitle: const Text('Allow remote participation'),
                      value: _isRemote,
                      onChanged: (value) => setState(() => _isRemote = value),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _maxParticipantsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max Participants (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: 'paused',
                          child: Text('Paused'),
                        ),
                        DropdownMenuItem(
                          value: 'closed',
                          child: Text('Closed'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _status = value ?? 'active'),
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
                        labelText: 'Target Audience (comma separated)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _saveOpportunity,
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
                                _isEdit ? 'Save Changes' : 'Create Opportunity',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _saveOpportunity() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('No authenticated user');

      final data = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'organization': _organizationController.text.trim(),
        'location': _locationController.text.trim(),
        'isRemote': _isRemote,
        'applyUrl': _applyUrlController.text.trim(),
        'status': _status,
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
      };

      final maxParticipants = int.tryParse(
        _maxParticipantsController.text.trim(),
      );
      if (maxParticipants != null && maxParticipants > 0) {
        data['maxParticipants'] = maxParticipants;
      }

      if (_isEdit) {
        await ref
            .read(updateOpportunityProvider)
            .call(widget.opportunityId!, data);
        ActivityLogger.logAdmin(
          title: 'Opportunity updated',
          type: 'content',
          subtitle: widget.opportunityId,
        );
      } else {
        await ref.read(createOpportunityProvider).call(data);
        ActivityLogger.logAdmin(
          title: 'Opportunity created',
          type: 'content',
          subtitle: 'new',
        );
      }

      ref.invalidate(opportunitiesProvider);

      setState(() {
        _isLoading = false;
        _successMessage = _isEdit
            ? 'Opportunity updated'
            : 'Opportunity created';
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
