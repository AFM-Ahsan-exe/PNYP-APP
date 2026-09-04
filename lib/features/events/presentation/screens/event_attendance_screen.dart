import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/activity_logger.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/events_providers.dart';

/// FR-039: Admin marks attendance for registered participants.
class EventAttendanceScreen extends ConsumerWidget {
  final String eventId;

  const EventAttendanceScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isAdmin = authState.user?.isAdmin ?? false;

    final registrationsAsync = ref.watch(eventRegistrationsProvider(eventId));
    final eventAsync = ref.watch(eventDetailProvider(eventId));

    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: !isAdmin
          ? const _UnauthorizedView()
          : eventAsync.when(
              loading: () => const AppLoadingState(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (event) {
                final title = event?.title ?? 'event';
                return registrationsAsync.when(
                  loading: () => const AppLoadingState(),
                  error: (e, _) => Center(
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
                            'Could not load registrations',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => ref.invalidate(
                              eventRegistrationsProvider(eventId),
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (registrations) {
                    if (registrations.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No registrations for "$title"',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(eventRegistrationsProvider(eventId));
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: registrations.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final reg = registrations[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: reg.attended
                                    ? AppColors.success.withValues(alpha: 0.15)
                                    : AppColors.textSecondary.withValues(
                                        alpha: 0.15,
                                      ),
                                child: Icon(
                                  reg.attended
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: reg.attended
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                ),
                              ),
                              title: Text(
                                reg.userName ?? reg.userId,
                                style: TextStyle(
                                  fontWeight: reg.attended
                                      ? FontWeight.w600
                                      : null,
                                ),
                              ),
                              subtitle: Text(
                                reg.userEmail ?? reg.userId,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              trailing: Switch(
                                value: reg.attended,
                                onChanged: (value) => _toggleAttendance(
                                  context,
                                  ref,
                                  reg.id,
                                  value,
                                ),
                                activeThumbColor: AppColors.success,
                                activeTrackColor: AppColors.success.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: !isAdmin
          ? null
          : FloatingActionButton.extended(
              onPressed: eventAsync.hasValue && eventAsync.value != null
                  ? () => context.push('/events/$eventId/edit')
                  : null,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Edit Event'),
            ),
    );
  }

  Future<void> _toggleAttendance(
    BuildContext context,
    WidgetRef ref,
    String registrationId,
    bool attended,
  ) async {
    try {
      await ref.read(markAttendanceUseCaseProvider)(
        registrationId: registrationId,
        attended: attended,
      );
      ref.invalidate(eventRegistrationsProvider(eventId));
      unawaited(
        ActivityLogger.log(
          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
          action: attended ? 'attendance_marked' : 'attendance_unmarked',
          details: 'Registration: $registrationId',
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              attended ? 'Attendance marked' : 'Attendance removed',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _UnauthorizedView extends StatelessWidget {
  const _UnauthorizedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              'You are not authorized to manage event attendance.',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
