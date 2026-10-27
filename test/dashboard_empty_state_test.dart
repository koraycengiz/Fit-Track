import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/widgets/dashboard_empty_state.dart';

void main() {
  Widget createTestApp(VoidCallback onAddEntry) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: DashboardEmptyState(onAddEntry: onAddEntry)),
      ),
    );
  }

  testWidgets('displays welcome message', (tester) async {
    await tester.pumpWidget(createTestApp(() {}));

    expect(find.text('Welcome to FitTrack!'), findsOneWidget);
    expect(
      find.text(
        'Start tracking your fitness journey by adding '
        'your first daily entry.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('displays add first entry button', (tester) async {
    await tester.pumpWidget(createTestApp(() {}));

    expect(
      find.widgetWithText(FilledButton, 'Add Your First Entry'),
      findsOneWidget,
    );
  });

  testWidgets('calls callback when add button is tapped', (tester) async {
    var wasTapped = false;

    await tester.pumpWidget(
      createTestApp(() {
        wasTapped = true;
      }),
    );

    await tester.tap(find.text('Add Your First Entry'));

    expect(wasTapped, isTrue);
  });

  testWidgets('does not call callback before interaction', (tester) async {
    var callCount = 0;

    await tester.pumpWidget(
      createTestApp(() {
        callCount++;
      }),
    );

    expect(callCount, 0);
  });
}
