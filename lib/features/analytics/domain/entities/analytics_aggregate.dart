import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsAggregate {
  final String id;
  final DateTime date;
  final int totalUsers;
  final int activeMembers;
  final int pendingMembers;
  final int totalEvents;
  final int totalVolunteers;
  final int totalPayments;
  final int totalDocuments;
  final int totalNews;

  const AnalyticsAggregate({
    required this.id,
    required this.date,
    required this.totalUsers,
    required this.activeMembers,
    required this.pendingMembers,
    required this.totalEvents,
    required this.totalVolunteers,
    required this.totalPayments,
    required this.totalDocuments,
    required this.totalNews,
  });

  factory AnalyticsAggregate.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final date = data['date'] is Timestamp
        ? (data['date'] as Timestamp).toDate()
        : DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now();
    return AnalyticsAggregate(
      id: doc.id,
      date: date,
      totalUsers: data['totalUsers'] as int? ?? 0,
      activeMembers: data['activeMembers'] as int? ?? 0,
      pendingMembers: data['pendingMembers'] as int? ?? 0,
      totalEvents: data['totalEvents'] as int? ?? 0,
      totalVolunteers: data['totalVolunteers'] as int? ?? 0,
      totalPayments: data['totalPayments'] as int? ?? 0,
      totalDocuments: data['totalDocuments'] as int? ?? 0,
      totalNews: data['totalNews'] as int? ?? 0,
    );
  }
}
