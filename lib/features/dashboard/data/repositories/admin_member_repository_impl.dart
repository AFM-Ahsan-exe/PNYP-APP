import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/cloud_functions_client.dart';
import '../../../../features/auth/domain/entities/app_user.dart';
import '../../domain/entities/admin_member.dart';
import '../../domain/repositories/admin_member_repository.dart';

class AdminMemberRepositoryImpl implements AdminMemberRepository {
  Future<Map<String, dynamic>?> _callFunction(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('No authenticated user');
    }

    final idToken = await user.getIdToken();

    if (idToken == null || idToken.isEmpty) {
      throw StateError('Unable to obtain Firebase ID token');
    }

    debugPrint(
      '[ADMIN_MEMBERS] Calling Cloud Function: $functionName '
      'uid=${user.uid}',
    );

    final client = CloudFunctionsClient(
      projectId: Firebase.app().options.projectId,
      region: 'us-central1',
    );

    return client.call(
      functionName,
      data,
      idToken,
    );
  }

  @override
  Future<List<AdminMember>> getMembers({
    String status = 'pending',
  }) async {
    final result = await _callFunction(
      'getPendingMembers',
      {
        if (status.isNotEmpty) 'status': status,
      },
    );

    final members = result?['members'] as List<dynamic>? ?? [];

    return members.map((member) {
      final data = Map<String, dynamic>.from(
        member as Map<dynamic, dynamic>,
      );

      final statusString =
          data['status'] as String? ?? 'pending';

      final roleString =
          data['role'] as String? ?? 'member';

      return AdminMember(
        uid: data['id'] as String? ??
            data['uid'] as String? ??
            '',
        name: data['fullName'] as String? ??
            data['name'] as String? ??
            '',
        email: data['email'] as String? ?? '',
        status: AccountStatus.values.firstWhere(
          (value) => value.name == statusString,
          orElse: () => AccountStatus.pending,
        ),
        role: roleString,
        createdAt: _parseTimestamp(data['createdAt']),
      );
    }).toList();
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Map) {
      final seconds = value['seconds'] as int?;
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    }
    return null;
  }

  @override
  Future<void> updateStatus(
    String uid,
    String status, {
    String? reason,
    String? membershipType,
  }) async {
    if (status != 'approved' && status != 'rejected') {
      throw ArgumentError(
        'Status must be either approved or rejected',
      );
    }

    final functionName =
        status == 'approved'
            ? 'approveMember'
            : 'rejectMember';

    final data = <String, dynamic>{
      'uid': uid,
      if (status == 'approved' && membershipType != null)
        'membershipType': membershipType,
      if (status == 'rejected' && reason != null)
        'reason': reason,
    };

    await _callFunction(
      functionName,
      data,
    );
  }

  @override
  Future<void> deleteUser(String uid) async {
    if (uid.trim().isEmpty) {
      throw ArgumentError('User UID cannot be empty');
    }

    debugPrint(
      '[ADMIN_MEMBERS] Deleting user uid=$uid',
    );

    await _callFunction(
      'deleteUser',
      {
        'uid': uid,
      },
    );

    debugPrint(
      '[ADMIN_MEMBERS] User deleted successfully uid=$uid',
    );
  }
}