import '../../domain/entities/notification.dart' as app_notification;
import '../../domain/repositories/notification_repository.dart';

class GetUserNotifications {
  final NotificationRepository repository;

  GetUserNotifications(this.repository);

  Future<List<app_notification.Notification>> call({int limit = 50}) {
    return repository.getUserNotifications(limit: limit);
  }
}
