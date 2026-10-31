import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/daily_entry.dart';
import '../services/analytics_service.dart';
import '../widgets/progress_line_chart.dart';
import '../models/fitness_goal.dart';
import '../services/weekly_insights_service.dart';
import '../widgets/weekly_insights_section.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  String? _error;
  List<DailyEntry> _allEntries = [];

  FitnessGoal _goals = const FitnessGoal();
  DateTime _selectedWeek = DateTime.now();

  int _selectedDays = 7;
  ProgressMetric _selectedMetric = ProgressMetric.weight;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    try {
      final entries = await DatabaseHelper.instance.getAllEntries();

      final goals = await DatabaseHelper.instance.getGoals();

      if (!mounted) return;

      setState(() {
        _allEntries = entries;
        _goals = goals;
        _error = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  String _formatWeightChange(double? change) {
    if (change == null) return '—';

    final sign = change > 0 ? '+' : '';

    return '$sign${change.toStringAsFixed(1)} kg';
  }

  String _formatCalories(double? value) {
    if (value == null) return '—';

    final rounded = value.round();

    final formatted = rounded.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    return '$formatted kcal';
  }

  String _formatAverage(double? value, String unit) {
    if (value == null) return '—';

    return '${value.toStringAsFixed(1)} $unit';
  }

  Widget _summaryCard(String title, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = AnalyticsService.entriesForLastDays(
      _allEntries,
      _selectedDays,
    );

    final today = DateTime.now();

    final weeklyInsights = WeeklyInsightsService.calculate(
      entries: _allEntries,
      goals: _goals,
      selectedDate: _selectedWeek,
      today: today,
    );

    final currentWeekStart = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - DateTime.monday));

    final canGoNext = weeklyInsights.weekStart.isBefore(currentWeekStart);

    return Scaffold(
      appBar: AppBar(title: const Text('Progress Analytics')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text('Failed to load analytics: $_error'))
              : RefreshIndicator(
                onRefresh: _loadEntries,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    WeeklyInsightsSection(
                      insights: weeklyInsights,
                      onPreviousWeek: () {
                        setState(() {
                          _selectedWeek = _selectedWeek.subtract(
                            const Duration(days: 7),
                          );
                        });
                      },
                      onNextWeek:
                          canGoNext
                              ? () {
                                setState(() {
                                  _selectedWeek = _selectedWeek.add(
                                    const Duration(days: 7),
                                  );
                                });
                              }
                              : null,
                    ),
                    const Divider(height: 40),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 7, label: Text('7 Days')),
                        ButtonSegment(value: 30, label: Text('30 Days')),
                      ],
                      selected: {_selectedDays},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _selectedDays = selection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        Row(
                          children: [
                            _summaryCard(
                              'Avg. Weight',
                              _formatAverage(
                                AnalyticsService.averageWeight(filtered),
                                'kg',
                              ),
                            ),
                            _summaryCard(
                              'Weight Change',
                              _formatWeightChange(
                                AnalyticsService.weightChange(filtered),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _summaryCard(
                              'Avg. Calories',
                              _formatCalories(
                                AnalyticsService.averageCalories(filtered),
                              ),
                            ),
                            _summaryCard(
                              'Avg. Protein',
                              _formatAverage(
                                AnalyticsService.averageProtein(filtered),
                                'g',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<ProgressMetric>(
                      segments: const [
                        ButtonSegment(
                          value: ProgressMetric.weight,
                          label: Text('Weight'),
                        ),
                        ButtonSegment(
                          value: ProgressMetric.calories,
                          label: Text('Calories'),
                        ),
                        ButtonSegment(
                          value: ProgressMetric.protein,
                          label: Text('Protein'),
                        ),
                      ],
                      selected: {_selectedMetric},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _selectedMetric = selection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    ProgressLineChart(
                      entries: filtered,
                      metric: _selectedMetric,
                    ),
                  ],
                ),
              ),
    );
  }
}
