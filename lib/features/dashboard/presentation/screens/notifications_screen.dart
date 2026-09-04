import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../features/notifications/domain/entities/notification.dart'
    as app_notification;
import '../../../../features/notifications/presentation/providers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final unreadCountAsync = ref.watch(unreadNotificationCountStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          unreadCountAsync.when(
            data: (count) {
              if (count > 0) {
                return TextButton.icon(
                  onPressed: () async {
                    await ref.read(markAllNotificationsAsReadProvider)();
                  },
                  icon: const Icon(
                    Icons.done_all_rounded,
                    size: 18,
                  ),
                  label: Text('Mark all read ($count)'),
                );
              }

              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () =>
            const AppLoadingState(message: 'Loading notifications...'),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(notificationsStreamProvider);
            ref.invalidate(unreadNotificationCountStreamProvider);
          },
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              message: 'No notifications yet',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsStreamProvider);
              ref.invalidate(unreadNotificationCountStreamProvider);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = items[index];

                return _NotificationTile(
                  notification: notification,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final app_notification.Notification notification;

  const _NotificationTile({
    required this.notification,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRead = notification.isRead;

    return Card(
      color: isRead
          ? null
          : AppColors.navyDeep.withValues(alpha: 0.04),
      child: InkWell(
        onTap: () async {
          if (!isRead) {
            try {
              await ref
                  .read(markNotificationAsReadProvider)
                  .call(notification.id);
            } catch (error) {
              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to mark notification as read: $error',
                  ),
                ),
              );

              return;
            }
          }

          if (notification.actionRoute != null &&
              context.mounted) {
            context.push(notification.actionRoute!);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _getIconForType(notification.type),
                color: isRead
                    ? AppColors.textSecondary
                    : Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: isRead
                            ? FontWeight.normal
                            : FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.body,
                      style: AppTextStyles.listSubtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isRead) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.circle,
                  size: 8,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(
    app_notification.NotificationType type,
  ) {
    switch (type) {
      case app_notification.NotificationType.welcome:
        return Icons.waving_hand_rounded;

      case app_notification.NotificationType.approval:
        return Icons.check_circle_rounded;

      case app_notification.NotificationType.rejection:
        return Icons.cancel_rounded;

      case app_notification.NotificationType.renewal:
        return Icons.refresh_rounded;

      case app_notification.NotificationType.eventRegistration:
        return Icons.event_rounded;

      case app_notification.NotificationType.attendanceMarked:
        return Icons.verified_rounded;

      case app_notification.NotificationType.news:
        return Icons.article_rounded;

      case app_notification.NotificationType.broadcast:
        return Icons.campaign_rounded;

      case app_notification.NotificationType.payment:
        return Icons.payments_rounded;

      case app_notification.NotificationType.document:
        return Icons.description_rounded;

      case app_notification.NotificationType.opportunity:
        return Icons.work_outline_rounded;

      case app_notification.NotificationType.volunteer:
        return Icons.volunteer_activism_rounded;

      case app_notification.NotificationType.system:
        return Icons.settings_rounded;
    }
  }
}