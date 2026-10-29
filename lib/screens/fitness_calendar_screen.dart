import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/daily_entry.dart';
import 'daily_entry_screen.dart';

class FitnessCalendarScreen extends StatefulWidget {
  final Future<List<DailyEntry>> Function()? loadEntries;

  const FitnessCalendarScreen({super.key, this.loadEntries});

  @override
  State<FitnessCalendarScreen> createState() => _FitnessCalendarScreenState();
}

class _FitnessCalendarScreenState extends State<FitnessCalendarScreen> {
  DateTime _displayedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());

  Map<String, DailyEntry> _entriesByDate = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final entries =
          await (widget.loadEntries?.call() ??
              DatabaseHelper.instance.getAllEntries());

      if (!mounted) return;

      setState(() {
        _entriesByDate = {
          for (final entry in entries) DailyEntry.dateKey(entry.date): entry,
        };
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

  Future<void> _openEntryEditor() async {
    final originalDate = _selectedDate;
    final originalEntry = _entriesByDate[DailyEntry.dateKey(originalDate)];

    try {
      final updatedEntry = await Navigator.push<DailyEntry>(
        context,
        MaterialPageRoute(
          builder:
              (context) => DailyEntryScreen(
                initialEntry: originalEntry,
                initialDate: originalDate,
              ),
        ),
      );

      if (!mounted || updatedEntry == null) return;

      await DatabaseHelper.instance.saveEntrySafely(
        updatedEntry,
        originalDate: originalEntry?.date,
      );

      if (!mounted) return;

      setState(() {
        _selectedDate = DateUtils.dateOnly(updatedEntry.date);
        _displayedMonth = DateTime(
          updatedEntry.date.year,
          updatedEntry.date.month,
        );
      });

      await _loadEntries();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            originalEntry == null
                ? 'Daily entry saved successfully!'
                : 'Daily entry updated successfully!',
          ),
        ),
      );
    } on StateError catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save entry: $error')));
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + offset,
      );
      _selectedDate = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    });
  }

  String _monthTitle(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  String _selectedDateTitle(DateTime date) {
    return '${date.day} ${_monthTitle(date)}';
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_displayedMonth.year, _displayedMonth.month, 1);

    final daysInMonth = DateUtils.getDaysInMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );

    // DateTime.weekday: Monday = 1, Sunday = 7.
    final leadingEmptyDays = firstDay.weekday - 1;

    final totalCells = ((leadingEmptyDays + daysInMonth + 6) ~/ 7) * 7;

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              key: const Key('previous_month'),
              tooltip: 'Previous month',
              onPressed: () => _changeMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                _monthTitle(_displayedMonth),
                key: const Key('calendar_month_title'),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              key: const Key('next_month'),
              tooltip: 'Next month',
              onPressed: () => _changeMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final weekday in weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    weekday,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 0.9,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            final dayNumber = index - leadingEmptyDays + 1;

            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }

            final date = DateTime(
              _displayedMonth.year,
              _displayedMonth.month,
              dayNumber,
            );

            final dateKey = DailyEntry.dateKey(date);
            final hasEntry = _entriesByDate.containsKey(dateKey);
            final isSelected = DateUtils.isSameDay(date, _selectedDate);
            final isToday = DateUtils.isSameDay(date, DateTime.now());

            return InkWell(
              key: Key('calendar_day_$dateKey'),
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  _selectedDate = date;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primaryContainer : null,
                  borderRadius: BorderRadius.circular(10),
                  border:
                      isToday ? Border.all(color: colorScheme.primary) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color:
                            isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      key: Key('entry_indicator_$dateKey'),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: hasEntry ? Colors.green : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSelectedDay() {
    final dateKey = DailyEntry.dateKey(_selectedDate);
    final entry = _entriesByDate[dateKey];

    final colorScheme = Theme.of(context).colorScheme;

    String formatDecimal(double? value, String unit) {
      if (value == null) return '—';

      final formatted =
          value == value.roundToDouble()
              ? value.toStringAsFixed(0)
              : value.toStringAsFixed(1);

      return '$formatted $unit';
    }

    Widget metricCard(String label, String value, IconData icon) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedDateTitle(_selectedDate),
          key: const Key('selected_date_title'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        if (entry == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.event_busy_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No entry recorded for this date.',
                      key: Key('selected_date_status'),
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          const Text(
            'Daily Overview',
            key: Key('selected_date_status'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              metricCard(
                'Weight',
                formatDecimal(entry.weight, 'kg'),
                Icons.monitor_weight_outlined,
              ),
              metricCard(
                'Calories',
                entry.calories == null ? '—' : '${entry.calories} kcal',
                Icons.local_fire_department_outlined,
              ),
              metricCard(
                'Protein',
                formatDecimal(entry.protein, 'g'),
                Icons.fitness_center_outlined,
              ),
              metricCard(
                'Carbs',
                formatDecimal(entry.carbs, 'g'),
                Icons.grain_outlined,
              ),
              metricCard(
                'Fat',
                formatDecimal(entry.fat, 'g'),
                Icons.water_drop_outlined,
              ),
              metricCard(
                'Steps',
                entry.steps?.toString() ?? '—',
                Icons.directions_walk_outlined,
              ),
              metricCard(
                'Waist',
                formatDecimal(entry.waist, 'cm'),
                Icons.straighten_outlined,
              ),
            ],
          ),

          if (entry.workout != null && entry.workout!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Workout',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(entry.workout!),
          ],

          if (entry.notes != null && entry.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Daily Notes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(entry.notes!),
          ],
        ],

        // This button is outside the if/else condition.
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('calendar_entry_action'),
            onPressed: _openEntryEditor,
            icon: Icon(entry == null ? Icons.add : Icons.edit_outlined),
            label: Text(entry == null ? 'Add Entry' : 'Edit Entry'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Calendar'),
        actions: [
          IconButton(
            tooltip: 'Refresh calendar',
            onPressed: _loadEntries,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Failed to load calendar:\n$_error',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadEntries,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadEntries,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildCalendar(),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Days with recorded entries',
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSelectedDay(),
                  ],
                ),
              ),
    );
  }
}
