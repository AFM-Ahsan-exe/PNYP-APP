import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/activity_item.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../../../core/network/cloud_functions_client.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final FirebaseFirestore _firestore;

  const DashboardRepositoryImpl(this._firestore);

  static const String usersCollection = 'users';
  static const String activityCollection = 'activity_logs';
  static const String volunteersCollection = 'volunteers';
  static const String opportunitiesCollection = 'opportunities';

  Future<Map<String, dynamic>?> _callFunction(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated user');
    final idToken = await user.getIdToken();
    debugPrint(
      '[DASHBOARD] Calling CF $functionName for uid=${user.uid}',
    );
    final client = CloudFunctionsClient(
      projectId: Firebase.app().options.projectId,
      region: 'us-central1',
    );
    return client.call(functionName, data, idToken);
  }

  @override
  Future<DashboardStats> getStats() async {
    final result = await _callFunction('getDashboardStats', {});
    return DashboardStats(
      totalMembers: (result?['totalMembers'] as int?) ?? 0,
      totalVolunteers: (result?['totalVolunteers'] as int?) ?? 0,
      totalCoordinators: (result?['totalCoordinators'] as int?) ?? 0,
      pendingApplications: (result?['pendingApplications'] as int?) ?? 0,
      activeOpportunities: (result?['activeOpportunities'] as int?) ?? 0,
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
      debugPrint('[DASHBOARD] Firestore error loading activity: ${error.code} - ${error.message}');
      if (error.code == 'permission-denied' ||
          error.code == 'not-found' ||
          error.code == 'failed-precondition') {
        return const [];
      }
      rethrow;
    } catch (error) {
      debugPrint('[DASHBOARD] Unexpected error loading activity: $error');
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
