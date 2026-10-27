import 'package:flutter/material.dart';

class DashboardQuickAccess extends StatelessWidget {
  final VoidCallback onHistory;
  final VoidCallback onAnalytics;
  final VoidCallback onGoals;

  const DashboardQuickAccess({
    super.key,
    required this.onHistory,
    required this.onAnalytics,
    required this.onGoals,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAccessButton(
                label: 'History',
                icon: Icons.history,
                onTap: onHistory,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAccessButton(
                label: 'Analytics',
                icon: Icons.show_chart,
                onTap: onAnalytics,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAccessButton(
                label: 'Goals',
                icon: Icons.flag_outlined,
                onTap: onGoals,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAccessButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAccessButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colorScheme.primary, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
