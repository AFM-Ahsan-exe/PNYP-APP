import 'package:flutter_test/flutter_test.dart';
import 'package:pynp_app/features/auth/domain/entities/app_user.dart';

void main() {
  group('AppUser', () {
    test('creates with required fields', () {
      final user = AppUser(uid: 'uid-123', email: 'test@example.com');
      expect(user.uid, 'uid-123');
      expect(user.email, 'test@example.com');
      expect(user.role, UserRole.member);
      expect(user.status, AccountStatus.pending);
      expect(user.isAdmin, isFalse);
    });

    test('isAdmin returns true for admin role', () {
      final user = AppUser(uid: 'uid-123', role: UserRole.admin);
      expect(user.isAdmin, isTrue);
    });

    test('copyWith updates specified fields', () {
      final user = AppUser(uid: 'uid-123', email: 'test@example.com', fullName: 'Test User');
      final updated = user.copyWith(fullName: 'Updated Name', phone: '+923001234567');
      expect(updated.fullName, 'Updated Name');
      expect(updated.phone, '+923001234567');
      expect(updated.uid, 'uid-123');
      expect(updated.email, 'test@example.com');
    });

    test('copyWith leaves unspecified fields unchanged', () {
      final user = AppUser(
        uid: 'uid-123',
        email: 'test@example.com',
        province: 'Punjab',
        skills: ['Flutter', 'Dart'],
      );
      final updated = user.copyWith(city: 'Lahore');
      expect(updated.city, 'Lahore');
      expect(updated.province, 'Punjab');
      expect(updated.skills, ['Flutter', 'Dart']);
    });
  });
}
