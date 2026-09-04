import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pynp_app/features/auth/domain/entities/app_user.dart';
import 'package:pynp_app/features/auth/domain/usecases/get_current_user.dart';
import 'package:pynp_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pynp_app/features/roles/presentation/screens/role_management_screen.dart';

class _MockGetCurrentUser extends Mock implements GetCurrentUser {}

void main() {
  group('RoleManagementScreen', () {
    final adminUser = AppUser(
      uid: 'uid-1',
      email: 'admin@test.com',
      role: UserRole.admin,
      roleName: 'national_admin',
    );

    testWidgets('shows loading indicator initially', (tester) async {
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
            usersProvider.overrideWith(
              (ref) async =>
                  await Completer<List<Map<String, dynamic>>>().future,
            ),
          ],
          child: MaterialApp(home: RoleManagementScreen()),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows app bar title Role Management', (tester) async {
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
            usersProvider.overrideWith(
              (ref) async =>
                  await Completer<List<Map<String, dynamic>>>().future,
            ),
          ],
          child: MaterialApp(home: RoleManagementScreen()),
        ),
      );
      expect(find.text('Role Management'), findsOneWidget);
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
          child: MaterialApp(home: RoleManagementScreen()),
        ),
      );
      expect(find.text('Administrator access required'), findsOneWidget);
    });

    testWidgets('shows user list when data loads', (tester) async {
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
            usersProvider.overrideWith(
              (ref) async => [
                {
                  'uid': '1',
                  'email': 'test@example.com',
                  'fullName': 'Test User',
                  'role': 'member',
                },
              ],
            ),
          ],
          child: MaterialApp(home: RoleManagementScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Test User'), findsOneWidget);
    });
  });
}
