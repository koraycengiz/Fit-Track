import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack/models/daily_entry.dart';
import 'package:fittrack/screens/fitness_calendar_screen.dart';

void main() {
  final recordedDate = DateTime(2026, 10, 27);

  Future<List<DailyEntry>> loadSampleEntries() async {
    return [
      DailyEntry(
        date: recordedDate,
        weight: 70.5,
        calories: 2400,
        protein: 142,
        carbs: 286,
        fat: 84,
        steps: 12356,
        waist: 79,
        workout: 'Off day',
        notes: 'Simple walking day',
      ),
    ];
  }

  Future<void> openCalendar(
    WidgetTester tester, {
    Future<List<DailyEntry>> Function()? loader,
  }) async {
    // Use a realistic mobile-sized viewport.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: FitnessCalendarScreen(loadEntries: loader ?? loadSampleEntries),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> tapCalendarDay(WidgetTester tester, String dateKey) async {
    final dayFinder = find.byKey(Key('calendar_day_$dateKey'));

    // Scroll until the date is visible.
    await tester.ensureVisible(dayFinder);
    await tester.pumpAndSettle();

    await tester.tap(dayFinder);
    await tester.pumpAndSettle();
  }

  testWidgets('displays the calendar title', (tester) async {
    await openCalendar(tester);

    expect(find.text('Fitness Calendar'), findsOneWidget);
    expect(find.byKey(const Key('calendar_month_title')), findsOneWidget);
  });

  testWidgets('navigates between months', (tester) async {
    await openCalendar(tester);

    final initialTitle =
        tester.widget<Text>(find.byKey(const Key('calendar_month_title'))).data;

    await tester.tap(find.byKey(const Key('next_month')));
    await tester.pumpAndSettle();

    final nextTitle =
        tester.widget<Text>(find.byKey(const Key('calendar_month_title'))).data;

    expect(nextTitle, isNot(initialTitle));

    await tester.tap(find.byKey(const Key('previous_month')));
    await tester.pumpAndSettle();

    final restoredTitle =
        tester.widget<Text>(find.byKey(const Key('calendar_month_title'))).data;

    expect(restoredTitle, initialTitle);
  });

  testWidgets('selects a date and displays an empty state', (tester) async {
    await openCalendar(tester);

    // Navigate directly to October 2026 using the month controls.
    final current = DateTime.now();
    final difference = (2026 - current.year) * 12 + (10 - current.month);

    final navigationKey =
        difference >= 0 ? const Key('next_month') : const Key('previous_month');

    for (var i = 0; i < difference.abs(); i++) {
      await tester.tap(find.byKey(navigationKey));
      await tester.pumpAndSettle();
    }

    await tapCalendarDay(tester, '2026-10-28');
    await tester.pumpAndSettle();

    expect(find.text('No entry recorded for this date.'), findsOneWidget);
    expect(find.text('Add Entry'), findsOneWidget);
  });

  testWidgets('shows recorded fitness metrics', (tester) async {
    await openCalendar(tester);

    final current = DateTime.now();
    final difference = (2026 - current.year) * 12 + (10 - current.month);

    final navigationKey =
        difference >= 0 ? const Key('next_month') : const Key('previous_month');

    for (var i = 0; i < difference.abs(); i++) {
      await tester.tap(find.byKey(navigationKey));
      await tester.pumpAndSettle();
    }

    await tapCalendarDay(tester, '2026-10-27');
    await tester.pumpAndSettle();

    expect(find.text('70.5 kg'), findsOneWidget);
    expect(find.text('2400 kcal'), findsOneWidget);
    expect(find.text('142 g'), findsOneWidget);
    expect(find.text('Edit Entry'), findsOneWidget);
  });

  testWidgets('shows an indicator for a recorded date', (tester) async {
    await openCalendar(tester);

    final current = DateTime.now();
    final difference = (2026 - current.year) * 12 + (10 - current.month);

    final navigationKey =
        difference >= 0 ? const Key('next_month') : const Key('previous_month');

    for (var i = 0; i < difference.abs(); i++) {
      await tester.tap(find.byKey(navigationKey));
      await tester.pumpAndSettle();
    }

    expect(find.byKey(const Key('entry_indicator_2026-10-27')), findsOneWidget);
  });

  testWidgets('displays an error when loading fails', (tester) async {
    Future<List<DailyEntry>> failingLoader() async {
      throw Exception('Database unavailable');
    }

    await openCalendar(tester, loader: failingLoader);

    expect(find.textContaining('Failed to load calendar'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
