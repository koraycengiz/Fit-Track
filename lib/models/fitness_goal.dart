
class FitnessGoal {
  final int? dailyCalories;
  final double? dailyProtein;
  final double? dailyCarbs;
  final double? dailyFat;
  final int? dailySteps;
  final double? targetWeight;

  const FitnessGoal({
    this.dailyCalories,
    this.dailyProtein,
    this.dailyCarbs,
    this.dailyFat,
    this.dailySteps,
    this.targetWeight,
  });

  bool get hasAnyGoal =>
      dailyCalories != null ||
          dailyProtein != null ||
          dailyCarbs != null ||
          dailyFat != null ||
          dailySteps != null ||
          targetWeight != null;

  Map<String, Object?> toMap() {
    return {
      'daily_calories': dailyCalories,
      'daily_protein': dailyProtein,
      'daily_carbs': dailyCarbs,
      'daily_fat': dailyFat,
      'daily_steps': dailySteps,
      'target_weight': targetWeight,
    };
  }

  factory FitnessGoal.fromMap(Map<String, Object?> map) {
    return FitnessGoal(
      dailyCalories: map['daily_calories'] as int?,
      dailyProtein: (map['daily_protein'] as num?)?.toDouble(),
      dailyCarbs: (map['daily_carbs'] as num?)?.toDouble(),
      dailyFat: (map['daily_fat'] as num?)?.toDouble(),
      dailySteps: map['daily_steps'] as int?,
      targetWeight: (map['target_weight'] as num?)?.toDouble(),
    );
  }

  FitnessGoal copyWith({
    int? dailyCalories,
    double? dailyProtein,
    double? dailyCarbs,
    double? dailyFat,
    int? dailySteps,
    double? targetWeight,
  }) {
    return FitnessGoal(
      dailyCalories: dailyCalories ?? this.dailyCalories,
      dailyProtein: dailyProtein ?? this.dailyProtein,
      dailyCarbs: dailyCarbs ?? this.dailyCarbs,
      dailyFat: dailyFat ?? this.dailyFat,
      dailySteps: dailySteps ?? this.dailySteps,
      targetWeight: targetWeight ?? this.targetWeight,
    );
  }
}
