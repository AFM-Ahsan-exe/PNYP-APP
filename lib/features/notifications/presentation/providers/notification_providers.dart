import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../features/notifications/domain/entities/notification.dart'
    as app_notification;
import '../../../../features/notifications/domain/repositories/notification_repository.dart';
import '../../../../features/notifications/domain/usecases/get_unread_notification_count.dart';
import '../../../../features/notifications/domain/usecases/get_user_notifications.dart';
import '../../../../features/notifications/domain/usecases/mark_all_notifications_as_read.dart';
import '../../../../features/notifications/domain/usecases/mark_notification_as_read.dart';
import '../../../../features/notifications/data/repositories/notification_repository_impl.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final getUserNotificationsProvider = Provider<GetUserNotifications>((ref) {
  return GetUserNotifications(
    ref.watch(notificationRepositoryProvider),
  );
});

final markNotificationAsReadProvider = Provider<MarkNotificationAsRead>((ref) {
  return MarkNotificationAsRead(
    ref.watch(notificationRepositoryProvider),
  );
});

final markAllNotificationsAsReadProvider =
    Provider<MarkAllNotificationsAsRead>((ref) {
  return MarkAllNotificationsAsRead(
    ref.watch(notificationRepositoryProvider),
  );
});

final getUnreadNotificationCountProvider =
    Provider<GetUnreadNotificationCount>((ref) {
  return GetUnreadNotificationCount(
    ref.watch(notificationRepositoryProvider),
  );
});

final notificationsProvider =
    FutureProvider.autoDispose<List<app_notification.Notification>>((ref) {
  return ref.watch(getUserNotificationsProvider)();
});

final unreadNotificationCountProvider =
    FutureProvider.autoDispose<int>((ref) {
  return ref.watch(getUnreadNotificationCountProvider)();
});

final unreadNotificationCountStreamProvider =
    StreamProvider.autoDispose<int>((ref) {
  return ref
      .watch(notificationRepositoryProvider)
      .watchUnreadCount();
});

final notificationsStreamProvider =
    StreamProvider.autoDispose<List<app_notification.Notification>>((ref) {
  return ref
      .watch(notificationRepositoryProvider)
      .watchUserNotifications();
});

final notificationDetailProvider = FutureProvider.autoDispose
    .family<app_notification.Notification?, String>(
  (ref, notificationId) async {
    final repo = ref.watch(notificationRepositoryProvider);

    return repo.getNotificationById(notificationId);
  },
);