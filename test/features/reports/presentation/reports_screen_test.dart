import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pynp_app/features/reports/presentation/screens/reports_screen.dart';

void main() {
  testWidgets('ReportsScreen shows app bar title', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ReportsScreen())),
    );
    expect(find.text('Reports'), findsOneWidget);
  });

  testWidgets('ReportsScreen shows report type dropdown', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ReportsScreen())),
    );
    expect(find.text('Report Type'), findsOneWidget);
  });
}
