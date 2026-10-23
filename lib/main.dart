
import 'package:flutter/material.dart';
import 'models/daily_entry.dart';
import 'screens/daily_entry_screen.dart';
import 'database/database_helper.dart';

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


  Future<void> _loadLatestEntry() async {
    try {
      debugPrint('DASHBOARD: Loading latest entry...');

      final entry =
      await DatabaseHelper.instance.getLatestEntry();

      debugPrint(
        'DASHBOARD: Loaded entry: '
            '${entry?.date}, Weight: ${entry?.weight}',
      );

      if (!mounted) return;

      setState(() {
        _latestEntry = entry;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('DATABASE ERROR: $error');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load entries: $error'),
        ),
      );
    }
  }




  Future<void> _addEntry() async {
    final entry = await Navigator.push<DailyEntry>(
      context,
      MaterialPageRoute(
        builder: (context) => const DailyEntryScreen(),
      ),
    );

    if (!mounted || entry == null) return;

    try {
      await DatabaseHelper.instance.saveEntry(entry);

      await _loadLatestEntry();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily entry saved successfully!'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save entry: $error'),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FitTrack'),
      ),
      body: _isLoading
        ? const Center(
        child: CircularProgressIndicator(),
      )
      : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Your Fitness Dashboard',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.monitor_weight),
              title: const Text('Weight'),
              subtitle: Text(
                _latestEntry?.weight == null
                    ? 'No entry yet'
                    : '${_latestEntry!.weight} kg',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_fire_department),
              title: const Text('Calories'),
              subtitle: Text(
                _latestEntry?.calories == null
                    ? 'No entry yet'
                    : '${_latestEntry!.calories} kcal',
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.directions_walk),
              title: const Text('Steps'),
              subtitle: Text(
                _latestEntry?.steps == null
                    ? 'No entry yet'
                    : '${_latestEntry!.steps}',
              ),
            ),
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

