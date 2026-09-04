import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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
) async {
  try {
    return await ref.watch(getDashboardStatsProvider)();
  } on FirebaseException catch (e) {
    throw _mapFirebaseError(e.message ?? 'Failed to load statistics');
  } catch (e) {
    throw _mapUnexpectedError(e);
  }
});

// Recent activity feed.
final recentActivityProvider = FutureProvider.autoDispose<List<ActivityItem>>((
  ref,
) async {
  try {
    return await ref.watch(getRecentActivityProvider)(limit: 8);
  } on FirebaseException catch (e) {
    throw _mapFirebaseError(e.message ?? 'Failed to load recent activity');
  } catch (e) {
    throw _mapUnexpectedError(e);
  }
});

String _mapFirebaseError(String? raw) {
  if (raw == null || raw.isEmpty) {
    return 'Something went wrong. Please try again.';
  }
  final lower = raw.toLowerCase();
  if (lower.contains('permission-denied') ||
      lower.contains('unauthenticated')) {
    return 'You do not have permission to view this data.';
  }
  if (lower.contains('not-found') || lower.contains('no such document')) {
    return 'Some required data is missing.';
  }
  if (lower.contains('network') || lower.contains('timeout')) {
    return 'Network error. Check your connection and try again.';
  }
  if (lower.contains('cloud function') && lower.contains('not deployed')) {
    return 'Backend service is not available. Contact support.';
  }
  return 'Could not load data. Please try again.';
}

String _mapUnexpectedError(Object e) {
  final message = e.toString();
  if (message.contains('Cloud function') && message.contains('not deployed')) {
    return 'Backend service is not available. Contact support.';
  }
  if (message.contains('No authenticated user')) {
    return 'Your session has expired. Please sign in again.';
  }
  return 'Something went wrong. Please try again.';
}

final adminMemberRepositoryProvider = Provider<AdminMemberRepository>((ref) {
  return AdminMemberRepositoryImpl();
});

// Converted to .family, keyed by status: this used to be a plain provider
// that always called getMembers() with no argument, which defaults to
// status: 'pending' - meaning the screen's status filter dropdown
// (Pending/Approved/Rejected/All) only ever re-filtered an
// already-pending-only list on the client. Selecting "Approved" or
// "Rejected" always showed nothing (the fetched data never contained
// anything but pending members), and "All" never actually showed
// everything either. Watching this with the selected status now makes
// Riverpod fetch fresh from the backend for whichever status is chosen.
final pendingMembersProvider =
    FutureProvider.autoDispose.family<List<AdminMember>, String>((
  ref,
  status,
) async {
  final timer = Timer(const Duration(seconds: 15), () {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  try {
    // getMembers only applies a status filter when the string is
    // non-empty (see AdminMemberRepositoryImpl / getPendingMembers) - an
    // empty string means "no filter, return every status".
    return await ref
        .watch(adminMemberRepositoryProvider)
        .getMembers(status: status == 'all' ? '' : status);
  } on FirebaseException catch (e) {
    throw _mapFirebaseError(e.message ?? 'Failed to load members');
  } catch (e) {
    throw _mapUnexpectedError(e);
  }
});