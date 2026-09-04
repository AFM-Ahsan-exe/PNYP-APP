import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pynp_app/features/search/presentation/screens/search_screen.dart';

void main() {
  group('SearchScreen', () {
    testWidgets('shows search hint initially', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: SearchScreen())),
      );
      expect(
        find.text('Search for events, news, and opportunities'),
        findsOneWidget,
      );
    });

    testWidgets('typing in search field triggers state change', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: SearchScreen())),
      );

      await tester.enterText(find.byType(TextField), 'test query');
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text('Search for events, news, and opportunities'),
        findsNothing,
      );
    });

    testWidgets('clear button appears when query is not empty', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: SearchScreen())),
      );

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byIcon(Icons.clear_rounded), findsOneWidget);
    });
  });
}
