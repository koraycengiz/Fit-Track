import 'package:flutter/material.dart';

class DashboardQuickAccess extends StatelessWidget {
  final VoidCallback onEnterData;
  final VoidCallback onHistory;
  final VoidCallback onCalendar;
  final VoidCallback onAnalytics;
  final VoidCallback onGoals;
  final VoidCallback onBackup;

  const DashboardQuickAccess({
    super.key,
    required this.onEnterData,
    required this.onHistory,
    required this.onCalendar,
    required this.onAnalytics,
    required this.onGoals,
    required this.onBackup,
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

        // Primary action - Enter Data
        Row(
          children: [
            Expanded(
              child: _QuickAccessButton(
                label: 'Enter Data',
                icon: Icons.edit_note_outlined,
                onTap: onEnterData,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Main navigation
        Row(
          children: [
            Expanded(
              child: _QuickAccessButton(
                label: 'Calendar',
                icon: Icons.calendar_month_outlined,
                onTap: onCalendar,
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
          ],
        ),

        const SizedBox(height: 10),

        // Secondary navigation
        Row(
          children: [
            Expanded(
              child: _QuickAccessButton(
                label: 'History',
                icon: Icons.history,
                onTap: onHistory,
                compact: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickAccessButton(
                label: 'Goals',
                icon: Icons.flag_outlined,
                onTap: onGoals,
                compact: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickAccessButton(
                label: 'Backup',
                icon: Icons.backup_outlined,
                onTap: onBackup,
                compact: true,
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
  final bool compact;

  const _QuickAccessButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.compact = false,
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
          padding: EdgeInsets.symmetric(
            vertical: compact ? 13 : 18,
            horizontal: 4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colorScheme.primary, size: compact ? 22 : 26),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 11 : 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
