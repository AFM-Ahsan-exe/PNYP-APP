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

    test('isAdmin returns true for districtCoordinator', () {
      final user = AppUser(
        uid: 'uid-123',
        role: UserRole.districtCoordinator,
        roleName: 'district_coordinator',
      );
      expect(user.isAdmin, isFalse);
    });

    test('isAdmin returns true for admin role', () {
      final user = AppUser(
        uid: 'uid-123',
        role: UserRole.admin,
        roleName: 'admin',
      );
      expect(user.isAdmin, isTrue);
    });

    test('isAdmin returns true for nationalAdmin, president, superAdmin', () {
      expect(AppUser(uid: '1', role: UserRole.nationalAdmin, roleName: 'national_admin').isAdmin, isTrue);
      expect(AppUser(uid: '2', role: UserRole.president, roleName: 'president').isAdmin, isTrue);
      expect(AppUser(uid: '3', role: UserRole.superAdmin, roleName: 'super_admin').isAdmin, isTrue);
    });

    test('isAdmin returns false for member', () {
      final user = AppUser(
        uid: 'uid-123',
        role: UserRole.member,
        roleName: 'member',
      );
      expect(user.isAdmin, isFalse);
    });

    test('copyWith updates specified fields', () {
      final user = AppUser(
        uid: 'uid-123',
        email: 'test@example.com',
        fullName: 'Test User',
      );
      final updated = user.copyWith(
        fullName: 'Updated Name',
        phone: '+923001234567',
      );
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

    group('hasAtLeastRole', () {
      test('member hasAtLeastRole member returns true', () {
        final user = AppUser(uid: 'uid-1', roleName: 'member');
        expect(user.hasAtLeastRole('member'), isTrue);
      });

      test('member hasAtLeastRole district_coordinator returns false', () {
        final user = AppUser(uid: 'uid-1', roleName: 'member');
        expect(user.hasAtLeastRole('district_coordinator'), isFalse);
      });

      test(
        'national_admin hasAtLeastRole regional_coordinator returns true',
        () {
          final user = AppUser(
            uid: 'uid-1',
            role: UserRole.nationalAdmin,
            roleName: 'national_admin',
          );
          expect(user.hasAtLeastRole('regional_coordinator'), isTrue);
        },
      );

      test('super_admin hasAtLeastRole super_admin returns true', () {
        final user = AppUser(
          uid: 'uid-1',
          role: UserRole.superAdmin,
          roleName: 'super_admin',
        );
        expect(user.hasAtLeastRole('super_admin'), isTrue);
      });

      test('super_admin hasAtLeastRole member returns true', () {
        final user = AppUser(uid: 'uid-1', roleName: 'super_admin');
        expect(user.hasAtLeastRole('member'), isTrue);
      });
    });
  });
}
