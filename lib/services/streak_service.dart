import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_streak.dart';

/// Service for managing daily login streaks
class StreakService {
  static const String _storageKey = 'daily_streak';

  /// Get the current streak data
  Future<DailyStreak> getStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        return const DailyStreak();
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return DailyStreak.fromJson(json);
    } catch (e) {
      debugPrint('❌ Error loading streak: $e');
      return const DailyStreak();
    }
  }

  /// Record that the player played today
  /// Updates streak and returns the updated data
  Future<DailyStreak> recordPlayToday() async {
    final currentStreak = await getStreak();
    final updatedStreak = currentStreak.updateForToday();

    await _saveStreak(updatedStreak);

    if (updatedStreak.currentStreak > currentStreak.currentStreak) {
      debugPrint('🔥 Streak increased to ${updatedStreak.currentStreak}!');
    } else if (updatedStreak.currentStreak < currentStreak.currentStreak) {
      debugPrint('💔 Streak reset to ${updatedStreak.currentStreak}');
    }

    return updatedStreak;
  }

  /// Save streak to SharedPreferences
  Future<void> _saveStreak(DailyStreak streak) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(streak.toJson());
      await prefs.setString(_storageKey, jsonString);
      debugPrint('💾 Streak saved: ${streak.currentStreak} days');
    } catch (e) {
      debugPrint('❌ Error saving streak: $e');
    }
  }

  /// Clear streak data (for testing/reset)
  Future<void> clearStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    debugPrint('🗑️ Streak cleared');
  }
}
