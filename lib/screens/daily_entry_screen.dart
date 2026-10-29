import 'package:flutter/material.dart';
import '../models/daily_entry.dart';

class DailyEntryScreen extends StatefulWidget {
  final DailyEntry? initialEntry;
  final DateTime? initialDate;

  const DailyEntryScreen({super.key, this.initialEntry, this.initialDate});

  @override
  State<DailyEntryScreen> createState() => _DailyEntryScreenState();
}

class _DailyEntryScreenState extends State<DailyEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();

  final _weightController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _stepsController = TextEditingController();
  final _waistController = TextEditingController();
  final _workoutController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final entry = widget.initialEntry;
    if (entry == null && widget.initialDate != null) {
      _selectedDate = DateUtils.dateOnly(widget.initialDate!);
    }

    if (entry != null) {
      _selectedDate = entry.date;

      _weightController.text = entry.weight?.toString() ?? '';
      _caloriesController.text = entry.calories?.toString() ?? '';
      _proteinController.text = entry.protein?.toString() ?? '';
      _carbsController.text = entry.carbs?.toString() ?? '';
      _fatController.text = entry.fat?.toString() ?? '';
      _stepsController.text = entry.steps?.toString() ?? '';
      _waistController.text = entry.waist?.toString() ?? '';
      _workoutController.text = entry.workout ?? '';
      _notesController.text = entry.notes ?? '';
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _stepsController.dispose();
    _waistController.dispose();
    _workoutController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  double? _parseDouble(String value) {
    final normalized = value.trim().replaceAll(',', '.');

    if (normalized.isEmpty) return null;

    return double.tryParse(normalized);
  }

  String? _validateNumber(String? value, {bool integer = false}) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final number = integer ? int.tryParse(value.trim()) : _parseDouble(value);

    if (number == null || number < 0) {
      return 'Enter a valid non-negative number';
    }

    return null;
  }

  // Reusable numeric input with label above the border.
  Widget _numberField(
    String label,
    TextEditingController controller, {
    bool integer = false,
    String? unit,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: !integer),
            decoration: InputDecoration(
              hintText: '0',
              suffixText: unit,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            validator: (value) => _validateNumber(value, integer: integer),
          ),
        ],
      ),
    );
  }

  // Reusable section heading.
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Reusable multiline input.
  Widget _textField(
    String label,
    TextEditingController controller, {
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.all(14),
      ),
    );
  }

  void _saveEntry() {
    if (!_formKey.currentState!.validate()) return;

    final entry = DailyEntry(
      date: _selectedDate,
      weight: _parseDouble(_weightController.text),
      calories: int.tryParse(_caloriesController.text.trim()),
      protein: _parseDouble(_proteinController.text),
      carbs: _parseDouble(_carbsController.text),
      fat: _parseDouble(_fatController.text),
      steps: int.tryParse(_stepsController.text.trim()),
      waist: _parseDouble(_waistController.text),
      workout:
          _workoutController.text.trim().isEmpty
              ? null
              : _workoutController.text.trim(),
      notes:
          _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
    );

    Navigator.pop(context, entry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialEntry == null ? 'New Daily Entry' : 'Edit Daily Entry',
        ),
      ),

      // Keeps the form and save button above the keyboard.
      resizeToAvoidBottomInset: true,

      // Scrollable form
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 400 ? 16.0 : 24.0;

            return Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 16,
                ),
                children: [
                  // Date selection
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Date'),
                      subtitle: Text(
                        '${_selectedDate.day}/'
                        '${_selectedDate.month}/'
                        '${_selectedDate.year}',
                      ),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: _pickDate,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Body measurements - compact 2-column layout
                  _sectionTitle('Body Measurements'),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _numberField(
                          'Weight',
                          _weightController,
                          unit: 'kg',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _numberField(
                          'Waist',
                          _waistController,
                          unit: 'cm',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Nutrition - compact 2x2 grid
                  _sectionTitle('Nutrition'),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _numberField(
                          'Calories',
                          _caloriesController,
                          integer: true,
                          unit: 'kcal',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _numberField(
                          'Protein',
                          _proteinController,
                          unit: 'g',
                        ),
                      ),
                    ],
                  ),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _numberField(
                          'Carbs',
                          _carbsController,
                          unit: 'g',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _numberField('Fat', _fatController, unit: 'g'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Activity
                  _sectionTitle('Activity'),

                  _numberField('Steps', _stepsController, integer: true),

                  const SizedBox(height: 12),

                  _textField(
                    'Workout',
                    _workoutController,
                    hint: 'e.g. Chest, triceps, 5 km run',
                  ),

                  const SizedBox(height: 24),

                  // Daily notes
                  _sectionTitle('Daily Notes'),

                  _textField(
                    'Notes',
                    _notesController,
                    hint: 'How did you feel today?',
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),

      // Fixed Save button
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _saveEntry,
              icon: const Icon(Icons.check),
              label: Text(
                widget.initialEntry == null ? 'Save Entry' : 'Update Entry',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
