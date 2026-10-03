import 'dart:convert';

/// Represents the type of entry logged: meal or workout.
enum EntryType {
  meal,
  workout,
}

/// Category of meal logged.
enum MealType {
  breakfast('Breakfast', '🍳'),
  lunch('Lunch', '🥗'),
  dinner('Dinner', '🍲'),
  snack('Snack', '🍎');

  final String label;
  final String icon;
  const MealType(this.label, this.icon);

  static MealType fromString(String? value) {
    if (value == null) return MealType.breakfast;
    return MealType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MealType.breakfast,
    );
  }
}

/// Category of exercise performed with standardized MET values.
enum ExerciseType {
  walking('Walking', 3.5, '🚶'),
  running('Running', 9.8, '🏃'),
  cycling('Cycling', 7.5, '🚴'),
  gym('Gym / Weights', 5.0, '🏋️'),
  yoga('Yoga', 3.0, '🧘'),
  swimming('Swimming', 6.0, '🏊'),
  other('Other', 4.0, '⚡');

  final String label;
  final double met;
  final String icon;
  const ExerciseType(this.label, this.met, this.icon);

  static ExerciseType fromString(String? value) {
    if (value == null) return ExerciseType.walking;
    return ExerciseType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ExerciseType.walking,
    );
  }
}

/// Core Entry model representing either a Meal or a Workout.
class Entry {
  final String id;
  final EntryType type;
  final String title;
  final int kcal;
  final DateTime createdAt;

  // Meal specific
  final MealType? mealType;

  // Workout specific
  final ExerciseType? exerciseType;
  final int? durationMin;

  const Entry({
    required this.id,
    required this.type,
    required this.title,
    required this.kcal,
    required this.createdAt,
    this.mealType,
    this.exerciseType,
    this.durationMin,
  });

  bool get isMeal => type == EntryType.meal;
  bool get isWorkout => type == EntryType.workout;

  Entry copyWith({
    String? id,
    EntryType? type,
    String? title,
    int? kcal,
    DateTime? createdAt,
    MealType? mealType,
    ExerciseType? exerciseType,
    int? durationMin,
  }) {
    return Entry(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      kcal: kcal ?? this.kcal,
      createdAt: createdAt ?? this.createdAt,
      mealType: mealType ?? this.mealType,
      exerciseType: exerciseType ?? this.exerciseType,
      durationMin: durationMin ?? this.durationMin,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'kcal': kcal,
      'createdAt': createdAt.toIso8601String(),
      'mealType': mealType?.name,
      'exerciseType': exerciseType?.name,
      'durationMin': durationMin,
    };
  }

  factory Entry.fromMap(Map<String, dynamic> map) {
    final type = map['type'] == 'workout' ? EntryType.workout : EntryType.meal;
    return Entry(
      id: map['id'] as String,
      type: type,
      title: map['title'] as String,
      kcal: (map['kcal'] as num).toInt(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      mealType: map['mealType'] != null ? MealType.fromString(map['mealType'] as String) : null,
      exerciseType: map['exerciseType'] != null ? ExerciseType.fromString(map['exerciseType'] as String) : null,
      durationMin: (map['durationMin'] as num?)?.toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Entry.fromJson(String source) => Entry.fromMap(json.decode(source) as Map<String, dynamic>);
}
