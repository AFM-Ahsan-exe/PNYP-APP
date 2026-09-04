import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/cloud_functions_client.dart';
import '../../domain/entities/volunteer.dart';
import '../../domain/repositories/volunteer_repository.dart';

class VolunteerRepositoryImpl implements VolunteerRepository {
  final FirebaseFirestore _firestore;

  VolunteerRepositoryImpl(this._firestore);

  Future<Map<String, dynamic>?> _callFunction(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated user');
    final idToken = await user.getIdToken();
    debugPrint(
      '[VOLUNTEERS] Calling CF $functionName for uid=${user.uid} data=$data',
    );
    final client = CloudFunctionsClient(
      projectId: Firebase.app().options.projectId,
      region: 'us-central1',
    );
    return client.call(functionName, data, idToken);
  }

  @override
  Future<List<Volunteer>> getMyApplications(String userId) async {
    final snapshot = await _firestore
        .collection('volunteers')
        .where('userId', isEqualTo: userId)
        .orderBy('appliedAt', descending: true)
        .limit(50)
        .get();
    return snapshot.docs.map(Volunteer.fromFirestore).toList();
  }

  @override
  Future<List<Volunteer>> getAllApplications({
    String? status,
    String? opportunityId,
  }) async {
    final result = await _callFunction('getVolunteerDirectory', {
      'status': ?status,
      'opportunityId': ?opportunityId,
    });
    final volunteers = result?['volunteers'] as List<dynamic>? ?? [];
    return volunteers.map((v) {
      final data = v as Map<String, dynamic>;
      return Volunteer(
        id: data['id'] as String? ?? '',
        userId: data['userId'] as String? ?? '',
        opportunityId: data['opportunityId'] as String? ?? '',
        motivation: data['motivation'] as String? ?? '',
        availability: data['availability'] as String? ?? '',
        skills:
            (data['skills'] as List<dynamic>?)?.cast<String>() ??
            const <String>[],
        status: data['status'] as String? ?? 'pending',
        appliedAt: _parseTimestamp(data['appliedAt']),
        reviewedAt: _parseTimestamp(data['reviewedAt']),
        reviewedBy: data['reviewedBy'] as String?,
        reviewNotes: data['reviewNotes'] as String?,
        createdAt: _parseTimestamp(data['createdAt']),
        updatedAt: _parseTimestamp(data['updatedAt']),
      );
    }).toList();
  }

  static Timestamp? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    if (value is Map<String, dynamic>) {
      final seconds = value['seconds'] as int?;
      final nanoseconds = value['nanoseconds'] as int?;
      if (seconds != null) {
        return Timestamp(seconds, nanoseconds ?? 0);
      }
    }
    return null;
  }

  @override
  Future<Volunteer> applyAsVolunteer({
    required String opportunityId,
    required String motivation,
    required String availability,
    required List<String> skills,
  }) async {
    final result = await _callFunction('applyAsVolunteer', {
      'opportunityId': opportunityId,
      'motivation': motivation,
      'availability': availability,
      'skills': skills,
    });
    final applicationId = result?['applicationId'] as String?;
    if (applicationId == null) throw StateError('Failed to submit application');
    final doc = await _firestore
        .collection('volunteers')
        .doc(applicationId)
        .get();
    if (!doc.exists) throw StateError('Failed to load application');
    return Volunteer.fromFirestore(doc);
  }

  @override
  Future<Volunteer> updateVolunteerStatus({
    required String applicationId,
    required String status,
    String? reviewNotes,
  }) async {
    await _callFunction('updateVolunteerStatus', {
      'applicationId': applicationId,
      'status': status,
      'reviewNotes': ?reviewNotes,
    });
    final doc = await _firestore
        .collection('volunteers')
        .doc(applicationId)
        .get();
    if (!doc.exists) throw StateError('Failed to load updated application');
    return Volunteer.fromFirestore(doc);
  }

  @override
  Future<void> withdrawApplication(String applicationId) async {
    await _callFunction('withdrawVolunteerApplication', {
      'applicationId': applicationId,
    });
  }
}
