/// Computed daily calorie balance.
class Balance {
  final int consumed;
  final int burned;
  final int target;
  final int remaining;
  final bool isOver;
  final int overAmount;
  final double progress;

  const Balance({
    required this.consumed,
    required this.burned,
    required this.target,
    required this.remaining,
    required this.isOver,
    required this.overAmount,
    required this.progress,
  });

  /// Factory constructor providing default zeroed balance.
  factory Balance.initial({int target = 2000}) {
    return Balance(
      consumed: 0,
      burned: 0,
      target: target,
      remaining: target,
      isOver: false,
      overAmount: 0,
      progress: 0.0,
    );
  }

  /// Net calories = consumed - burned
  int get netCalories => consumed - burned;

  /// Whether user is currently in a calorie deficit / on track
  bool get isDeficit => !isOver && remaining >= 0;

  /// Burn ratio compared to target
  double get burnProgress => target > 0 ? (burned / target).clamp(0.0, 1.0) : 0.0;

  /// Consumed ratio compared to target
  double get consumedProgress => progress;

  @override
  String toString() {
    return 'Balance(consumed: $consumed, burned: $burned, target: $target, remaining: $remaining, isOver: $isOver, progress: ${(progress * 100).toStringAsFixed(1)}%)';
  }
}
