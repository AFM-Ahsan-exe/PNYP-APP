import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('events')
      .orderBy('startDateTime', descending: false)
      .limit(50)
      .get();
  return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
});

final eventDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, eventId) async {
  final doc = await FirebaseFirestore.instance.collection('events').doc(eventId).get();
  if (!doc.exists) return {};
  return {'id': doc.id, ...doc.data()!};
});

final eventRegistrationStatusProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, eventId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  final doc = await FirebaseFirestore.instance.collection('event_registrations').doc('${eventId}_${user.uid}').get();
  if (!doc.exists) return null;
  return {'id': doc.id, ...doc.data()!};
});
