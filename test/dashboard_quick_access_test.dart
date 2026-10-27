import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/widgets/dashboard_quick_access.dart';

void main() {
  Widget createTestApp({
    required VoidCallback onHistory,
    required VoidCallback onAnalytics,
    required VoidCallback onGoals,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: DashboardQuickAccess(
          onHistory: onHistory,
          onAnalytics: onAnalytics,
          onGoals: onGoals,
          onBackup: () {},
        ),
      ),
    );
  }

  testWidgets('displays all three navigation shortcuts', (tester) async {
    await tester.pumpWidget(
      createTestApp(onHistory: () {}, onAnalytics: () {}, onGoals: () {}),
    );

    expect(find.text('Quick Access'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Goals'), findsOneWidget);
  });

  testWidgets('History shortcut calls its callback', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      createTestApp(
        onHistory: () => tapped = true,
        onAnalytics: () {},
        onGoals: () {},
      ),
    );

    await tester.tap(find.text('History'));

    expect(tapped, isTrue);
  });

  testWidgets('Analytics shortcut calls its callback', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      createTestApp(
        onHistory: () {},
        onAnalytics: () => tapped = true,
        onGoals: () {},
      ),
    );

    await tester.tap(find.text('Analytics'));

    expect(tapped, isTrue);
  });

  testWidgets('Goals shortcut calls its callback', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      createTestApp(
        onHistory: () {},
        onAnalytics: () {},
        onGoals: () => tapped = true,
      ),
    );

    await tester.tap(find.text('Goals'));

    expect(tapped, isTrue);
  });
}
