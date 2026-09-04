import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/event.dart';
import '../providers/events_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../app/theme/app_text_styles.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final regAsync = ref.watch(eventRegistrationStatusProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          eventAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (event) {
              if (event == null) return const SizedBox.shrink();
              final isAdmin =
                  ref.watch(authControllerProvider).user?.isAdmin ?? false;
              if (!isAdmin) return const SizedBox.shrink();
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    tooltip: 'Edit Event',
                    onPressed: () => context.push('/events/$eventId/edit'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.how_to_reg_rounded),
                    tooltip: 'Mark Attendance',
                    onPressed: () =>
                        context.push('/events/$eventId/attendance'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: eventAsync.when(
        loading: () =>
            const AppLoadingState(message: 'Loading event details...'),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(eventDetailProvider(eventId)),
        ),
        data: (event) {
          if (event == null) {
            return const AppEmptyState(message: 'Event not found');
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(eventDetailProvider(eventId));
              ref.invalidate(eventRegistrationStatusProvider(eventId));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  event.title,
                  style: AppTextStyles.title.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.eventType,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (event.status == 'cancelled' || event.status == 'completed')
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.status == 'cancelled' ? 'Cancelled' : 'Completed',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                if (event.coverImageUrl != null &&
                    event.coverImageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      event.coverImageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      cacheWidth: 1200,
                    ),
                  ),
                const SizedBox(height: 20),
                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Start',
                  value: _formatDateTime(event.startDateTime?.toDate()),
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.event_busy_rounded,
                  label: 'End',
                  value: _formatDateTime(event.endDateTime?.toDate()),
                ),
                const SizedBox(height: 10),
                if (event.location != null && event.location!.isNotEmpty)
                  _InfoRow(
                    icon: Icons.location_on_rounded,
                    label: 'Location',
                    value: event.location!,
                  ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.people_rounded,
                  label: 'Participants',
                  value:
                      '${event.currentParticipants ?? 0}${event.maxParticipants != null && (event.maxParticipants ?? 0) > 0 ? " / ${event.maxParticipants}" : ""}',
                ),
                if (event.registrationDeadline != null) ...[
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.access_alarm_rounded,
                    label: 'Reg. Deadline',
                    value: _formatDateTime(
                      event.registrationDeadline!.toDate(),
                    ),
                  ),
                ],
                if (event.isOnline) ...[
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.video_call_rounded,
                    label: 'Type',
                    value: 'Online',
                  ),
                ],
                if (event.entryFee > 0) ...[
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.attach_money_rounded,
                    label: 'Entry Fee',
                    value: 'PKR ${event.entryFee}',
                  ),
                ],
                const SizedBox(height: 20),
                const Text('Description', style: AppTextStyles.title),
                const SizedBox(height: 8),
                Text(event.description ?? 'No description provided'),
                if (event.tags.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Tags', style: AppTextStyles.title),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: event.tags
                        .map(
                          (t) => Chip(
                            label: Text(t),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 24),
                regAsync.when(
                  loading: () => const AppLoadingState(
                    message: 'Loading registration status...',
                  ),
                  error: (error, _) => const SizedBox.shrink(),
                  data: (registration) {
                    final isRegistered = registration != null;
                    final isAttended =
                        registration?['attended'] as bool? ?? false;
                    if (!event.isOpenForRegistration) {
                      return _RegistrationUnavailable(event: event);
                    }
                    return Column(
                      children: [
                        if (isRegistered && !isAttended)
                          FilledButton.icon(
                            onPressed: event.canCancelRegistration
                                ? () =>
                                      _cancelRegistration(context, ref, eventId)
                                : null,
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancel Registration'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                          ),
                        if (!isRegistered)
                          FilledButton.icon(
                            onPressed: () =>
                                _registerForEvent(context, ref, eventId),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Register'),
                          ),
                        if (isAttended)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: AppColors.success,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'You have attended this event',
                                  style: TextStyle(color: AppColors.success),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _registerForEvent(
    BuildContext context,
    WidgetRef ref,
    String eventId,
  ) async {
    try {
      await ref.read(registerForEventUseCaseProvider)(eventId);
      ref.invalidate(eventRegistrationStatusProvider(eventId));
      ref.invalidate(eventDetailProvider(eventId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registered successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _cancelRegistration(
    BuildContext context,
    WidgetRef ref,
    String eventId,
  ) async {
    try {
      await ref.read(cancelEventRegistrationUseCaseProvider)(eventId);
      ref.invalidate(eventRegistrationStatusProvider(eventId));
      ref.invalidate(eventDetailProvider(eventId));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Registration cancelled')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Not specified';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _RegistrationUnavailable extends StatelessWidget {
  final Event event;

  const _RegistrationUnavailable({required this.event});

  @override
  Widget build(BuildContext context) {
    String reason;
    if (event.status == 'cancelled') {
      reason = 'This event has been cancelled.';
    } else if (event.status == 'completed') {
      reason = 'This event has concluded.';
    } else if (event.isFull) {
      reason =
          'This event is at full capacity (${event.maxParticipants} participants).';
    } else if (event.registrationDeadline != null &&
        event.registrationDeadline!.toDate().isBefore(DateTime.now())) {
      reason = 'The registration deadline has passed.';
    } else {
      reason = 'Registrations are not open for this event.';
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reason,
              style: TextStyle(color: AppColors.warning.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.accentBlue),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
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
    );
  }
}
