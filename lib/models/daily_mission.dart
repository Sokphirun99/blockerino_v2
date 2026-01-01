import 'package:equatable/equatable.dart';

/// Types of daily missions available in the game
enum MissionType {
  clearLines,
  earnScore,
  perfectClears,
  longCombo,
  playGames,
  useChaosMode,
}

/// Represents a daily mission with progress tracking and rewards
class DailyMission extends Equatable {
  final String id;
  final String title;
  final String description;
  final MissionType type;
  final int target;
  final int progress;
  final int coinReward;
  final DateTime expiresAt;
  final bool isCompleted;

  const DailyMission({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    required this.progress,
    required this.coinReward,
    required this.expiresAt,
    this.isCompleted = false,
  });

  /// Progress as a percentage (0.0 to 1.0)
  double get progressPercentage => (progress / target).clamp(0.0, 1.0);

  /// Whether the mission can be claimed (completed but not yet claimed)
  bool get canClaim => progress >= target && !isCompleted;

  /// Create a copy with updated fields
  DailyMission copyWith({
    String? id,
    String? title,
    String? description,
    MissionType? type,
    int? target,
    int? progress,
    int? coinReward,
    DateTime? expiresAt,
    bool? isCompleted,
  }) {
    return DailyMission(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      coinReward: coinReward ?? this.coinReward,
      expiresAt: expiresAt ?? this.expiresAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // ========== Factory Methods ==========

  /// Mission to clear a number of lines
  factory DailyMission.clearLines({required DateTime expiresAt}) {
    return DailyMission(
      id: 'clear_lines_${expiresAt.millisecondsSinceEpoch}',
      title: '🎯 Line Clearer',
      description: 'Clear 50 lines in any game mode',
      type: MissionType.clearLines,
      target: 50,
      progress: 0,
      coinReward: 100,
      expiresAt: expiresAt,
    );
  }

  /// Mission to earn a high score
  factory DailyMission.earnScore({required DateTime expiresAt}) {
    return DailyMission(
      id: 'earn_score_${expiresAt.millisecondsSinceEpoch}',
      title: '💯 High Scorer',
      description: 'Earn 15,000 points in a single game',
      type: MissionType.earnScore,
      target: 15000,
      progress: 0,
      coinReward: 150,
      expiresAt: expiresAt,
    );
  }

  /// Mission to achieve perfect clears
  factory DailyMission.perfectClears({required DateTime expiresAt}) {
    return DailyMission(
      id: 'perfect_clears_${expiresAt.millisecondsSinceEpoch}',
      title: '✨ Perfectionist',
      description: 'Achieve 2 perfect clears (clear entire board)',
      type: MissionType.perfectClears,
      target: 2,
      progress: 0,
      coinReward: 200,
      expiresAt: expiresAt,
    );
  }

  /// Mission to achieve a long combo
  factory DailyMission.longCombo({required DateTime expiresAt}) {
    return DailyMission(
      id: 'long_combo_${expiresAt.millisecondsSinceEpoch}',
      title: '🔥 Combo Master',
      description: 'Reach a combo of 10 or higher',
      type: MissionType.longCombo,
      target: 10,
      progress: 0,
      coinReward: 175,
      expiresAt: expiresAt,
    );
  }

  /// Mission to play multiple games
  factory DailyMission.playGames({required DateTime expiresAt}) {
    return DailyMission(
      id: 'play_games_${expiresAt.millisecondsSinceEpoch}',
      title: '🎮 Dedicated',
      description: 'Play 5 games in any mode',
      type: MissionType.playGames,
      target: 5,
      progress: 0,
      coinReward: 75,
      expiresAt: expiresAt,
    );
  }

  /// Mission to use Chaos mode
  factory DailyMission.useChaosMode({required DateTime expiresAt}) {
    return DailyMission(
      id: 'use_chaos_${expiresAt.millisecondsSinceEpoch}',
      title: '🌪️ Chaos Explorer',
      description: 'Play 3 games in Chaos mode',
      type: MissionType.useChaosMode,
      target: 3,
      progress: 0,
      coinReward: 125,
      expiresAt: expiresAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        target,
        progress,
        coinReward,
        expiresAt,
        isCompleted,
      ];
}
