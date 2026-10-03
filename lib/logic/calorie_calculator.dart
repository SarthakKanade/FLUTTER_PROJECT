import '../models/balance.dart';
import '../models/entry.dart';

/// Pure logic for calculating daily calorie balance and progress cues.
class CalorieCalculator {
  /// Calculate balance from the list of entries and user daily target.
  static Balance calculate(List<Entry> entries, int target) {
    int consumed = 0;
    int burned = 0;

    for (final entry in entries) {
      if (entry.isMeal) {
        consumed += entry.kcal;
      } else if (entry.isWorkout) {
        burned += entry.kcal;
      }
    }

    // Remaining = Target - Consumed + Burned
    final remaining = target - consumed + burned;
    final isOver = remaining < 0;
    final overAmount = isOver ? (consumed - (target + burned)) : 0;
    final progress = target > 0 ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    return Balance(
      consumed: consumed,
      burned: burned,
      target: target,
      remaining: remaining,
      isOver: isOver,
      overAmount: overAmount,
      progress: progress,
    );
  }
}
