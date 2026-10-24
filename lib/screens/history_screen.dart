
import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/daily_entry.dart';
import 'daily_entry_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  String? _error;
  List<DailyEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    try {
      final entries = await DatabaseHelper.instance.getAllEntries();

      if (!mounted) return;

      setState(() {
        _entries = entries;
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

  Future<void> _editEntry(DailyEntry entry) async {
    final updatedEntry = await Navigator.push<DailyEntry>(
      context,
      MaterialPageRoute(
        builder: (context) => DailyEntryScreen(
          initialEntry: entry,
        ),
      ),
    );

    if (!mounted || updatedEntry == null) return;

    try {
      // If the date changes, remove the old record only after
      // checking that the new date is not already occupied.
      if (DailyEntry.dateKey(updatedEntry.date) !=
          DailyEntry.dateKey(entry.date)) {
        final existing = await DatabaseHelper.instance
            .getEntryByDate(updatedEntry.date);

        if (existing != null) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'An entry already exists for that date. '
                    'Edit that entry instead.',
              ),
            ),
          );
          return;
        }

        // Keep the original record until the new one is saved.
        await DatabaseHelper.instance.saveEntry(updatedEntry);
        await DatabaseHelper.instance.deleteEntry(entry.date);
      } else {
        await DatabaseHelper.instance.saveEntry(updatedEntry);
      }

      await _loadEntries();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entry updated successfully!'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update entry: $error')),
      );
    }
  }

  Future<void> _deleteEntry(DailyEntry entry) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: Text(
          'Are you sure you want to delete the entry '
              'for ${_formatDate(entry.date)}? '
              'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || shouldDelete != true) return;

    try {
      await DatabaseHelper.instance.deleteEntry(entry.date);
      await _loadEntries();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entry deleted successfully!'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete entry: $error')),
      );
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDecimal(double? value, String unit) {
    if (value == null) return '—';

    final formatted = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);

    return '$formatted $unit';
  }

  String _formatCalories(int? value) {
    if (value == null) return '—';

    final formatted = value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
    );

    return '$formatted kcal';
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _entryCard(DailyEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _editEntry(entry),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDate(entry.date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete entry',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteEntry(entry),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _metric(
                    'Weight',
                    _formatDecimal(entry.weight, 'kg'),
                  ),
                  _metric(
                    'Calories',
                    _formatCalories(entry.calories),
                  ),
                  _metric(
                    'Protein',
                    _formatDecimal(entry.protein, 'g'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily History'),
        actions: [
          IconButton(
            tooltip: 'Refresh history',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadEntries();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Failed to load history:\n$_error',
            textAlign: TextAlign.center,
          ),
        ),
      )
          : _entries.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 60,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'No entries yet',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 6),
            Text(
              'Add your first daily entry to see it here.',
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadEntries,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _entries.length,
          itemBuilder: (context, index) {
            return _entryCard(_entries[index]);
          },
        ),
      ),
    );
  }
}
