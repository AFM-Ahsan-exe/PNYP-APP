import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pynp_app/features/activity/presentation/screens/user_activity_screen.dart';

void main() {
  group('UserActivityScreen', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final controller = StreamController<List<Map<String, dynamic>>>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userActivityProvider.overrideWith((ref) => controller.stream),
          ],
          child: const MaterialApp(home: UserActivityScreen()),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await controller.close();
    });

    testWidgets('shows app bar title Activity Log', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userActivityProvider.overrideWith(
              (ref) => Stream.value(<Map<String, dynamic>>[]),
            ),
          ],
          child: const MaterialApp(home: UserActivityScreen()),
        ),
      );
      expect(find.text('Activity Log'), findsOneWidget);
    });

    testWidgets('shows No activity yet when empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userActivityProvider.overrideWith(
              (ref) => Stream.value(<Map<String, dynamic>>[]),
            ),
          ],
          child: const MaterialApp(home: UserActivityScreen()),
        ),
      );
      await tester.pump();
      expect(find.text('No activity yet'), findsOneWidget);
    });

    testWidgets('tapping an activity item opens detail dialog', (tester) async {
      final activity = <String, dynamic>{
        'id': 'act-1',
        'action': 'login',
        'details': 'User logged in',
        'timestamp': DateTime.now(),
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userActivityProvider.overrideWith(
              (ref) => Stream.value([activity]),
            ),
          ],
          child: const MaterialApp(home: UserActivityScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Logged in'), findsOneWidget);

      await tester.tap(find.text('Logged in'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
    });
  });
}
