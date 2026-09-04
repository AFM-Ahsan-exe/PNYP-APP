import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../features/notifications/domain/entities/notification.dart';
import '../../../../features/notifications/presentation/providers/notification_providers.dart';
import '../../../../core/widgets/app_loading_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../app/theme/app_text_styles.dart';

class NotificationDetailScreen extends ConsumerWidget {
  final String notificationId;

  const NotificationDetailScreen({super.key, required this.notificationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationAsync = ref.watch(
      notificationDetailProvider(notificationId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Notification')),
      body: notificationAsync.when(
        loading: () =>
            const AppLoadingState(message: 'Loading notification...'),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () =>
              ref.invalidate(notificationDetailProvider(notificationId)),
        ),
        data: (notification) {
          if (notification == null) {
            return const AppEmptyState(message: 'Notification not found');
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getIconForType(notification.type),
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                notification.title,
                                style: AppTextStyles.title.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          notification.body,
                          style: AppTextStyles.body.copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${notification.timestamp.day.toString().padLeft(2, '0')}/${notification.timestamp.month.toString().padLeft(2, '0')}/${notification.timestamp.year} ${notification.timestamp.hour.toString().padLeft(2, '0')}:${notification.timestamp.minute.toString().padLeft(2, '0')}',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: notification.isRead
                                ? AppColors.surfaceMuted
                                : AppColors.accentBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            notification.isRead ? 'Read' : 'Unread',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: notification.isRead
                                  ? AppColors.textSecondary
                                  : AppColors.accentBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.welcome:
        return Icons.waving_hand_rounded;
      case NotificationType.approval:
        return Icons.check_circle_rounded;
      case NotificationType.rejection:
        return Icons.cancel_rounded;
      case NotificationType.renewal:
        return Icons.refresh_rounded;
      case NotificationType.eventRegistration:
        return Icons.event_rounded;
      case NotificationType.attendanceMarked:
        return Icons.verified_rounded;
      case NotificationType.news:
        return Icons.article_rounded;
      case NotificationType.broadcast:
        return Icons.campaign_rounded;
      case NotificationType.payment:
        return Icons.payments_rounded;
      case NotificationType.document:
        return Icons.description_rounded;
      case NotificationType.opportunity:
        return Icons.work_outline_rounded;
      case NotificationType.volunteer:
        return Icons.volunteer_activism_rounded;
      case NotificationType.system:
        return Icons.settings_rounded;
    }
  }
}
