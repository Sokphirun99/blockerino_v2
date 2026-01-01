import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_mission.dart';

/// Service for managing daily missions
/// Handles generation, persistence, progress tracking, and rewards
class MissionService {
  static const String _storageKey = 'daily_missions';
  static const String _lastGeneratedKey = 'missions_last_generated';

  /// Get today's daily missions
  /// Generates new missions if none exist for today
  Future<List<DailyMission>> getDailyMissions() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = _formatDate(today);

    // Check if missions were generated today
    final lastGenerated = prefs.getString(_lastGeneratedKey);

    if (lastGenerated != todayString) {
      // Generate new missions for today
      final missions = _generateRandomMissions(today);
      await _saveMissions(missions);
      await prefs.setString(_lastGeneratedKey, todayString);
      debugPrint('🎯 Generated new daily missions for $todayString');
      return missions;
    }

    // Load existing missions
    return _loadMissions();
  }

  /// Generate 3 random missions for today
  List<DailyMission> _generateRandomMissions(DateTime today) {
    // Calculate tomorrow midnight for expiration
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final expiresAt = tomorrow;

    // Create all mission types
    final allMissions = [
      DailyMission.clearLines(expiresAt: expiresAt),
      DailyMission.earnScore(expiresAt: expiresAt),
      DailyMission.perfectClears(expiresAt: expiresAt),
      DailyMission.longCombo(expiresAt: expiresAt),
      DailyMission.playGames(expiresAt: expiresAt),
      DailyMission.useChaosMode(expiresAt: expiresAt),
    ];

    // Shuffle and take 3 random missions
    final random = Random();
    allMissions.shuffle(random);
    return allMissions.take(3).toList();
  }

  /// Update progress for a specific mission
  Future<void> updateMissionProgress(String id, int newProgress) async {
    final missions = await _loadMissions();
    final index = missions.indexWhere((m) => m.id == id);

    if (index == -1) {
      debugPrint('⚠️ Mission not found: $id');
      return;
    }

    final mission = missions[index];
    
    // Don't update if already completed
    if (mission.isCompleted) return;

    // Update progress
    final updatedMission = mission.copyWith(
      progress: newProgress,
      isCompleted: newProgress >= mission.target ? mission.isCompleted : false,
    );

    missions[index] = updatedMission;
    await _saveMissions(missions);

    debugPrint('📊 Mission progress: ${mission.title} - $newProgress/${mission.target}');
  }

  /// Update progress by adding to current value
  Future<void> addMissionProgress(MissionType type, int amount) async {
    final missions = await _loadMissions();

    for (int i = 0; i < missions.length; i++) {
      final mission = missions[i];
      
      if (mission.type == type && !mission.isCompleted) {
        final newProgress = mission.progress + amount;
        missions[i] = mission.copyWith(progress: newProgress);
        debugPrint('📊 Mission progress: ${mission.title} - $newProgress/${mission.target}');
      }
    }

    await _saveMissions(missions);
  }

  /// Track high score for earnScore missions
  Future<void> trackHighScore(int score) async {
    final missions = await _loadMissions();

    for (int i = 0; i < missions.length; i++) {
      final mission = missions[i];
      
      if (mission.type == MissionType.earnScore && !mission.isCompleted) {
        // For high score, we track the maximum achieved
        if (score > mission.progress) {
          missions[i] = mission.copyWith(progress: score);
          debugPrint('📊 High score tracked: ${mission.title} - $score/${mission.target}');
        }
      }
    }

    await _saveMissions(missions);
  }

  /// Track max combo for longCombo missions
  Future<void> trackMaxCombo(int combo) async {
    final missions = await _loadMissions();

    for (int i = 0; i < missions.length; i++) {
      final mission = missions[i];
      
      if (mission.type == MissionType.longCombo && !mission.isCompleted) {
        // For combo, we track the maximum achieved
        if (combo > mission.progress) {
          missions[i] = mission.copyWith(progress: combo);
          debugPrint('📊 Max combo tracked: ${mission.title} - $combo/${mission.target}');
        }
      }
    }

    await _saveMissions(missions);
  }

  /// Claim reward for a completed mission
  /// Returns the coin reward amount, or 0 if not claimable
  Future<int> claimReward(String id) async {
    final missions = await _loadMissions();
    final index = missions.indexWhere((m) => m.id == id);

    if (index == -1) {
      debugPrint('⚠️ Mission not found: $id');
      return 0;
    }

    final mission = missions[index];

    // Check if can claim
    if (!mission.canClaim) {
      debugPrint('⚠️ Mission cannot be claimed: ${mission.title}');
      return 0;
    }

    // Mark as completed
    missions[index] = mission.copyWith(isCompleted: true);
    await _saveMissions(missions);

    debugPrint('🎁 Claimed reward: ${mission.coinReward} coins for ${mission.title}');
    return mission.coinReward;
  }

  /// Load missions from storage
  Future<List<DailyMission>> _loadMissions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => _missionFromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error loading missions: $e');
      return [];
    }
  }

  /// Save missions to storage
  Future<void> _saveMissions(List<DailyMission> missions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = missions.map((m) => _missionToJson(m)).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  /// Convert mission to JSON
  Map<String, dynamic> _missionToJson(DailyMission mission) {
    return {
      'id': mission.id,
      'title': mission.title,
      'description': mission.description,
      'type': mission.type.index,
      'target': mission.target,
      'progress': mission.progress,
      'coinReward': mission.coinReward,
      'expiresAt': mission.expiresAt.millisecondsSinceEpoch,
      'isCompleted': mission.isCompleted,
    };
  }

  /// Convert JSON to mission
  DailyMission _missionFromJson(Map<String, dynamic> json) {
    return DailyMission(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: MissionType.values[json['type'] as int],
      target: json['target'] as int,
      progress: json['progress'] as int,
      coinReward: json['coinReward'] as int,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int),
      isCompleted: json['isCompleted'] as bool,
    );
  }

  /// Format date as 'yyyy-MM-dd' for comparison
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Clear all missions (for testing/reset)
  Future<void> clearMissions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_lastGeneratedKey);
    debugPrint('🗑️ Cleared all daily missions');
  }
}
