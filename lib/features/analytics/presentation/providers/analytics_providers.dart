import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/analytics_repository_impl.dart';
import '../../domain/entities/analytics_aggregate.dart';
import '../../domain/entities/analytics_stats.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../domain/usecases/get_analytics_aggregates.dart';
import '../../domain/usecases/get_analytics_stats.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl(ref.watch(firestoreProvider));
});

final getAnalyticsStatsProvider = Provider<GetAnalyticsStats>((ref) {
  return GetAnalyticsStats(ref.watch(analyticsRepositoryProvider));
});

final getAnalyticsAggregatesProvider = Provider<GetAnalyticsAggregates>((ref) {
  return GetAnalyticsAggregates(ref.watch(analyticsRepositoryProvider));
});

final analyticsStatsProvider = FutureProvider.autoDispose<AnalyticsStats>((
  ref,
) async {
  return ref.watch(getAnalyticsStatsProvider)();
});

final analyticsAggregatesProvider =
    FutureProvider.autoDispose<List<AnalyticsAggregate>>((ref) async {
      return ref.watch(getAnalyticsAggregatesProvider)();
    });
