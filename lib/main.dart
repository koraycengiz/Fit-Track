
import 'package:flutter/material.dart';

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

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FitTrack'),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Fitness Dashboard',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Card(
              child: ListTile(
                leading: Icon(Icons.monitor_weight),
                title: Text('Weight'),
                subtitle: Text('No entry yet'),
              ),
            ),
            const Card(
              child: ListTile(
                leading: Icon(Icons.local_fire_department),
                title: Text('Calories'),
                subtitle: Text('No entry yet'),
              ),
            ),
            const Card(
              child: ListTile(
                leading: Icon(Icons.directions_walk),
                title: Text('Steps'),
                subtitle: Text('No entry yet'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Daily entry screen coming next!'),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
