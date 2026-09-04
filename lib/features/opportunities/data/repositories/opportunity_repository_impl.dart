import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/network/cloud_functions_client.dart';
import '../../domain/entities/opportunity.dart';
import '../../domain/repositories/opportunity_repository.dart';

class OpportunityRepositoryImpl implements OpportunityRepository {
  final FirebaseFirestore _firestore;
  final int _limit;

  OpportunityRepositoryImpl(
    this._firestore, {
    int limit = 50,
  }) : _limit = limit;

  Future<Map<String, dynamic>?> _callFunction(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('No authenticated user');
    }

    final idToken = await user.getIdToken();

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
  Future<List<Opportunity>> getActiveOpportunities() async {
    final snapshot = await _firestore
        .collection('opportunities')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(_limit)
        .get();

    return snapshot.docs
        .map(Opportunity.fromFirestore)
        .toList();
  }

  @override
  Stream<List<Opportunity>> watchActiveOpportunities() {
    return _firestore
        .collection('opportunities')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(_limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(Opportunity.fromFirestore)
              .toList(),
        );
  }

  @override
  Future<List<Opportunity>> getAllOpportunitiesForAdmin() async {
    final snapshot = await _firestore
        .collection('opportunities')
        .orderBy('createdAt', descending: true)
        .limit(_limit)
        .get();

    return snapshot.docs
        .map(Opportunity.fromFirestore)
        .toList();
  }

  @override
  Future<Opportunity?> getOpportunityById(
    String opportunityId,
  ) async {
    final doc = await _firestore
        .collection('opportunities')
        .doc(opportunityId)
        .get();

    if (!doc.exists) return null;

    return Opportunity.fromFirestore(doc);
  }

  @override
  Future<List<Opportunity>> searchOpportunities(
    String query,
  ) async {
    final lower = query.toLowerCase().trim();

    final snapshot = await _firestore
        .collection('opportunities')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(_limit)
        .get();

    final results = <Opportunity>[];

    for (final doc in snapshot.docs) {
      final opportunity = Opportunity.fromFirestore(doc);

      if (opportunity.title.toLowerCase().contains(lower) ||
          (opportunity.description?.toLowerCase().contains(lower) ??
              false) ||
          (opportunity.location?.toLowerCase().contains(lower) ??
              false)) {
        results.add(opportunity);
      }
    }

    return results;
  }

  @override
  Future<Opportunity> createOpportunity(
    Map<String, dynamic> data,
  ) async {
    final result = await _callFunction(
      'createOpportunity',
      data,
    );

    final opportunityId =
        result?['opportunityId'] as String?;

    if (opportunityId == null || opportunityId.isEmpty) {
      throw StateError(
        'Failed to create opportunity',
      );
    }

    final doc = await _firestore
        .collection('opportunities')
        .doc(opportunityId)
        .get();

    if (!doc.exists) {
      throw StateError(
        'Failed to load created opportunity',
      );
    }

    return Opportunity.fromFirestore(doc);
  }

  @override
  Future<Opportunity> updateOpportunity(
    String opportunityId,
    Map<String, dynamic> data,
  ) async {
    await _callFunction(
      'updateOpportunity',
      {
        ...data,
        'opportunityId': opportunityId,
      },
    );

    final doc = await _firestore
        .collection('opportunities')
        .doc(opportunityId)
        .get();

    if (!doc.exists) {
      throw StateError(
        'Failed to load updated opportunity',
      );
    }

    return Opportunity.fromFirestore(doc);
  }

  @override
  Future<void> deleteOpportunity(
    String opportunityId,
  ) async {
    await _callFunction(
      'deleteOpportunity',
      {
        'opportunityId': opportunityId,
      },
    );
  }
}