
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/main.dart';

void main() {
  testWidgets('FitTrack dashboard displays correctly',
          (WidgetTester tester) async {
        await tester.pumpWidget(const FitTrackApp());

        expect(find.text('FitTrack'), findsOneWidget);
        expect(find.text('Your Fitness Dashboard'), findsOneWidget);
        expect(find.text('Weight'), findsOneWidget);
        expect(find.text('Calories'), findsOneWidget);
        expect(find.text('Steps'), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });
}
