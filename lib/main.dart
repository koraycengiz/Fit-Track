import 'package:flutter/material.dart';
import 'models/daily_entry.dart';
import 'screens/daily_entry_screen.dart';
import 'database/database_helper.dart';
import 'screens/history_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/goals_screen.dart';
import 'widgets/dashboard_metric_card.dart';
import 'widgets/dashboard_quick_access.dart';
import 'widgets/dashboard_empty_state.dart';
import 'screens/backup_restore_screen.dart';

void main() {
  runApp(const FitTrackApp());
}

class FitTrackApp extends StatelessWidget {
  const FitTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.greenAccent,
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DailyEntry? _latestEntry;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLatestEntry();
  }

  Future<void> _openAnalytics() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
    );

    if (!mounted) return;

    await _loadLatestEntry();
  }

  Future<void> _openHistory() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );

    if (!mounted) return;

    await _loadLatestEntry();
  }

  Future<void> _openGoals() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GoalsScreen()),
    );

    if (!mounted) return;

    await _loadLatestEntry();
  }

  Future<void> _openBackup() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (context) => const BackupRestoreScreen()),
    );

    if (!mounted) return;

    // Refresh the Dashboard after returning from Backup & Restore.
    await _loadLatestEntry();
  }

  Future<void> _loadLatestEntry() async {
    try {
      final entry = await DatabaseHelper.instance.getLatestEntry();

      if (!mounted) return;

      setState(() {
        _latestEntry = entry;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load entries: $error')));
    }
  }

  Future<void> _addEntry() async {
    try {
      final today = DateTime.now();

      final existingEntry = await DatabaseHelper.instance.getEntryByDate(today);

      if (!mounted) return;

      final entry = await Navigator.push<DailyEntry>(
        context,
        MaterialPageRoute(
          builder: (context) => DailyEntryScreen(initialEntry: existingEntry),
        ),
      );

      if (!mounted || entry == null) return;

      await DatabaseHelper.instance.saveEntry(entry);

      await _loadLatestEntry();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existingEntry == null
                ? 'Daily entry saved successfully!'
                : 'Daily entry updated successfully!',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save entry: $error')));
    }
  }

  String get _entryDateLabel {
    final entry = _latestEntry;

    if (entry == null) {
      return 'No fitness entries recorded yet';
    }

    final today = DateTime.now();

    final isToday =
        entry.date.year == today.year &&
        entry.date.month == today.month &&
        entry.date.day == today.day;

    if (isToday) {
      return "Today's fitness data";
    }

    return 'Latest entry: ${DailyEntry.dateKey(entry.date)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FitTrack')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Your Fitness Dashboard',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _entryDateLabel,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_latestEntry == null)
                    DashboardEmptyState(onAddEntry: _addEntry)
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.35,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            DashboardMetricCard(
                              label: 'Weight',
                              value:
                                  _latestEntry?.weight == null
                                      ? 'No data'
                                      : '${_latestEntry!.weight} kg',
                              icon: Icons.monitor_weight_outlined,
                            ),
                            DashboardMetricCard(
                              label: 'Calories',
                              value:
                                  _latestEntry?.calories == null
                                      ? 'No data'
                                      : '${_latestEntry!.calories} kcal',
                              icon: Icons.local_fire_department_outlined,
                            ),
                            DashboardMetricCard(
                              label: 'Protein',
                              value:
                                  _latestEntry?.protein == null
                                      ? 'No data'
                                      : '${_latestEntry!.protein} g',
                              icon: Icons.fitness_center_outlined,
                            ),
                            DashboardMetricCard(
                              label: 'Steps',
                              value:
                                  _latestEntry?.steps == null
                                      ? 'No data'
                                      : '${_latestEntry!.steps}',
                              icon: Icons.directions_walk_outlined,
                            ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 28),

                  DashboardQuickAccess(
                    onHistory: _openHistory,
                    onAnalytics: _openAnalytics,
                    onGoals: _openGoals,
                    onBackup: _openBackup,
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEntry,
        child: const Icon(Icons.add),
      ),
    );
  }
}
