import 'package:flutter/material.dart';

class DashboardEmptyState extends StatelessWidget {
  final VoidCallback onAddEntry;

  const DashboardEmptyState({super.key, required this.onAddEntry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.insights_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to FitTrack!',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking your fitness journey by adding '
              'your first daily entry.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAddEntry,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Entry'),
            ),
          ],
        ),
      ),
    );
  }
}
