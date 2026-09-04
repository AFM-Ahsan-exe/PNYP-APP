import '../../domain/repositories/event_repository.dart';

class MarkAttendance {
  final EventRepository repository;
  MarkAttendance(this.repository);

  Future<void> call({required String registrationId, required bool attended}) =>
      repository.markAttendance(
        registrationId: registrationId,
        attended: attended,
      );
}
