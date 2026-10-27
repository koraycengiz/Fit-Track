import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/widgets/dashboard_metric_card.dart';

void main() {
  Widget createTestApp({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 180,
            height: 130,
            child: DashboardMetricCard(label: label, value: value, icon: icon),
          ),
        ),
      ),
    );
  }

  testWidgets('displays metric label and value', (tester) async {
    await tester.pumpWidget(
      createTestApp(
        label: 'Weight',
        value: '70.5 kg',
        icon: Icons.monitor_weight_outlined,
      ),
    );

    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('70.5 kg'), findsOneWidget);
  });

  testWidgets('displays the supplied metric icon', (tester) async {
    await tester.pumpWidget(
      createTestApp(
        label: 'Calories',
        value: '2400 kcal',
        icon: Icons.local_fire_department_outlined,
      ),
    );

    expect(find.byIcon(Icons.local_fire_department_outlined), findsOneWidget);
  });

  testWidgets('displays missing data placeholder', (tester) async {
    await tester.pumpWidget(
      createTestApp(
        label: 'Protein',
        value: 'No data',
        icon: Icons.fitness_center_outlined,
      ),
    );

    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('No data'), findsOneWidget);
  });

  testWidgets('displays step count correctly', (tester) async {
    await tester.pumpWidget(
      createTestApp(
        label: 'Steps',
        value: '12356',
        icon: Icons.directions_walk_outlined,
      ),
    );

    expect(find.text('Steps'), findsOneWidget);
    expect(find.text('12356'), findsOneWidget);
  });
}
