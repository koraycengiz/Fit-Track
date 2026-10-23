
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
}
