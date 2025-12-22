import 'game_mode.dart';
import 'dart:math' as math;

enum ChallengeType {
  clearLines,      // Clear X lines
  reachScore,      // Reach score X
  useNoPowerUps,   // Complete without power-ups
  timeTrial,       // Complete in X seconds
  perfectStreak,   // Clear X lines in a row
  comboChain,      // Achieve X combo
}

class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final GameMode gameMode;
  final int targetValue; // Lines to clear, score to reach, etc.
  final int rewardCoins;
  final DateTime date;
  final bool completed;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.gameMode,
    required this.targetValue,
    required this.rewardCoins,
    required this.date,
    this.completed = false,
  });

  DailyChallenge copyWith({
    String? id,
    String? title,
    String? description,
    ChallengeType? type,
    GameMode? gameMode,
    int? targetValue,
    int? rewardCoins,
    DateTime? date,
    bool? completed,
  }) {
    return DailyChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      gameMode: gameMode ?? this.gameMode,
      targetValue: targetValue ?? this.targetValue,
      rewardCoins: rewardCoins ?? this.rewardCoins,
      date: date ?? this.date,
      completed: completed ?? this.completed,
    );
  }

  // Generate a daily challenge based on current date
  static DailyChallenge generateForDate(DateTime date) {
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final random = math.Random(seed);
    final challengeIndex = random.nextInt(10);

    final challenges = [
      DailyChallenge(
        id: 'daily_${date.toIso8601String().split('T')[0]}',
        title: 'Line Master',
        description: 'Clear 20 lines in Classic mode',
        type: ChallengeType.clearLines,
        gameMode: GameMode.classic,
        targetValue: 20,
        rewardCoins: 100,
        date: date,
      ),
      DailyChallenge(
        id: 'daily_${date.toIso8601String().split('T')[0]}',
        title: 'Score Hunter',
        description: 'Reach 5000 points in Chaos mode',
        type: ChallengeType.reachScore,
        gameMode: GameMode.chaos,
        targetValue: 5000,
        rewardCoins: 150,
        date: date,
      ),
      DailyChallenge(
        id: 'daily_${date.toIso8601String().split('T')[0]}',
        title: 'Purist',
        description: 'Complete a game without using power-ups',
        type: ChallengeType.useNoPowerUps,
        gameMode: GameMode.classic,
        targetValue: 1,
        rewardCoins: 200,
        date: date,
      ),
      DailyChallenge(
        id: 'daily_${date.toIso8601String().split('T')[0]}',
        title: 'Speed Runner',
        description: 'Clear 10 lines in under 60 seconds',
        type: ChallengeType.timeTrial,
        gameMode: GameMode.classic,
        targetValue: 60,
        rewardCoins: 175,
        date: date,
      ),
      DailyChallenge(
        id: 'daily_${date.toIso8601String().split('T')[0]}',
        title: 'Perfect Streak',
        description: 'Clear 5 consecutive lines without errors',
        type: ChallengeType.perfectStreak,
        gameMode: GameMode.classic,
        targetValue: 5,
        rewardCoins: 125,
        date: date,
      ),
      DailyChallenge(
        id: 'daily_${date.toIso8601String().split('T')[0]}',
        title: 'Combo King',
        description: 'Achieve a x10 combo in Chaos mode',
        type: ChallengeType.comboChain,
        gameMode: GameMode.chaos,
        targetValue: 10,
        rewardCoins: 180,
        date: date,
      ),
      DailyChallenge(
        id: 'daily_${date.toIso8601String().split('T')[0]}',
        title: 'Marathon',
        description: 'Clear 50 lines in Classic mode',
        type: ChallengeType.clearLines,
        gameMode: GameMode.classic,
        targetValue: 50,
        rewardCoins: 250,
        date: date,
      ),
      DailyChallenge(
        id: 'daily_${date.toIso8601String().split('T')[0]}',
        title: 'High Roller',
        description: 'Reach 10000 points in any mode',
        type: ChallengeType.reachScore,
        gameMode: GameMode.chaos,
        targetValue: 10000,
        rewardCoins: 300,
        date: date,
      ),
      DailyChallenge(
        id: 'daily_${date.toIso8601String().split('T')[0]}',
        title: 'Quick Clear',
        description: 'Clear 5 lines in under 20 seconds',
        type: ChallengeType.timeTrial,
        gameMode: GameMode.classic,
        targetValue: 20,
        rewardCoins: 150,
        date: date,
      ),
      DailyChallenge(
        id: 'daily_${date.toIso8601String().split('T')[0]}',
        title: 'Combo Master',
        description: 'Achieve a x15 combo',
        type: ChallengeType.comboChain,
        gameMode: GameMode.chaos,
        targetValue: 15,
        rewardCoins: 220,
        date: date,
      ),
    ];

    return challenges[challengeIndex];
  }
}
