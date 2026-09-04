import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pynp_app/features/auth/domain/entities/app_user.dart';
import 'package:pynp_app/features/auth/domain/usecases/get_current_user.dart';
import 'package:pynp_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pynp_app/features/audit/presentation/screens/audit_log_screen.dart';

class _MockGetCurrentUser extends Mock implements GetCurrentUser {}

void main() {
  group('AuditLogScreen', () {
    final adminUser = AppUser(
      uid: 'uid-1',
      email: 'admin@test.com',
      role: UserRole.admin,
      roleName: 'national_admin',
    );

    testWidgets('shows prompt to load logs initially', (tester) async {
      final mockGetCurrentUser = _MockGetCurrentUser();
      when(() => mockGetCurrentUser()).thenReturn(adminUser);
      when(
        () => mockGetCurrentUser.withRole(),
      ).thenAnswer((_) async => adminUser);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getCurrentUserUseCaseProvider.overrideWith(
              (ref) => mockGetCurrentUser,
            ),
          ],
          child: MaterialApp(home: AuditLogScreen()),
        ),
      );
      expect(find.text('Apply filters to load audit logs'), findsOneWidget);
    });

    testWidgets('shows app bar title Audit Logs', (tester) async {
      final mockGetCurrentUser = _MockGetCurrentUser();
      when(() => mockGetCurrentUser()).thenReturn(adminUser);
      when(
        () => mockGetCurrentUser.withRole(),
      ).thenAnswer((_) async => adminUser);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getCurrentUserUseCaseProvider.overrideWith(
              (ref) => mockGetCurrentUser,
            ),
          ],
          child: MaterialApp(home: AuditLogScreen()),
        ),
      );
      expect(find.text('Audit Logs'), findsOneWidget);
    });

    testWidgets('shows admin access required message for non-admin', (
      tester,
    ) async {
      final mockGetCurrentUser = _MockGetCurrentUser();
      when(() => mockGetCurrentUser()).thenReturn(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getCurrentUserUseCaseProvider.overrideWith(
              (ref) => mockGetCurrentUser,
            ),
          ],
          child: MaterialApp(home: AuditLogScreen()),
        ),
      );
      expect(find.text('Administrator access required'), findsOneWidget);
    });
  });
}
