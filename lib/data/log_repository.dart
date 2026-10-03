import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/entry.dart';

/// Repository handling persistent local storage using SharedPreferences.
/// Meets R10: Local storage for offline access.
class LogRepository {
  static const String _keyPrefix = 'fittrail_log_';
  static const String _targetKey = 'fittrail_target_kcal';
  static const String _weightKey = 'fittrail_user_weight_kg';

  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  String _formatDateKey(DateTime date) {
    return '$_keyPrefix${_dateFormatter.format(date)}';
  }

  /// Load all entries for a specific calendar date.
  Future<List<Entry>> getEntriesForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _formatDateKey(date);
    final rawJson = prefs.getString(key);

    if (rawJson == null || rawJson.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = json.decode(rawJson) as List<dynamic>;
      return decoded.map((item) => Entry.fromMap(item as Map<String, dynamic>)).toList();
    } catch (e) {
      // In case of corrupt local storage entry, return safe empty list
      return [];
    }
  }

  /// Save the full entries list for a specific calendar date.
  Future<void> saveEntriesForDate(DateTime date, List<Entry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _formatDateKey(date);
    final jsonString = json.encode(entries.map((e) => e.toMap()).toList());
    await prefs.setString(key, jsonString);
  }

  /// Add a new entry to the given date and return the updated entries list.
  Future<List<Entry>> addEntry(DateTime date, Entry entry) async {
    final currentEntries = await getEntriesForDate(date);
    // Insert at front so newest entries appear on top
    final updated = [entry, ...currentEntries];
    await saveEntriesForDate(date, updated);
    return updated;
  }

  /// Update an existing entry.
  Future<List<Entry>> updateEntry(DateTime date, Entry entry) async {
    final currentEntries = await getEntriesForDate(date);
    final updated = currentEntries.map((e) => e.id == entry.id ? entry : e).toList();
    await saveEntriesForDate(date, updated);
    return updated;
  }

  /// Delete an entry by ID.
  Future<List<Entry>> deleteEntry(DateTime date, String entryId) async {
    final currentEntries = await getEntriesForDate(date);
    final updated = currentEntries.where((e) => e.id != entryId).toList();
    await saveEntriesForDate(date, updated);
    return updated;
  }

  /// Get daily target calorie setting (default: 2000).
  Future<int> getTargetCalorie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_targetKey) ?? 2000;
  }

  /// Save daily target calorie setting.
  Future<void> saveTargetCalorie(int target) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_targetKey, target);
  }

  /// Get user weight in kg (default: 70.0).
  Future<double> getUserWeight() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_weightKey) ?? 70.0;
  }

  /// Save user weight in kg.
  Future<void> saveUserWeight(double weight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_weightKey, weight);
  }
}
