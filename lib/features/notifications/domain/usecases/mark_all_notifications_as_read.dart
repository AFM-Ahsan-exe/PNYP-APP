import '../../domain/repositories/notification_repository.dart';

class MarkAllNotificationsAsRead {
  final NotificationRepository repository;

  MarkAllNotificationsAsRead(this.repository);

  Future<void> call() {
    return repository.markAllAsRead();
  }
}
