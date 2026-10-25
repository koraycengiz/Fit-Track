
class DailyEntry {
  final DateTime date;
  final double? weight;
  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final int? steps;
  final double? waist;
  final String? workout;
  final String? notes;

  const DailyEntry({
    required this.date,
    this.weight,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.steps,
    this.waist,
    this.workout,
    this.notes,
  });

  // Convert a date to YYYY-MM-DD.
  static String dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // Convert a Dart object into SQLite column values.
  Map<String, Object?> toMap() {
    return {
      'date': dateKey(date),
      'weight': weight,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'steps': steps,
      'waist': waist,
      'workout': workout,
      'notes': notes,
    };
  }

  // Convert a SQLite row back into a Dart object.
  factory DailyEntry.fromMap(Map<String, Object?> map) {
    return DailyEntry(
      date: DateTime.parse(map['date'] as String),
      weight: (map['weight'] as num?)?.toDouble(),
      calories: (map['calories'] as num?)?.toInt(),
      protein: (map['protein'] as num?)?.toDouble(),
      carbs: (map['carbs'] as num?)?.toDouble(),
      fat: (map['fat'] as num?)?.toDouble(),
      steps: (map['steps'] as num?)?.toInt(),
      waist: (map['waist'] as num?)?.toDouble(),
      workout: map['workout'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
