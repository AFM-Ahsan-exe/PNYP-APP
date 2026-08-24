import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final opportunitiesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('opportunities')
      .where('status', isEqualTo: 'active')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .get();
  return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
});

final opportunityDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, opportunityId) async {
  final doc = await FirebaseFirestore.instance.collection('opportunities').doc(opportunityId).get();
  if (!doc.exists) return {};
  return {'id': doc.id, ...doc.data()!};
});
