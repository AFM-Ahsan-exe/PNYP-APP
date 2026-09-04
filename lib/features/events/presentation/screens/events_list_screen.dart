import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/event.dart';
import '../providers/events_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_status_chip.dart';

class EventsListScreen extends ConsumerWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
            tooltip: 'Search',
          ),
        ],
      ),
      body: events.when(
        loading: () => const AppLoadingState(message: 'Loading events...'),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(eventsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(message: 'No events scheduled');
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(eventsStreamProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _EventTile(event: items[index]),
            ),
          );
        },
      ),
      floatingActionButton: Builder(
        builder: (context) {
          final authState = ref.watch(authControllerProvider);
          if (authState.user?.hasAtLeastRole('district_coordinator') ?? false) {
            return FloatingActionButton.extended(
              onPressed: () => context.push('/events/new'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Event'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final Event event;

  const _EventTile({required this.event});

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'upcoming':
        return 'Upcoming';
      case 'ongoing':
        return 'Ongoing';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final startDate = event.startDateTime?.toDate() ?? DateTime.now();
    final status = event.status ?? 'upcoming';

    return Card(
      child: InkWell(
        onTap: () => context.push('/events/${event.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Semantics(
          label:
              '${event.title}, ${_statusLabel(status)}, ${event.eventType}, ${_formatDate(startDate)}',
          button: true,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.navyDeep.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.event_rounded,
                    color: AppColors.navyDeep,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${event.eventType} • ${_formatDate(startDate)} ${event.isOnline ? "Online" : " ${event.location ?? ''}"}',
                        style: AppTextStyles.listSubtitle,
                      ),
                    ],
                  ),
                ),
                StatusChip(label: _statusLabel(status), compact: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}