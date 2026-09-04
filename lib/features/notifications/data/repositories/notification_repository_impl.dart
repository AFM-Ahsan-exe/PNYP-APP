import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  NotificationRepositoryImpl(this._firestore, this._auth);

  @override
  Future<List<Notification>> getUserNotifications({int limit = 50}) async {
    final user = _auth.currentUser;

    if (user == null) {
      return [];
    }

    final snapshot = await _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => Notification.fromJson(doc.data(), docId: doc.id))
        .toList();
  }

  @override
  Future<Notification?> getNotificationById(String id) async {
    final doc = await _firestore.collection('notifications').doc(id).get();

    if (!doc.exists) {
      return null;
    }

    return Notification.fromJson(doc.data()!, docId: doc.id);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('No authenticated user');
    }

    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('No authenticated user');
    }

    final snapshot = await _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    final docs = snapshot.docs;

    if (docs.isEmpty) {
      return;
    }

    const batchSize = 500;

    for (var i = 0; i < docs.length; i += batchSize) {
      final batch = _firestore.batch();
      final chunk = docs.skip(i).take(batchSize);

      for (final doc in chunk) {
        batch.update(doc.reference, {
          'isRead': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    }
  }

  @override
  Future<int> getUnreadCount() async {
    final user = _auth.currentUser;

    if (user == null) {
      return 0;
    }

    final snapshot = await _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  @override
  Stream<int> watchUnreadCount() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(0);
    }

    // IMPORTANT:
    // count() returns AggregateQuery and AggregateQuery does not
    // support snapshots().
    //
    // For a realtime unread count, listen to the actual documents.
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Stream<List<Notification>> watchUserNotifications({int limit = 50}) {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(const <Notification>[]);
    }

    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Notification.fromJson(doc.data(), docId: doc.id))
              .toList(),
        );
  }
}
