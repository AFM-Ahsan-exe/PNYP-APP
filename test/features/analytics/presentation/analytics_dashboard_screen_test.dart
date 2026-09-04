import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pynp_app/features/analytics/presentation/screens/analytics_dashboard_screen.dart';

void main() {
  testWidgets('AnalyticsDashboardScreen shows loading indicator initially', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AnalyticsDashboardScreen())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AnalyticsDashboardScreen shows app bar title', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AnalyticsDashboardScreen())),
    );
    expect(find.text('Analytics Dashboard'), findsOneWidget);
  });
}
