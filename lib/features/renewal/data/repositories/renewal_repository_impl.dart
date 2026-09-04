import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/renewal_request.dart';
import '../../domain/repositories/renewal_repository.dart';
import '../../../../core/network/cloud_functions_client.dart';

class RenewalRepositoryImpl implements RenewalRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  RenewalRepositoryImpl(
    this._firestore,
    this._auth,
  );

  Future<Map<String, dynamic>?> _callFunction(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No authenticated user');
    final idToken = await user.getIdToken();
    debugPrint(
      '[RENEWALS] Calling CF $functionName for uid=${user.uid} data=$data',
    );
    final client = CloudFunctionsClient(
      projectId: Firebase.app().options.projectId,
      region: 'us-central1',
    );
    return client.call(functionName, data, idToken);
  }

  @override
  Future<void> submitRenewal({
    required String userId,
    required String membershipType,
    required String paymentProofUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != userId) {
      throw StateError('Unauthorized renewal submission');
    }

    await _callFunction('submitRenewal', {
      'membershipType': membershipType,
      'paymentProofUrl': paymentProofUrl,
    });
  }

  @override
  Future<List<RenewalRequest>> getPendingRenewals() async {
    final result = await _callFunction('getPendingMembers', {
      'status': 'pending',
    });
    final members = result?['members'] as List<dynamic>? ?? [];
    return members.map((m) {
      final data = m as Map<String, dynamic>;
      return RenewalRequest(
        uid: data['id'] as String? ?? '',
        membershipType: data['membershipType'] as String? ?? 'youth_mpa',
        paymentProofUrl: data['paymentProofUrl'] as String? ?? '',
        submittedAt: data['updatedAt'] is Timestamp
            ? (data['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
        status: data['status'] as String? ?? 'pending',
      );
    }).toList();
  }

  @override
  Future<void> approveRenewal(String userId, {String? membershipType}) async {
    final adminUid = _auth.currentUser?.uid;
    if (adminUid == null) throw StateError('No authenticated user');
    if (adminUid == userId) {
      throw StateError('You cannot approve your own renewal');
    }

    // approveMember (functions/src/admin.ts) reads `uid`, not `userId`.
    final data = <String, dynamic>{'uid': userId, 'status': 'approved'};
    if (membershipType != null) data['membershipType'] = membershipType;
    await _callFunction('approveMember', data);
  }

  @override
  Future<void> rejectRenewal(String userId, {String? reason}) async {
    final adminUid = _auth.currentUser?.uid;
    if (adminUid == null) throw StateError('No authenticated user');
    if (adminUid == userId) {
      throw StateError('You cannot reject your own renewal');
    }

    // rejectMember (functions/src/admin.ts) reads `uid`, not `userId`.
    final data = <String, dynamic>{'uid': userId, 'status': 'rejected'};
    if (reason != null && reason.trim().isNotEmpty) {
      data['reason'] = reason.trim();
    }
    await _callFunction('rejectMember', data);
  }
}