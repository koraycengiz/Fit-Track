
import 'package:flutter/material.dart';
import 'models/daily_entry.dart';
import 'screens/daily_entry_screen.dart';

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

  Future<void> _addEntry() async {
    final entry = await Navigator.push<DailyEntry>(
      context,
      MaterialPageRoute(
        builder: (context) => const DailyEntryScreen(),
      ),
    );

    if (!mounted || entry == null) return;

    setState(() {
      _latestEntry = entry;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entry added for this session!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FitTrack'),
      ),
      body: ListView(
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

