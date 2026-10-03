import '../models/entry.dart';

/// MET (Metabolic Equivalent of Task) table and exercise calculation utilities.
/// Formula: kcal = MET × weight(kg) × duration(hours)
class MetCalculator {
  /// Default user weight in kg if none configured.
  static const double defaultWeightKg = 70.0;

  /// Calculate estimated calories burned based on exercise type, weight, and duration in minutes.
  static int estimateBurn({
    required ExerciseType exerciseType,
    required int durationMin,
    double weightKg = defaultWeightKg,
  }) {
    if (durationMin <= 0 || weightKg <= 0) return 0;
    final hours = durationMin / 60.0;
    final burned = exerciseType.met * weightKg * hours;
    return burned.round();
  }
}
