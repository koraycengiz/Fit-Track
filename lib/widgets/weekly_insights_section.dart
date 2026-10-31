import 'package:flutter/material.dart';

import '../models/weekly_insights.dart';

class WeeklyInsightsSection extends StatelessWidget {
  final WeeklyInsights insights;
  final VoidCallback onPreviousWeek;
  final VoidCallback? onNextWeek;

  const WeeklyInsightsSection({
    super.key,
    required this.insights,
    required this.onPreviousWeek,
    required this.onNextWeek,
  });

  String _dateLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}';
  }

  String _average(double? value, String unit) {
    if (value == null) return 'No data';
    return '${value.toStringAsFixed(1)} $unit';
  }

  String _weightChange(double? value) {
    if (value == null) return 'No data';

    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(1)} kg';
  }

  Widget _metricCard(BuildContext context, String label, String value) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _goalProgress(String label, WeeklyGoalProgress? progress) {
    if (progress == null) {
      return const SizedBox.shrink();
    }

    final rate = progress.achievementRate;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text('${progress.achievedDays}/${progress.measuredDays} days'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: rate ?? 0),
          if (rate == null)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('No measurements this week'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasGoals =
        insights.caloriesGoal != null ||
        insights.proteinGoal != null ||
        insights.stepsGoal != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weekly Insights', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              tooltip: 'Previous week',
              onPressed: onPreviousWeek,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '${_dateLabel(insights.weekStart)} - '
                    '${_dateLabel(insights.weekEnd)}, '
                    '${insights.weekEnd.year}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${insights.loggedDays} days logged',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Next week',
              onPressed: onNextWeek,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _metricCard(
              context,
              'Avg. Calories',
              _average(insights.averageCalories, 'kcal'),
            ),
            _metricCard(
              context,
              'Avg. Protein',
              _average(insights.averageProtein, 'g'),
            ),
          ],
        ),
        Row(
          children: [
            _metricCard(
              context,
              'Avg. Steps',
              _average(insights.averageSteps, 'steps'),
            ),
            _metricCard(
              context,
              'Weight Change',
              _weightChange(insights.weightChange),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Goal Achievement',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (!hasGoals)
          const Text(
            'Set calorie, protein, or step goals '
            'to see your weekly progress.',
          ),
        _goalProgress('Calories', insights.caloriesGoal),
        _goalProgress('Protein', insights.proteinGoal),
        _goalProgress('Steps', insights.stepsGoal),
      ],
    );
  }
}
