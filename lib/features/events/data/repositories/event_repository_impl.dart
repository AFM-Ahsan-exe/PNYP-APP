import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/network/cloud_functions_client.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';

class EventRepositoryImpl implements EventRepository {
  final FirebaseFirestore _firestore;
  final int _limit;

  EventRepositoryImpl(this._firestore, {int limit = 50}) : _limit = limit;

  Future<Map<String, dynamic>?> _callFunction(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated user');
    final idToken = await user.getIdToken();
    final client = CloudFunctionsClient(
      projectId: Firebase.app().options.projectId,
      region: 'us-central1',
    );
    return client.call(functionName, data, idToken);
  }

  @override
  Future<List<Event>> getEvents() async {
    final snapshot = await _firestore
        .collection('events')
        .orderBy('startDateTime', descending: false)
        .limit(_limit)
        .get();
    return snapshot.docs.map(Event.fromFirestore).toList();
  }
  @override
Stream<List<Event>> watchEvents() {
  return _firestore
      .collection('events')
      .orderBy('startDateTime', descending: false)
      .limit(_limit)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(Event.fromFirestore).toList(),
      );
}

  @override
  Future<Event?> getEventById(String eventId) async {
    final doc = await _firestore.collection('events').doc(eventId).get();
    if (!doc.exists) return null;
    return Event.fromFirestore(doc);
  }

  @override
  Future<List<Event>> searchEvents(String query) async {
    final lower = query.toLowerCase();
    final snapshot = await _firestore
        .collection('events')
        .orderBy('startDateTime', descending: false)
        .limit(_limit)
        .get();
    final results = <Event>[];
    for (final doc in snapshot.docs) {
      final event = Event.fromFirestore(doc);
      if (event.title.toLowerCase().contains(lower) ||
          (event.eventType.toLowerCase().contains(lower)) ||
          (event.location?.toLowerCase().contains(lower) ?? false)) {
        results.add(event);
      }
    }
    return results;
  }

  @override
  Future<EventPage> getEventsPage({
    int limit = 20,
    Timestamp? startAfter,
    String? category,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('events')
        .orderBy('startDateTime', descending: false);
    if (category != null && category.isNotEmpty) {
      query = query.where('eventType', isEqualTo: category);
    }
    if (startAfter != null) {
      query = query.startAfter([startAfter]);
    }
    final snapshot = await query.limit(limit).get();
    final events = snapshot.docs.map(Event.fromFirestore).toList();
    Timestamp? last;
    if (snapshot.docs.isNotEmpty) {
      last = snapshot.docs.last.data()['startDateTime'] as Timestamp?;
    }
    return EventPage(events: events, lastStartDateTime: last);
  }

  @override
  Future<String> createEvent(Map<String, dynamic> eventData) async {
    final result = await _callFunction('createEvent', eventData);
    return result?['eventId'] as String? ?? '';
  }

  @override
  Future<void> updateEvent(
    String eventId,
    Map<String, dynamic> eventData,
  ) async {
    await _callFunction('updateEvent', {'eventId': eventId, ...eventData});
  }

  @override
  Future<void> registerForEvent(String eventId) async {
    await _callFunction('registerForEvent', {'eventId': eventId});
  }

  @override
  Future<void> cancelEventRegistration(String eventId) async {
    await _callFunction('cancelEventRegistration', {'eventId': eventId});
  }

  @override
  Future<Map<String, dynamic>?> getRegistrationStatus(String eventId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await _firestore
        .collection('event_registrations')
        .doc('${eventId}_${user.uid}')
        .get();
    if (!doc.exists) return null;
    return doc.data();
  }

  @override
  Future<List<EventRegistration>> getEventRegistrations(String eventId) async {
    final snapshot = await _firestore
        .collection('event_registrations')
        .where('eventId', isEqualTo: eventId)
        .orderBy('registeredAt', descending: false)
        .get();

    // Best-effort enrichment with member names/emails. Only admins can read
    // other users' documents per Firestore rules; failures are non-fatal.
    final registrations = snapshot.docs
        .map(EventRegistration.fromFirestore)
        .toList();
    try {
      final userIds = registrations.map((r) => r.userId).toSet().toList();
      final users = <String, Map<String, dynamic>>{};
      for (var i = 0; i < userIds.length; i += 10) {
        final batch = userIds.skip(i).take(10).toList();
        final snap = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        for (final doc in snap.docs) {
          users[doc.id] = doc.data();
        }
      }
      return registrations
          .map(
            (r) => EventRegistration(
              id: r.id,
              eventId: r.eventId,
              userId: r.userId,
              userName: users[r.userId]?['fullName'] as String? ?? r.userName,
              userEmail: users[r.userId]?['email'] as String? ?? r.userEmail,
              registeredAt: r.registeredAt,
              attended: r.attended,
            ),
          )
          .toList();
    } catch (_) {
      return registrations;
    }
  }

  @override
  Future<void> markAttendance({
    required String registrationId,
    required bool attended,
  }) async {
    await _callFunction('markAttendance', {
      'registrationId': registrationId,
      'attended': attended,
    });
  }
}
