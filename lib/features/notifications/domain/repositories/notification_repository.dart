import '../entities/notification.dart';

abstract class NotificationRepository {
  Future<List<Notification>> getUserNotifications({int limit = 50});
  Future<Notification?> getNotificationById(String id);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<int> getUnreadCount();
  Stream<int> watchUnreadCount();
  Stream<List<Notification>> watchUserNotifications({int limit = 50});
}