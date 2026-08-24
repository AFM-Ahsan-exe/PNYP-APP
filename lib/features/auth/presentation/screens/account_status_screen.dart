import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/app_user.dart';
import '../providers/auth_providers.dart';

class AccountStatusScreen extends ConsumerWidget {
  final AccountStatus status;

  const AccountStatusScreen({required this.status, super.key});

  String get _title {
    switch (status) {
      case AccountStatus.pending:
        return 'Waiting for administrator approval';
      case AccountStatus.rejected:
        return 'Account application rejected';
      case AccountStatus.suspended:
        return 'Account suspended';
      case AccountStatus.approved:
        return 'Account approved';
      case AccountStatus.expired:
        return 'Membership expired';
    }
  }

  String get _message {
    switch (status) {
      case AccountStatus.pending:
        return 'Your registration was received. An administrator must approve your account before you can access the member dashboard.';
      case AccountStatus.rejected:
        return 'Your registration was not approved. Please contact the program administrator for more information.';
      case AccountStatus.suspended:
        return 'Your account is temporarily suspended. Please contact the program administrator.';
      case AccountStatus.approved:
        return 'Your account is ready.';
      case AccountStatus.expired:
        return 'Your membership has expired. Please renew to continue accessing member features.';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account status')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                status == AccountStatus.pending
                    ? Icons.hourglass_top_rounded
                    : Icons.info_outline_rounded,
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                _title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(_message, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
