import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/log_repository.dart';
import '../logic/calorie_calculator.dart';
import '../models/balance.dart';
import '../models/entry.dart';

/// Singleton-like repository provider.
final repositoryProvider = Provider<LogRepository>((ref) {
  return LogRepository();
});

/// Notifier managing the selected calendar date.
/// Meets F11: Date selector (previous/next day arrows + picker).
final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void setDate(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }

  void nextDay() {
    state = state.add(const Duration(days: 1));
  }

  void previousDay() {
    state = state.subtract(const Duration(days: 1));
  }

  void setToday() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, now.day);
  }

  bool get isToday {
    final now = DateTime.now();
    return state.year == now.year && state.month == now.month && state.day == now.day;
  }
}

/// Persistent daily target calories notifier (F9).
final targetProvider = AsyncNotifierProvider<TargetNotifier, int>(
  TargetNotifier.new,
);

class TargetNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final repo = ref.watch(repositoryProvider);
    return repo.getTargetCalorie();
  }

  Future<void> setTarget(int newTarget) async {
    final repo = ref.read(repositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.saveTargetCalorie(newTarget);
      return newTarget;
    });
  }
}

/// Persistent user weight notifier in kg (used for MET calculation).
final weightProvider = AsyncNotifierProvider<WeightNotifier, double>(
  WeightNotifier.new,
);

class WeightNotifier extends AsyncNotifier<double> {
  @override
  Future<double> build() async {
    final repo = ref.watch(repositoryProvider);
    return repo.getUserWeight();
  }

  Future<void> setWeight(double newWeight) async {
    final repo = ref.read(repositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.saveUserWeight(newWeight);
      return newWeight;
    });
  }
}

/// Core day log notifier (R4, R7, R9, R10).
/// Reactive to selected date and persists writes asynchronously.
final dayLogProvider = AsyncNotifierProvider<DayLogNotifier, List<Entry>>(
  DayLogNotifier.new,
);

class DayLogNotifier extends AsyncNotifier<List<Entry>> {
  @override
  Future<List<Entry>> build() async {
    final date = ref.watch(selectedDateProvider);
    final repo = ref.watch(repositoryProvider);
    return repo.getEntriesForDate(date);
  }

  /// Add entry asynchronously and refresh state.
  Future<void> addEntry(Entry entry) async {
    final date = ref.read(selectedDateProvider);
    final repo = ref.read(repositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return repo.addEntry(date, entry);
    });
  }

  /// Update entry asynchronously.
  Future<void> updateEntry(Entry entry) async {
    final date = ref.read(selectedDateProvider);
    final repo = ref.read(repositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return repo.updateEntry(date, entry);
    });
  }

  /// Delete entry asynchronously (F5, R9).
  Future<void> deleteEntry(String entryId) async {
    final date = ref.read(selectedDateProvider);
    final repo = ref.read(repositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return repo.deleteEntry(date, entryId);
    });
  }

  /// Restore an entry after undo (F13).
  Future<void> restoreEntry(Entry entry) async {
    final date = ref.read(selectedDateProvider);
    final repo = ref.read(repositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return repo.addEntry(date, entry);
    });
  }
}

/// Derived async balance provider (R3, R4, R7).
/// Watches dayLogProvider and targetProvider, computes net balance.
final balanceProvider = FutureProvider<Balance>((ref) async {
  final entries = await ref.watch(dayLogProvider.future);
  final targetAsync = ref.watch(targetProvider);
  final target = targetAsync.value ?? 2000;
  return CalorieCalculator.calculate(entries, target);
});

/// Theme mode provider for instant Light / Dark mode switching.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
    } else {
      state = ThemeMode.dark;
    }
  }

  void setTheme(ThemeMode mode) => state = mode;
}
