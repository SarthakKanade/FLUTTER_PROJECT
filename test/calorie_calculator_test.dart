import 'package:flutter_test/flutter_test.dart';
import 'package:fittrail/models/entry.dart';
import 'package:fittrail/logic/calorie_calculator.dart';
import 'package:fittrail/logic/met_table.dart';

void main() {
  group('CalorieCalculator Tests', () {
    test('calculateBalance with no entries returns initial target', () {
      final balance = CalorieCalculator.calculate([], 2000);
      expect(balance.consumed, 0);
      expect(balance.burned, 0);
      expect(balance.target, 2000);
      expect(balance.remaining, 2000);
      expect(balance.isOver, false);
      expect(balance.overAmount, 0);
      expect(balance.progress, 0.0);
    });

    test('calculateBalance with meals and workouts recalculates net remaining', () {
      final entries = [
        Entry(
          id: '1',
          type: EntryType.meal,
          title: 'Poha',
          kcal: 350,
          createdAt: DateTime(2026, 10, 2, 8, 30),
          mealType: MealType.breakfast,
        ),
        Entry(
          id: '2',
          type: EntryType.workout,
          title: 'Morning Run',
          kcal: 250,
          createdAt: DateTime(2026, 10, 2, 9, 30),
          exerciseType: ExerciseType.running,
          durationMin: 25,
        ),
        Entry(
          id: '3',
          type: EntryType.meal,
          title: 'Lunch Thali',
          kcal: 650,
          createdAt: DateTime(2026, 10, 2, 13, 0),
          mealType: MealType.lunch,
        ),
      ];

      final balance = CalorieCalculator.calculate(entries, 2000);
      // Consumed: 350 + 650 = 1000
      // Burned: 250
      // Remaining: 2000 - 1000 + 250 = 1250
      // Progress: 1000 / 2000 = 0.5
      expect(balance.consumed, 1000);
      expect(balance.burned, 250);
      expect(balance.remaining, 1250);
      expect(balance.isOver, false);
      expect(balance.progress, 0.5);
    });

    test('calculateBalance detects over-target state accurately', () {
      final entries = [
        Entry(
          id: '1',
          type: EntryType.meal,
          title: 'Heavy Feast',
          kcal: 2300,
          createdAt: DateTime(2026, 10, 2, 20, 0),
          mealType: MealType.dinner,
        ),
        Entry(
          id: '2',
          type: EntryType.workout,
          title: 'Short Walk',
          kcal: 100,
          createdAt: DateTime(2026, 10, 2, 21, 0),
          exerciseType: ExerciseType.walking,
          durationMin: 25,
        ),
      ];

      final balance = CalorieCalculator.calculate(entries, 2000);
      // Target: 2000, Consumed: 2300, Burned: 100
      // Remaining: 2000 - 2300 + 100 = -200
      // isOver: true, overAmount: 200
      // Progress: 2300 / 2000 clamped to 1.0
      expect(balance.consumed, 2300);
      expect(balance.burned, 100);
      expect(balance.remaining, -200);
      expect(balance.isOver, true);
      expect(balance.isDeficit, false);
      expect(balance.overAmount, 200);
      expect(balance.progress, 1.0);
    });

    test('calculateBalance correctly calculates calorie deficit and burn progress', () {
      final entries = [
        Entry(
          id: '1',
          type: EntryType.meal,
          title: 'Oats & Berries',
          kcal: 400,
          createdAt: DateTime(2026, 10, 2, 8, 0),
          mealType: MealType.breakfast,
        ),
        Entry(
          id: '2',
          type: EntryType.workout,
          title: 'Cycling',
          kcal: 300,
          createdAt: DateTime(2026, 10, 2, 17, 0),
          exerciseType: ExerciseType.cycling,
          durationMin: 35,
        ),
      ];

      final balance = CalorieCalculator.calculate(entries, 2000);
      // Consumed: 400, Burned: 300
      // Remaining deficit: 2000 - 400 + 300 = 1900
      expect(balance.isDeficit, true);
      expect(balance.isOver, false);
      expect(balance.remaining, 1900);
      expect(balance.consumedProgress, 400 / 2000);
      expect(balance.burnProgress, 300 / 2000);
    });
  });

  group('MetCalculator Tests', () {
    test('estimateBurn computes accurate calories according to MET formula', () {
      // Running MET = 9.8, weight = 70 kg, 30 min (0.5 hour)
      // kcal = 9.8 * 70 * 0.5 = 343 kcal
      final runBurn = MetCalculator.estimateBurn(
        exerciseType: ExerciseType.running,
        durationMin: 30,
        weightKg: 70,
      );
      expect(runBurn, 343);

      // Walking MET = 3.5, weight = 70 kg, 60 min (1.0 hour)
      // kcal = 3.5 * 70 * 1.0 = 245 kcal
      final walkBurn = MetCalculator.estimateBurn(
        exerciseType: ExerciseType.walking,
        durationMin: 60,
        weightKg: 70,
      );
      expect(walkBurn, 245);
    });
  });
}
