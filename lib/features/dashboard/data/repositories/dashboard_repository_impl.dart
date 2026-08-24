import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/activity_item.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';

/// Firestore-backed implementation of [DashboardRepository].
///
/// IMPORTANT (flagged, not guessed silently): no members/volunteers/
/// coordinators/applications/opportunities Dart entities or Firestore
/// collections existed in the uploaded project, so the collection/field
/// names below are best-guess conventions, centralized here as constants.
/// If your real Firestore schema uses different names, update only the
/// constants below — nothing else in the app needs to change.
class DashboardRepositoryImpl implements DashboardRepository {
  final FirebaseFirestore _firestore;

  const DashboardRepositoryImpl(this._firestore);

  static const String usersCollection = 'users';
  static const String activityCollection = 'activity_logs';

  Future<int> _count(Query<Map<String, dynamic>> query) async {
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  @override
  Future<DashboardStats> getStats() async {
    // Count-aggregate queries only transfer a number, not documents -
    // this keeps Firestore reads/costs minimal for a dashboard that may
    // be opened frequently.
    final results = await Future.wait<int>([
      _count(
        _firestore
            .collection(usersCollection)
            .where('role', isEqualTo: 'member')
            .where('status', isEqualTo: 'approved'),
      ),
      Future.value(0),
      Future.value(0),
      _count(
        _firestore
            .collection(usersCollection)
            .where('role', isEqualTo: 'member')
            .where('status', isEqualTo: 'pending'),
      ),
      Future.value(0),
    ]);

    return DashboardStats(
      totalMembers: results[0],
      totalVolunteers: results[1],
      totalCoordinators: results[2],
      pendingApplications: results[3],
      activeOpportunities: results[4],
    );
  }

  @override
  Future<List<ActivityItem>> getRecentActivity({int limit = 10}) async {
    QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _firestore
          .collection(activityCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied' || error.code == 'not-found') {
        return const [];
      }
      rethrow;
    }

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final rawTimestamp = data['timestamp'];
      return ActivityItem(
        id: doc.id,
        title: (data['title'] as String?) ?? 'Activity',
        subtitle: data['subtitle'] as String?,
        timestamp: rawTimestamp is Timestamp
            ? rawTimestamp.toDate()
            : DateTime.now(),
        type: _parseType(data['type'] as String?),
      );
    }).toList();
  }

  ActivityType _parseType(String? raw) {
    switch (raw) {
      case 'member':
        return ActivityType.member;
      case 'volunteer':
        return ActivityType.volunteer;
      case 'coordinator':
        return ActivityType.coordinator;
      case 'application':
        return ActivityType.application;
      case 'opportunity':
        return ActivityType.opportunity;
      default:
        return ActivityType.general;
    }
  }
}
