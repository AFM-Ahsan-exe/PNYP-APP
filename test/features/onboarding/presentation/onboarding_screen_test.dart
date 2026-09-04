import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:pynp_app/features/auth/domain/entities/app_user.dart';
import 'package:pynp_app/features/auth/domain/usecases/get_current_user.dart';
import 'package:pynp_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pynp_app/features/onboarding/presentation/screens/onboarding_screen.dart';

class _MockFirebaseAuthPlatform extends FirebaseAuthPlatform {
  _MockFirebaseAuthPlatform() : super(appInstance: null);

  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseAuthPlatform setInitialValues({
    InternalUserDetails? currentUser,
    String? languageCode,
  }) => this;

  @override
  UserPlatform? get currentUser => null;

  @override
  Stream<UserPlatform?> authStateChanges() => const Stream.empty();

  @override
  Stream<UserPlatform?> idTokenChanges() => const Stream.empty();

  @override
  Stream<UserPlatform?> userChanges() => const Stream.empty();
}

class _MockFirebasePlatform extends FirebasePlatform {
  final FirebaseAppPlatform mockApp;

  _MockFirebasePlatform(this.mockApp);

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) => mockApp;

  @override
  List<FirebaseAppPlatform> get apps => [mockApp];
}

class _MockGetCurrentUser extends Mock implements GetCurrentUser {}

void main() {
  group('OnboardingScreen', () {
    final memberUser = AppUser(
      uid: 'uid-1',
      email: 'member@test.com',
      role: UserRole.member,
      roleName: 'member',
    );

    setUpAll(() {
      final mockApp = FirebaseAppPlatform(
        'test',
        const FirebaseOptions(
          apiKey: 'test-api-key',
          appId: 'test-app-id',
          messagingSenderId: 'test-sender-id',
          projectId: 'test-project',
        ),
      );
      final mockFirebasePlatform = _MockFirebasePlatform(mockApp);
      Firebase.delegatePackingProperty = mockFirebasePlatform;
      FirebaseAuthPlatform.instance = _MockFirebaseAuthPlatform();
    });

    testWidgets('shows first step initially', (tester) async {
      final mockGetCurrentUser = _MockGetCurrentUser();
      when(() => mockGetCurrentUser()).thenReturn(memberUser);
      when(
        () => mockGetCurrentUser.withRole(),
      ).thenAnswer((_) async => memberUser);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getCurrentUserUseCaseProvider.overrideWith(
              (ref) => mockGetCurrentUser,
            ),
          ],
          child: MaterialApp(home: OnboardingScreen()),
        ),
      );
      expect(find.text('Welcome to PYNP'), findsOneWidget);
    });

    testWidgets('tapping Continue advances to next step', (tester) async {
      final mockGetCurrentUser = _MockGetCurrentUser();
      when(() => mockGetCurrentUser()).thenReturn(memberUser);
      when(
        () => mockGetCurrentUser.withRole(),
      ).thenAnswer((_) async => memberUser);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getCurrentUserUseCaseProvider.overrideWith(
              (ref) => mockGetCurrentUser,
            ),
          ],
          child: MaterialApp(home: OnboardingScreen()),
        ),
      );
      expect(find.text('Welcome to PYNP'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Stay Updated'), findsOneWidget);
    });

    testWidgets('tapping Skip completes onboarding', (tester) async {
      final mockGetCurrentUser = _MockGetCurrentUser();
      when(() => mockGetCurrentUser()).thenReturn(memberUser);
      when(
        () => mockGetCurrentUser.withRole(),
      ).thenAnswer((_) async => memberUser);

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const OnboardingScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const Scaffold(body: Text('Home')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getCurrentUserUseCaseProvider.overrideWith(
              (ref) => mockGetCurrentUser,
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('Get Started button appears on last step', (tester) async {
      final mockGetCurrentUser = _MockGetCurrentUser();
      when(() => mockGetCurrentUser()).thenReturn(memberUser);
      when(
        () => mockGetCurrentUser.withRole(),
      ).thenAnswer((_) async => memberUser);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            getCurrentUserUseCaseProvider.overrideWith(
              (ref) => mockGetCurrentUser,
            ),
          ],
          child: MaterialApp(home: OnboardingScreen()),
        ),
      );

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Get Started'), findsOneWidget);
    });
  });
}
