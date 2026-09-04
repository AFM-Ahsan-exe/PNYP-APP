import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/event_repository_impl.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/usecases/cancel_event_registration.dart';
import '../../domain/usecases/create_event.dart';
import '../../domain/usecases/get_event_detail.dart';
import '../../domain/usecases/get_event_registrations.dart';
import '../../domain/usecases/get_events.dart';
import '../../domain/usecases/get_registration_status.dart';
import '../../domain/usecases/mark_attendance.dart';
import '../../domain/usecases/register_for_event.dart';
import '../../domain/usecases/search_events.dart';
import '../../domain/usecases/update_event.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepositoryImpl(ref.watch(firestoreProvider));
});

final getEventsProvider = Provider<GetEvents>((ref) {
  return GetEvents(ref.watch(eventRepositoryProvider));
});

final getEventDetailProvider = Provider<GetEventDetail>((ref) {
  return GetEventDetail(ref.watch(eventRepositoryProvider));
});

final searchEventsProvider = Provider<SearchEvents>((ref) {
  return SearchEvents(ref.watch(eventRepositoryProvider));
});

final createEventUseCaseProvider = Provider<CreateEvent>((ref) {
  return CreateEvent(ref.watch(eventRepositoryProvider));
});

final updateEventUseCaseProvider = Provider<UpdateEvent>((ref) {
  return UpdateEvent(ref.watch(eventRepositoryProvider));
});

final registerForEventUseCaseProvider = Provider<RegisterForEvent>((ref) {
  return RegisterForEvent(ref.watch(eventRepositoryProvider));
});

final cancelEventRegistrationUseCaseProvider =
    Provider<CancelEventRegistration>((ref) {
      return CancelEventRegistration(ref.watch(eventRepositoryProvider));
    });

final getRegistrationStatusUseCaseProvider = Provider<GetRegistrationStatus>((
  ref,
) {
  return GetRegistrationStatus(ref.watch(eventRepositoryProvider));
});

final getEventRegistrationsUseCaseProvider = Provider<GetEventRegistrations>((
  ref,
) {
  return GetEventRegistrations(ref.watch(eventRepositoryProvider));
});

final markAttendanceUseCaseProvider = Provider<MarkAttendance>((ref) {
  return MarkAttendance(ref.watch(eventRepositoryProvider));
});

final eventsProvider = FutureProvider.autoDispose<List<Event>>((ref) async {
  return ref.watch(getEventsProvider)();
});
final eventsStreamProvider = StreamProvider.autoDispose<List<Event>>((ref) {
  return ref.watch(eventRepositoryProvider).watchEvents();
});
final eventDetailProvider = FutureProvider.autoDispose.family<Event?, String>((
  ref,
  eventId,
) async {
  return ref.watch(getEventDetailProvider)(eventId);
});

final eventSearchProvider = FutureProvider.autoDispose
    .family<List<Event>, String>((ref, query) async {
      return ref.watch(searchEventsProvider)(query);
    });

/// Current user's registration for an event (null when not registered).
final eventRegistrationStatusProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, eventId) async {
      return ref.watch(getRegistrationStatusUseCaseProvider)(eventId);
    });

/// Admin: registrations for an event (attendance marking).
final eventRegistrationsProvider = FutureProvider.autoDispose
    .family<List<EventRegistration>, String>((ref, eventId) async {
      return ref.watch(getEventRegistrationsUseCaseProvider)(eventId);
    });
