enum ActivityType { member, volunteer, coordinator, application, opportunity, general }

/// A single entry in the admin "recent activity" feed.
class ActivityItem {
  final String id;
  final String title;
  final String? subtitle;
  final DateTime timestamp;
  final ActivityType type;

  const ActivityItem({
    required this.id,
    required this.title,
    required this.timestamp,
    this.subtitle,
    this.type = ActivityType.general,
  });
}
