import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  welcome,
  approval,
  rejection,
  renewal,
  eventRegistration,
  attendanceMarked,
  news,
  broadcast,
  payment,
  document,
  opportunity,
  volunteer,
  system;

  String get displayName {
    switch (this) {
      case NotificationType.welcome:
        return 'Welcome';
      case NotificationType.approval:
        return 'Approval';
      case NotificationType.rejection:
        return 'Rejection';
      case NotificationType.renewal:
        return 'Renewal';
      case NotificationType.eventRegistration:
        return 'Event Registration';
      case NotificationType.attendanceMarked:
        return 'Attendance';
      case NotificationType.news:
        return 'News';
      case NotificationType.broadcast:
        return 'Broadcast';
      case NotificationType.payment:
        return 'Payment';
      case NotificationType.document:
        return 'Document';
      case NotificationType.opportunity:
        return 'Opportunity';
      case NotificationType.volunteer:
        return 'Volunteer';
      case NotificationType.system:
        return 'System';
    }
  }
}

enum NotificationCategory {
  events,
  news,
  documents,
  opportunities,
  volunteers,
  payments,
  system;

  String get displayName {
    switch (this) {
      case NotificationCategory.events:
        return 'Events';
      case NotificationCategory.news:
        return 'News & Announcements';
      case NotificationCategory.documents:
        return 'Documents';
      case NotificationCategory.opportunities:
        return 'Opportunities';
      case NotificationCategory.volunteers:
        return 'Volunteer Activities';
      case NotificationCategory.payments:
        return 'Payment Receipts';
      case NotificationCategory.system:
        return 'System';
    }
  }
}

class Notification {
  final String id;
  final String recipientId;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationCategory category;
  final bool isRead;
  final DateTime timestamp;
  final String? actionRoute;
  final Map<String, dynamic>? metadata;

  const Notification({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.body,
    required this.type,
    required this.category,
    required this.isRead,
    required this.timestamp,
    this.actionRoute,
    this.metadata,
  });

  factory Notification.fromJson(Map<String, dynamic> json, {String? docId}) {
    final typeStr = json['type'] as String? ?? 'system';
    final categoryStr = json['category'] as String? ?? 'system';
    return Notification(
      id: docId ?? json['id'] as String? ?? '',
      recipientId: json['recipientId'] as String? ?? '',
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => NotificationType.system,
      ),
      category: NotificationCategory.values.firstWhere(
        (e) => e.name == categoryStr,
        orElse: () => NotificationCategory.system,
      ),
      isRead: json['isRead'] as bool? ?? false,
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
                DateTime.now(),
      actionRoute: json['actionRoute'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipientId': recipientId,
      'title': title,
      'body': body,
      'type': type.name,
      'category': category.name,
      'isRead': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
      'actionRoute': actionRoute,
      'metadata': metadata,
    };
  }

  Notification copyWith({
    String? id,
    String? recipientId,
    String? title,
    String? body,
    NotificationType? type,
    NotificationCategory? category,
    bool? isRead,
    DateTime? timestamp,
    String? actionRoute,
    Map<String, dynamic>? metadata,
  }) {
    return Notification(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
      actionRoute: actionRoute ?? this.actionRoute,
      metadata: metadata ?? this.metadata,
    );
  }
}
