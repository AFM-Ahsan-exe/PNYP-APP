import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/analytics_aggregate.dart';
import '../../domain/entities/analytics_stats.dart';
import '../../domain/repositories/analytics_repository.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final FirebaseFirestore _firestore;

  AnalyticsRepositoryImpl(this._firestore);

  Future<int> _count(Query<Map<String, dynamic>> query) async {
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  @override
  Future<AnalyticsStats> getStats() async {
    final results = await Future.wait<int>([
      _count(_firestore.collection('users')),
      _count(
        _firestore.collection('users').where('status', isEqualTo: 'approved'),
      ),
      _count(
        _firestore.collection('users').where('status', isEqualTo: 'pending'),
      ),
      _count(_firestore.collection('events')),
      _count(_firestore.collection('documents')),
      _count(_firestore.collection('news')),
      _count(_firestore.collection('volunteers')),
      _count(_firestore.collection('payments')),
    ]);

    return AnalyticsStats(
      totalUsers: results[0],
      approvedMembers: results[1],
      pendingMembers: results[2],
      totalEvents: results[3],
      totalDocuments: results[4],
      totalNews: results[5],
      totalVolunteers: results[6],
      totalPayments: results[7],
    );
  }

  @override
  Future<List<AnalyticsAggregate>> getAggregates({int limit = 30}) async {
    final snapshot = await _firestore
        .collection('analytics_aggregates')
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map(AnalyticsAggregate.fromFirestore).toList();
  }
}
