import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/fitness_goal.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _stepsController = TextEditingController();
  final _weightController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final goals = await DatabaseHelper.instance.getGoals();

      if (!mounted) return;

      _caloriesController.text = goals.dailyCalories?.toString() ?? '';
      _proteinController.text = goals.dailyProtein?.toString() ?? '';
      _carbsController.text = goals.dailyCarbs?.toString() ?? '';
      _fatController.text = goals.dailyFat?.toString() ?? '';
      _stepsController.text = goals.dailySteps?.toString() ?? '';
      _weightController.text = goals.targetWeight?.toString() ?? '';

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load goals: $error')));
    }
  }

  int? _parseInt(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : int.tryParse(value);
  }

  double? _parseDouble(TextEditingController controller) {
    final value = controller.text.trim().replaceAll(',', '.');
    return value.isEmpty ? null : double.tryParse(value);
  }

  String? _validatePositiveNumber(String? value, {bool integer = false}) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final normalized = value.trim().replaceAll(',', '.');

    final number =
        integer ? int.tryParse(normalized) : double.tryParse(normalized);

    if (number == null || !number.isFinite || number <= 0) {
      return 'Enter a positive ${integer ? 'whole number' : 'number'}';
    }

    return null;
  }

  Future<void> _saveGoals() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final goals = FitnessGoal(
      dailyCalories: _parseInt(_caloriesController),
      dailyProtein: _parseDouble(_proteinController),
      dailyCarbs: _parseDouble(_carbsController),
      dailyFat: _parseDouble(_fatController),
      dailySteps: _parseInt(_stepsController),
      targetWeight: _parseDouble(_weightController),
    );

    try {
      await DatabaseHelper.instance.saveGoals(goals);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fitness goals saved!')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save goals: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _clearGoals() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Clear all goals?'),
            content: const Text(
              'This will remove all your configured fitness targets. '
              'Your daily fitness entries will not be affected.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Clear Goals'),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await DatabaseHelper.instance.clearGoals();

      if (!mounted) return;

      // Reset the form before clearing the controllers.
      _formKey.currentState?.reset();

      _caloriesController.clear();
      _proteinController.clear();
      _carbsController.clear();
      _fatController.clear();
      _stepsController.clear();
      _weightController.clear();

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All goals cleared.')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to clear goals: $error')));
    } finally {
      if (mounted && _isSaving) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _goalField({
    required String label,
    required String unit,
    required TextEditingController controller,
    bool integer = false,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_isSaving,
      keyboardType: TextInputType.numberWithOptions(decimal: !integer),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        border: const OutlineInputBorder(),
      ),
      validator: (value) => _validatePositiveNumber(value, integer: integer),
    );
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _stepsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fitness Goals')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Set your personal targets. All fields are optional.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Daily Nutrition',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    _goalField(
                      label: 'Calories',
                      unit: 'kcal',
                      controller: _caloriesController,
                      integer: true,
                    ),
                    const SizedBox(height: 12),

                    _goalField(
                      label: 'Protein',
                      unit: 'g',
                      controller: _proteinController,
                    ),
                    const SizedBox(height: 12),

                    _goalField(
                      label: 'Carbs',
                      unit: 'g',
                      controller: _carbsController,
                    ),
                    const SizedBox(height: 12),

                    _goalField(
                      label: 'Fat',
                      unit: 'g',
                      controller: _fatController,
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Activity & Body',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    _goalField(
                      label: 'Daily Steps',
                      unit: 'steps',
                      controller: _stepsController,
                      integer: true,
                    ),
                    const SizedBox(height: 12),

                    _goalField(
                      label: 'Target Weight',
                      unit: 'kg',
                      controller: _weightController,
                    ),
                    const SizedBox(height: 24),

                    FilledButton.icon(
                      onPressed: _isSaving ? null : _saveGoals,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Goals'),
                    ),
                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : _clearGoals,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Clear All Goals'),
                    ),
                  ],
                ),
              ),
    );
  }
}
