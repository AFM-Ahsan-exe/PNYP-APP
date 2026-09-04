import 'package:cloud_firestore/cloud_firestore.dart';

import '../entities/event.dart';

/// A page of events plus the cursor used to fetch the next page.
class EventPage {
  final List<Event> events;
  final Timestamp? lastStartDateTime;

  const EventPage({
    required this.events,
    this.lastStartDateTime,
  });

  bool get hasMore => events.isNotEmpty;
}

/// Registration record for an event participant.
class EventRegistration {
  final String id;
  final String eventId;
  final String userId;
  final String? userName;
  final String? userEmail;
  final Timestamp? registeredAt;
  final bool attended;

  const EventRegistration({
    required this.id,
    required this.eventId,
    required this.userId,
    this.userName,
    this.userEmail,
    this.registeredAt,
    this.attended = false,
  });

  factory EventRegistration.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return EventRegistration(
      id: doc.id,
      eventId: data['eventId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String?,
      userEmail: data['userEmail'] as String?,
      registeredAt: data['registeredAt'] as Timestamp?,
      attended: data['attended'] as bool? ?? false,
    );
  }
}

abstract class EventRepository {
  /// Returns the current list of events.
  Future<List<Event>> getEvents();

  /// Realtime stream of events.
  Stream<List<Event>> watchEvents();

  /// Returns one event by its ID.
  Future<Event?> getEventById(String eventId);

  /// Searches events.
  Future<List<Event>> searchEvents(String query);

  /// FR-035: paginated listing ordered by start date.
  Future<EventPage> getEventsPage({
    int limit = 20,
    Timestamp? startAfter,
    String? category,
  });

  /// Creates an event through Cloud Functions.
  Future<String> createEvent(
    Map<String, dynamic> eventData,
  );

  /// Updates an event through Cloud Functions.
  Future<void> updateEvent(
    String eventId,
    Map<String, dynamic> eventData,
  );

  /// Registers the current user for an event.
  Future<void> registerForEvent(String eventId);

  /// Cancels the current user's event registration.
  Future<void> cancelEventRegistration(String eventId);

  /// Returns the current user's registration for [eventId], or null.
  Future<Map<String, dynamic>?> getRegistrationStatus(
    String eventId,
  );

  /// Admin: returns all registrations for an event.
  Future<List<EventRegistration>> getEventRegistrations(
    String eventId,
  );

  /// Admin: mark/unmark attendance.
  Future<void> markAttendance({
    required String registrationId,
    required bool attended,
  });
}