import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/activity_item.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/usecases/get_dashboard_stats.dart';
import '../../domain/usecases/get_recent_activity.dart';
import '../../data/repositories/admin_member_repository_impl.dart';
import '../../domain/entities/admin_member.dart';
import '../../domain/repositories/admin_member_repository.dart';

// Firestore instance.
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Repository.
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(firestoreProvider));
});

// Use cases.
final getDashboardStatsProvider = Provider<GetDashboardStats>((ref) {
  return GetDashboardStats(ref.watch(dashboardRepositoryProvider));
});

final getRecentActivityProvider = Provider<GetRecentActivity>((ref) {
  return GetRecentActivity(ref.watch(dashboardRepositoryProvider));
});

// Stats - autoDispose so the dashboard doesn't keep polling/holding data
// once the admin navigates away.
final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((
  ref,
) {
  return ref.watch(getDashboardStatsProvider)();
});

// Recent activity feed.
final recentActivityProvider = FutureProvider.autoDispose<List<ActivityItem>>((
  ref,
) {
  return ref.watch(getRecentActivityProvider)(limit: 8);
});

final adminMemberRepositoryProvider = Provider<AdminMemberRepository>((ref) {
  return AdminMemberRepositoryImpl(FirebaseAuth.instance, http.Client());
});

final pendingMembersProvider = FutureProvider.autoDispose<List<AdminMember>>((
  ref,
) {
  return ref.watch(adminMemberRepositoryProvider).getMembers();
});
