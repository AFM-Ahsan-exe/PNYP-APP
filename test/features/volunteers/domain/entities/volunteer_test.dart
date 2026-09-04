import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pynp_app/features/volunteers/domain/entities/volunteer.dart';

void main() {
  group('Volunteer', () {
    test('creates with required fields', () {
      final volunteer = Volunteer(
        id: 'vol-1',
        userId: 'user-1',
        opportunityId: 'opp-1',
        motivation: 'I want to help',
        availability: 'Weekends',
        skills: const ['communication'],
        status: 'pending',
        appliedAt: Timestamp.now(),
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
      expect(volunteer.id, 'vol-1');
      expect(volunteer.userId, 'user-1');
      expect(volunteer.opportunityId, 'opp-1');
      expect(volunteer.status, 'pending');
      expect(volunteer.skills, ['communication']);
    });

    test('defaults for optional fields', () {
      final volunteer = Volunteer(
        id: 'vol-1',
        userId: 'user-1',
        opportunityId: 'opp-1',
        motivation: 'Help',
        availability: 'Evenings',
        skills: const <String>[],
        status: 'pending',
        appliedAt: Timestamp.now(),
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
      expect(volunteer.reviewNotes, isNull);
      expect(volunteer.reviewedBy, isNull);
      expect(volunteer.reviewedAt, isNull);
      expect(volunteer.skills, isEmpty);
    });
  });
}
