import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/validators/registration_validators.dart';
import '../providers/events_providers.dart';

const List<String> kEventCategories = [
  'Meeting',
  'Workshop',
  'Training',
  'Conference',
  'Seminar',
  'Webinar',
  'Community Service',
  'Other',
];

class EventFormScreen extends ConsumerStatefulWidget {
  final String? eventId;

  const EventFormScreen({super.key, this.eventId});

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _bannerUrlController = TextEditingController();
  final _entryFeeController = TextEditingController();
  String _selectedCategory = 'Workshop';
  bool _isOnline = false;
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  DateTime? _registrationDeadline;
  final List<String> _targetAudience = [];

  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadEvent(widget.eventId!);
      });
    }
  }

  Future<void> _loadEvent(String eventId) async {
    setState(() => _isLoading = true);
    try {
      final event = await ref.read(eventDetailProvider(eventId).future);
      if (event == null || !mounted) return;
      setState(() {
        _titleController.text = event.title;
        _descriptionController.text = event.description ?? '';
        _locationController.text = event.location ?? '';
        _maxParticipantsController.text =
            event.maxParticipants?.toString() ?? '';
        _bannerUrlController.text = event.coverImageUrl ?? '';
        _entryFeeController.text = event.entryFee > 0
            ? event.entryFee.toString()
            : '';
        _selectedCategory = event.eventType;
        _isOnline = event.isOnline;
        _startDateTime = event.startDateTime?.toDate();
        _endDateTime = event.endDateTime?.toDate();
        _registrationDeadline = event.registrationDeadline?.toDate();
        _targetAudience
          ..clear()
          ..addAll(event.targetAudience);
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load event: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    _bannerUrlController.dispose();
    _entryFeeController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime({required bool isStart}) async {
    final initialDate = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null || !mounted) return;
    final result = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (isStart) {
        _startDateTime = result;
      } else {
        _endDateTime = result;
      }
    });
  }

  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate:
          _startDateTime ?? DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 59),
    );
    if (time == null || !mounted) return;
    setState(() {
      _registrationDeadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _toggleAudience(String value) {
    setState(() {
      if (_targetAudience.contains(value)) {
        _targetAudience.remove(value);
      } else {
        _targetAudience.add(value);
      }
    });
  }

  String? _validateTitle(String? v) {
    if (v == null || v.trim().isEmpty) return 'Title is required';
    if (v.trim().length > 100) return 'Title must be at most 100 characters';
    return null;
  }

  String? _validateDescription(String? v) {
    if (v == null || v.trim().isEmpty) return 'Description is required';
    if (v.trim().length > 2000) {
      return 'Description must be at most 2000 characters';
    }
    return null;
  }

  String? _validateVenue(String? v) {
    if (v == null || v.trim().isEmpty) return 'Venue is required';
    return null;
  }

  String? _validateMaxParticipants(String? v) {
    if (v == null || v.isEmpty) return null;
    final n = int.tryParse(v);
    if (n == null) return 'Enter a valid number';
    if (n <= 0) return 'Must be greater than 0';
    return null;
  }

  String? _validateDates() {
    if (_startDateTime == null) return 'Start date and time are required';
    if (_endDateTime == null) return 'End date and time are required';
    if (_endDateTime!.isBefore(_startDateTime!)) {
      return 'End must be after start';
    }
    return null;
  }

  Future<void> _save() async {
    final dateError = _validateDates();
    if (dateError != null) {
      setState(() => _errorMessage = dateError);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final eventData = <String, dynamic>{
      'title': _titleController.text.trim(),
      'eventType': _selectedCategory,
      'description': _descriptionController.text.trim(),
      'location': _locationController.text.trim(),
      'isOnline': _isOnline,
      'maxParticipants': int.tryParse(_maxParticipantsController.text) ?? 0,
      'bannerUrl': _bannerUrlController.text.trim(),
      'entryFee': int.tryParse(_entryFeeController.text) ?? 0,
      'targetAudience': _targetAudience,
    };
    if (_startDateTime != null) {
      // A raw cloud_firestore Timestamp has no toJson() and can't be
      // JSON-encoded - jsonEncode would throw before the createEvent/
      // updateEvent request was ever sent, breaking event creation and
      // editing entirely. Send an ISO string; the Cloud Function now
      // converts it back to a Timestamp server-side.
      eventData['startDateTime'] = _startDateTime!.toIso8601String();
    }
    if (_endDateTime != null) {
      eventData['endDateTime'] = _endDateTime!.toIso8601String();
    }
    if (_registrationDeadline != null) {
      eventData['registrationDeadline'] =
          _registrationDeadline!.toIso8601String();
    }

    try {
      if (widget.eventId == null) {
        await ref.read(createEventUseCaseProvider)(eventData);
      } else {
        await ref.read(updateEventUseCaseProvider)(widget.eventId!, eventData);
      }
      if (!mounted) return;
      ref.invalidate(eventsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.eventId == null ? 'Event created' : 'Event updated',
          ),
        ),
      );
      if (context.mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppPageHeader(
        title: widget.eventId == null ? 'Create Event' : 'Edit Event',
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textOnDark,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading && widget.eventId != null
          ? const AppLoadingState(message: 'Loading event...')
          : _errorMessage != null && _errorMessage!.isNotEmpty
          ? _ErrorView(message: _errorMessage!, onRetry: _save)
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildText(
                    'Title',
                    _titleController,
                    validator: _validateTitle,
                    maxLength: 100,
                  ),
                  const SizedBox(height: 16),
                  _buildText(
                    'Description',
                    _descriptionController,
                    maxLines: 4,
                    validator: _validateDescription,
                    maxLength: 2000,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    items: kEventCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedCategory = v ?? 'Workshop'),
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                     validator: (v) => RegistrationValidators.required(v, 'Category'),
                  ),
                  const SizedBox(height: 16),
                  _buildText(
                    'Venue / Location',
                    _locationController,
                    validator: _validateVenue,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Online event'),
                    value: _isOnline,
                    onChanged: (v) => setState(() => _isOnline = v),
                  ),
                  const SizedBox(height: 8),
                  _DateTimePicker(
                    label: 'Start Date & Time',
                    value: _startDateTime,
                    onTap: () => _selectDateTime(isStart: true),
                    validator: (_) => _validateDates(),
                  ),
                  const SizedBox(height: 16),
                  _DateTimePicker(
                    label: 'End Date & Time',
                    value: _endDateTime,
                    onTap: () => _selectDateTime(isStart: false),
                    validator: (_) => _validateDates(),
                  ),
                  const SizedBox(height: 16),
                  _DateTimePicker(
                    label: 'Registration Deadline',
                    value: _registrationDeadline,
                    onTap: _selectDeadline,
                  ),
                  const SizedBox(height: 16),
                  _buildText(
                    'Max Participants',
                    _maxParticipantsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _validateMaxParticipants,
                    helperText: '0 = unlimited',
                  ),
                  const SizedBox(height: 16),
                  _buildText(
                    'Entry Fee (PKR)',
                    _entryFeeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                  _buildText('Banner Image URL', _bannerUrlController),
                  const SizedBox(height: 16),
                  Text('Target Audience', style: AppTextStyles.listTitle),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Members', 'Volunteers', 'Coordinators', 'All']
                        .map((a) {
                          final selected = _targetAudience.contains(a);
                          return FilterChip(
                            label: Text(a),
                            selected: selected,
                            onSelected: (_) => _toggleAudience(a),
                          );
                        })
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navyDarkest,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        widget.eventId == null
                            ? 'Create Event'
                            : 'Save Changes',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildText(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int? maxLength,
    int? maxLines,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength != null ? min(maxLength, 2000) : null,
      maxLines: maxLines ?? 1,
      decoration: InputDecoration(
        labelText: label,
        hintText: helperText,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}

class _DateTimePicker extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String? Function(String?)? validator;

  const _DateTimePicker({
    required this.label,
    required this.value,
    required this.onTap,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today_rounded),
            ),
            child: Text(
              value != null
                  ? '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year} ${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}'
                  : 'Select date and time',
              style: value != null
                  ? AppTextStyles.body
                  : AppTextStyles.bodyMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: 24),
            Text(
              message,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
