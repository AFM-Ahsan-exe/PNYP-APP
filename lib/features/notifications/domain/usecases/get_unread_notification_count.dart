import '../../domain/repositories/notification_repository.dart';

class GetUnreadNotificationCount {
  final NotificationRepository repository;

  GetUnreadNotificationCount(this.repository);

  Future<int> call() {
    return repository.getUnreadCount();
  }
}
