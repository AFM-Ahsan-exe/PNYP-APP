import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/cloud_functions_client.dart';
import '../../../../core/validators/registration_validators.dart';
import '../../../../features/notifications/domain/entities/notification.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends ConsumerState<AdminNotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _recipientController = TextEditingController();
  String _selectedType = 'broadcast';
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final title = _titleController.text.trim();
      final message = _messageController.text.trim();
      final recipient = _recipientController.text.trim();

      final notificationType = NotificationType.values.firstWhere(
        (e) => e.name == _selectedType,
        orElse: () => NotificationType.broadcast,
      );

      final client = CloudFunctionsClient(
        projectId: Firebase.app().options.projectId,
        region: 'us-central1',
      );
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('No authenticated user');
      final idToken = await user.getIdToken();

      await client.call('sendNotification', {
        'title': title,
        'body': message,
        'type': notificationType.name,
        // sendNotification now resolves this to a real uid server-side
        // and throws a clear not-found error if no user matches - it
        // used to be sent as 'recipientId' (a raw Firestore doc ID),
        // silently matching no one since no user's ID is an email.
        if (recipient.isNotEmpty) 'recipientEmail': recipient,
      }, idToken);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification sent successfully')),
      );
      _titleController.clear();
      _messageController.clear();
      _recipientController.clear();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Notification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send a notification to members.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Notification Type',
                  border: OutlineInputBorder(),
                ),
                items: NotificationType.values.map((type) {
                  return DropdownMenuItem(
                    value: type.name,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
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
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) => RegistrationValidators.required(value, 'Message'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _recipientController,
                decoration: const InputDecoration(
                  labelText: 'Recipient email (leave empty for all)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  return RegistrationValidators.email(value);
                },
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _sendNotification,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_isLoading ? 'Sending...' : 'Send Notification'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
