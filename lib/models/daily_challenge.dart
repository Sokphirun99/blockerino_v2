import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'game_mode.dart';
import 'story_level.dart';
import 'board.dart';

/// Level difficulty tiers like Block Blast
enum LevelTier {
  beginner,    // Levels 1-20: Easy introduction
  easy,        // Levels 21-50: Building skills
  medium,      // Levels 51-100: Moderate challenge
  hard,        // Levels 101-150: Difficult
  expert,      // Levels 151-180: Very challenging
  master,      // Levels 181-200: Extreme difficulty
}

/// Adventure levels library - 200 Block Blast style puzzle levels
/// Each level has specific objectives (score targets, line targets, time limits)
class AdventureLevels {
  static const int totalLevels = 200;

  /// Get level by number (1-200) as a StoryLevel for game integration
  static StoryLevel getLevel(int levelNumber) {
    if (levelNumber < 1 || levelNumber > totalLevels) {
      return _generateLevel(1); // Return level 1 as fallback
    }
    return _generateLevel(levelNumber);
  }

  /// Get all levels
  static List<StoryLevel> get allLevels {
    return List.generate(totalLevels, (i) => _generateLevel(i + 1));
  }

  /// Get levels by tier
  static List<StoryLevel> getLevelsByTier(LevelTier tier) {
    final range = _getTierRange(tier);
    return List.generate(
      range.end - range.start + 1,
      (i) => _generateLevel(range.start + i),
    );
  }

  /// Get tier for a level number
  static LevelTier getTierForLevel(int levelNumber) {
    if (levelNumber <= 20) return LevelTier.beginner;
    if (levelNumber <= 50) return LevelTier.easy;
    if (levelNumber <= 100) return LevelTier.medium;
    if (levelNumber <= 150) return LevelTier.hard;
    if (levelNumber <= 180) return LevelTier.expert;
    return LevelTier.master;
  }

  /// Get tier color
  static int getTierColor(LevelTier tier) {
    switch (tier) {
      case LevelTier.beginner:
        return 0xFF4CAF50; // Green
      case LevelTier.easy:
        return 0xFF8BC34A; // Light Green
      case LevelTier.medium:
        return 0xFFFFEB3B; // Yellow
      case LevelTier.hard:
        return 0xFFFF9800; // Orange
      case LevelTier.expert:
        return 0xFFFF5722; // Deep Orange
      case LevelTier.master:
        return 0xFFE91E63; // Pink/Red
    }
  }

  /// Get tier name
  static String getTierName(LevelTier tier) {
    switch (tier) {
      case LevelTier.beginner:
        return 'Beginner';
      case LevelTier.easy:
        return 'Easy';
      case LevelTier.medium:
        return 'Medium';
      case LevelTier.hard:
        return 'Hard';
      case LevelTier.expert:
        return 'Expert';
      case LevelTier.master:
        return 'Master';
    }
  }

  /// Get tier emoji
  static String getTierEmoji(LevelTier tier) {
    switch (tier) {
      case LevelTier.beginner:
        return '🌱';
      case LevelTier.easy:
        return '🌿';
      case LevelTier.medium:
        return '⚡';
      case LevelTier.hard:
        return '🔥';
      case LevelTier.expert:
        return '💎';
      case LevelTier.master:
        return '👑';
    }
  }

  /// Check if level is unlocked (previous level completed or level 1)
  static bool isLevelUnlocked(int levelNumber, Map<int, int> completedLevels) {
    if (levelNumber == 1) return true;
    // Previous level must have at least 1 star
    return (completedLevels[levelNumber - 1] ?? 0) >= 1;
  }

  static ({int start, int end}) _getTierRange(LevelTier tier) {
    switch (tier) {
      case LevelTier.beginner:
        return (start: 1, end: 20);
      case LevelTier.easy:
        return (start: 21, end: 50);
      case LevelTier.medium:
        return (start: 51, end: 100);
      case LevelTier.hard:
        return (start: 101, end: 150);
      case LevelTier.expert:
        return (start: 151, end: 180);
      case LevelTier.master:
        return (start: 181, end: 200);
    }
  }

  /// Generate a single level with Block Blast-style objectives
  static StoryLevel _generateLevel(int levelNumber) {
    final tier = getTierForLevel(levelNumber);
    final title = _getTitle(levelNumber, tier);
    final difficulty = _getDifficulty(tier);
    final gameMode = _getGameMode(levelNumber, tier);
    final boardSize = gameMode == GameMode.chaos ? 10 : 8;

    // Calculate objectives based on level number and tier
    final targetScore = _calculateTargetScore(levelNumber, tier);
    final targetLines = _calculateTargetLines(levelNumber, tier);
    final timeLimit = _calculateTimeLimit(levelNumber, tier);

    // Calculate star thresholds (1 star = 80%, 2 stars = 100%, 3 stars = 130%)
    final starThreshold1 = (targetScore * 0.8).round();
    final starThreshold2 = targetScore;
    final starThreshold3 = (targetScore * 1.3).round();

    // Calculate coin reward
    final coinReward = _calculateCoinReward(levelNumber, tier);

    // Get restrictions for higher difficulty levels
    final restrictions = _getRestrictions(levelNumber, tier);

    // Generate Block Quest features based on level
    final prefilledBlocks = _generatePrefilledBlocks(levelNumber, tier, boardSize);
    final iceBlocks = _generateIceBlocks(levelNumber, tier, boardSize, prefilledBlocks);
    final starPositions = _generateStarPositions(levelNumber, tier, boardSize, prefilledBlocks, iceBlocks);
    final targetStars = starPositions.isNotEmpty ? starPositions.length : null;

    return StoryLevel(
      levelNumber: levelNumber,
      title: title,
      description: _getDescription(levelNumber, tier, targetScore, targetLines, timeLimit, targetStars),
      story: _getStoryText(levelNumber, tier),
      gameMode: gameMode,
      difficulty: difficulty,
      targetScore: targetScore,
      targetLines: targetLines,
      timeLimit: timeLimit,
      restrictions: restrictions,
      starThreshold1: starThreshold1,
      starThreshold2: starThreshold2,
      starThreshold3: starThreshold3,
      coinReward: coinReward,
      isUnlocked: levelNumber == 1,
      prefilledBlocks: prefilledBlocks,
      iceBlocks: iceBlocks,
      starPositions: starPositions,
      targetStars: targetStars,
    );
  }

  // ===== BLOCK QUEST FEATURES =====

  /// Generate pre-filled blocks based on level
  static List<PrefilledBlock> _generatePrefilledBlocks(int level, LevelTier tier, int boardSize) {
    // Start adding prefilled blocks from level 10
    if (level < 10) return [];

    final random = math.Random(level * 13); // Seeded for consistent levels
    int blockCount;

    switch (tier) {
      case LevelTier.beginner:
        blockCount = 2 + (level - 10) ~/ 3; // 2-5 blocks
        break;
      case LevelTier.easy:
        blockCount = 5 + (level - 21) ~/ 4; // 5-12 blocks
        break;
      case LevelTier.medium:
        blockCount = 10 + (level - 51) ~/ 5; // 10-20 blocks
        break;
      case LevelTier.hard:
        blockCount = 18 + (level - 101) ~/ 6; // 18-26 blocks
        break;
      case LevelTier.expert:
        blockCount = 22 + (level - 151) ~/ 5; // 22-28 blocks
        break;
      case LevelTier.master:
        blockCount = 25 + (level - 181) ~/ 4; // 25-30 blocks
        break;
    }

    // Limit to reasonable amount
    blockCount = blockCount.clamp(0, (boardSize * boardSize * 0.4).round());

    final colors = [
      const Color(0xFF00BFA5), // Teal
      const Color(0xFFFF6B6B), // Coral
      const Color(0xFFFFD93D), // Yellow
      const Color(0xFF6C5CE7), // Purple
      const Color(0xFF74B9FF), // Blue
    ];

    final usedPositions = <String>{};
    final blocks = <PrefilledBlock>[];

    // Generate blocks in clusters for more interesting patterns
    while (blocks.length < blockCount) {
      final row = random.nextInt(boardSize);
      final col = random.nextInt(boardSize);
      final key = '$row-$col';

      if (!usedPositions.contains(key)) {
        usedPositions.add(key);
        blocks.add(PrefilledBlock(
          row: row,
          col: col,
          color: colors[random.nextInt(colors.length)],
        ));
      }
    }

    return blocks;
  }

  /// Generate ice blocks based on level
  static List<IceBlock> _generateIceBlocks(int level, LevelTier tier, int boardSize, List<PrefilledBlock> prefilled) {
    // Start adding ice blocks from level 25
    if (level < 25) return [];

    final random = math.Random(level * 17);
    int iceCount;

    switch (tier) {
      case LevelTier.beginner:
        iceCount = 0;
        break;
      case LevelTier.easy:
        iceCount = 1 + (level - 25) ~/ 5; // 1-5 ice blocks
        break;
      case LevelTier.medium:
        iceCount = 4 + (level - 51) ~/ 6; // 4-12 ice blocks
        break;
      case LevelTier.hard:
        iceCount = 10 + (level - 101) ~/ 7; // 10-17 ice blocks
        break;
      case LevelTier.expert:
        iceCount = 14 + (level - 151) ~/ 5; // 14-20 ice blocks
        break;
      case LevelTier.master:
        iceCount = 18 + (level - 181) ~/ 4; // 18-23 ice blocks
        break;
    }

    // Get positions already used by prefilled blocks
    final usedPositions = prefilled.map((b) => '${b.row}-${b.col}').toSet();
    final blocks = <IceBlock>[];

    while (blocks.length < iceCount) {
      final row = random.nextInt(boardSize);
      final col = random.nextInt(boardSize);
      final key = '$row-$col';

      if (!usedPositions.contains(key)) {
        usedPositions.add(key);
        // Higher levels have more 2-hit ice blocks
        final hits = (random.nextDouble() < 0.3 + (level / 400)) ? 2 : 1;
        blocks.add(IceBlock(row: row, col: col, hits: hits));
      }
    }

    return blocks;
  }

  /// Generate star positions based on level
  static List<StarPosition> _generateStarPositions(int level, LevelTier tier, int boardSize,
      List<PrefilledBlock> prefilled, List<IceBlock> ice) {
    // Start adding stars from level 15
    if (level < 15) return [];

    final random = math.Random(level * 23);
    int starCount;

    switch (tier) {
      case LevelTier.beginner:
        starCount = 1 + (level - 15) ~/ 3; // 1-2 stars
        break;
      case LevelTier.easy:
        starCount = 2 + (level - 21) ~/ 6; // 2-6 stars
        break;
      case LevelTier.medium:
        starCount = 4 + (level - 51) ~/ 8; // 4-10 stars
        break;
      case LevelTier.hard:
        starCount = 6 + (level - 101) ~/ 8; // 6-12 stars
        break;
      case LevelTier.expert:
        starCount = 8 + (level - 151) ~/ 6; // 8-13 stars
        break;
      case LevelTier.master:
        starCount = 10 + (level - 181) ~/ 4; // 10-15 stars
        break;
    }

    // Get positions already used
    final usedPositions = <String>{};
    for (final b in prefilled) {
      usedPositions.add('${b.row}-${b.col}');
    }
    for (final b in ice) {
      usedPositions.add('${b.row}-${b.col}');
    }

    final stars = <StarPosition>[];

    while (stars.length < starCount) {
      final row = random.nextInt(boardSize);
      final col = random.nextInt(boardSize);
      final key = '$row-$col';

      if (!usedPositions.contains(key)) {
        usedPositions.add(key);
        stars.add(StarPosition(row: row, col: col));
      }
    }

    return stars;
  }

  // ===== SCORE CALCULATION =====
  static int _calculateTargetScore(int level, LevelTier tier) {
    switch (tier) {
      case LevelTier.beginner:
        // Levels 1-20: 200 to 1000
        return 200 + ((level - 1) * 40);
      case LevelTier.easy:
        // Levels 21-50: 1000 to 3000
        return 1000 + ((level - 21) * 67);
      case LevelTier.medium:
        // Levels 51-100: 3000 to 8000
        return 3000 + ((level - 51) * 100);
      case LevelTier.hard:
        // Levels 101-150: 8000 to 15000
        return 8000 + ((level - 101) * 140);
      case LevelTier.expert:
        // Levels 151-180: 15000 to 25000
        return 15000 + ((level - 151) * 333);
      case LevelTier.master:
        // Levels 181-200: 25000 to 40000
        return 25000 + ((level - 181) * 750);
    }
  }

  // ===== LINE TARGETS =====
  static int? _calculateTargetLines(int level, LevelTier tier) {
    // Only some levels have line targets (every 3rd level starting from level 5)
    if (level < 5) return null;
    if (level % 3 != 2) return null; // Levels 5, 8, 11, 14...

    switch (tier) {
      case LevelTier.beginner:
        return 5 + ((level - 5) ~/ 3 * 2);
      case LevelTier.easy:
        return 15 + ((level - 23) ~/ 3 * 3);
      case LevelTier.medium:
        return 30 + ((level - 53) ~/ 3 * 4);
      case LevelTier.hard:
        return 60 + ((level - 101) ~/ 3 * 5);
      case LevelTier.expert:
        return 100 + ((level - 152) ~/ 3 * 8);
      case LevelTier.master:
        return 150 + ((level - 182) ~/ 3 * 15);
    }
  }

  // ===== TIME LIMITS =====
  static int? _calculateTimeLimit(int level, LevelTier tier) {
    // Time trials on specific levels (every 5th level starting from level 10)
    if (level < 10) return null;
    if (level % 5 != 0) return null; // Levels 10, 15, 20, 25...

    switch (tier) {
      case LevelTier.beginner:
        return 180; // 3 minutes
      case LevelTier.easy:
        return 150; // 2.5 minutes
      case LevelTier.medium:
        return 120; // 2 minutes
      case LevelTier.hard:
        return 90; // 1.5 minutes
      case LevelTier.expert:
        return 60; // 1 minute
      case LevelTier.master:
        return 45; // 45 seconds
    }
  }

  // ===== COIN REWARDS =====
  static int _calculateCoinReward(int level, LevelTier tier) {
    switch (tier) {
      case LevelTier.beginner:
        return 20 + (level * 3);
      case LevelTier.easy:
        return 50 + ((level - 20) * 4);
      case LevelTier.medium:
        return 150 + ((level - 50) * 5);
      case LevelTier.hard:
        return 400 + ((level - 100) * 8);
      case LevelTier.expert:
        return 800 + ((level - 150) * 15);
      case LevelTier.master:
        return 1500 + ((level - 180) * 50);
    }
  }

  // ===== GAME MODE =====
  static GameMode _getGameMode(int level, LevelTier tier) {
    // Use story mode for proper objective tracking
    // But use chaos board for harder levels
    switch (tier) {
      case LevelTier.beginner:
      case LevelTier.easy:
        return GameMode.story; // Classic 8x8 grid
      case LevelTier.medium:
        // Introduce chaos every 5th level starting from 75
        return (level >= 75 && level % 5 == 0) ? GameMode.chaos : GameMode.story;
      case LevelTier.hard:
        // Every 3rd level is chaos
        return (level % 3 == 0) ? GameMode.chaos : GameMode.story;
      case LevelTier.expert:
        // Every other level is chaos
        return (level % 2 == 0) ? GameMode.chaos : GameMode.story;
      case LevelTier.master:
        // All master levels are chaos
        return GameMode.chaos;
    }
  }

  // ===== DIFFICULTY MAPPING =====
  static LevelDifficulty _getDifficulty(LevelTier tier) {
    switch (tier) {
      case LevelTier.beginner:
      case LevelTier.easy:
        return LevelDifficulty.easy;
      case LevelTier.medium:
        return LevelDifficulty.medium;
      case LevelTier.hard:
        return LevelDifficulty.hard;
      case LevelTier.expert:
      case LevelTier.master:
        return LevelDifficulty.expert;
    }
  }

  // ===== RESTRICTIONS =====
  static List<String> _getRestrictions(int level, LevelTier tier) {
    final restrictions = <String>[];

    // Add restrictions for harder levels
    if (tier == LevelTier.expert && level % 10 == 0) {
      restrictions.add('No power-ups allowed');
    }
    if (tier == LevelTier.master) {
      restrictions.add('Perfect play required');
      if (level >= 190) {
        restrictions.add('No invalid placements');
      }
    }

    return restrictions;
  }

  // ===== DESCRIPTIONS =====
  static String _getDescription(int level, LevelTier tier, int targetScore, int? targetLines, int? timeLimit, int? targetStars) {
    final parts = <String>[];

    parts.add('Score $targetScore');

    if (targetLines != null) {
      parts.add('Clear $targetLines lines');
    }

    if (targetStars != null) {
      parts.add('Collect $targetStars stars');
    }

    if (timeLimit != null) {
      final minutes = timeLimit ~/ 60;
      final seconds = timeLimit % 60;
      if (seconds > 0) {
        parts.add('${minutes}m ${seconds}s');
      } else {
        parts.add('$minutes min');
      }
    }

    return parts.join(' • ');
  }

  // ===== STORY TEXT =====
  static String _getStoryText(int level, LevelTier tier) {
    switch (tier) {
      case LevelTier.beginner:
        return 'Welcome to the adventure! Start your journey here.';
      case LevelTier.easy:
        return 'You\'re getting better! Keep pushing forward.';
      case LevelTier.medium:
        return 'The challenge intensifies. Stay focused!';
      case LevelTier.hard:
        return 'Only the skilled can progress from here.';
      case LevelTier.expert:
        return 'Elite territory. Prove your mastery!';
      case LevelTier.master:
        return 'The ultimate challenge awaits. Become a legend!';
    }
  }

  // ===== LEVEL TITLES =====
  static String _getTitle(int level, LevelTier tier) {
    switch (tier) {
      case LevelTier.beginner:
        return _beginnerTitles[(level - 1) % _beginnerTitles.length];
      case LevelTier.easy:
        return _easyTitles[(level - 21) % _easyTitles.length];
      case LevelTier.medium:
        return _mediumTitles[(level - 51) % _mediumTitles.length];
      case LevelTier.hard:
        return _hardTitles[(level - 101) % _hardTitles.length];
      case LevelTier.expert:
        return _expertTitles[(level - 151) % _expertTitles.length];
      case LevelTier.master:
        return _masterTitles[(level - 181) % _masterTitles.length];
    }
  }

  static const _beginnerTitles = [
    'First Steps', 'Getting Started', 'Easy Does It', 'Baby Steps', 'Warm Up',
    'Learning Curve', 'Practice Run', 'Simple Start', 'Beginner Luck', 'Basic Training',
    'Foundation', 'Building Blocks', 'First Clear', 'Line Breaker', 'Starter Pack',
    'Rookie Move', 'Training Day', 'Early Bird', 'First Win', 'Graduation',
  ];

  static const _easyTitles = [
    'Growing Strong', 'Rising Up', 'Moving Forward', 'Steady Progress', 'On Track',
    'Skill Builder', 'Combo Intro', 'Line Master', 'Score Seeker', 'Point Hunter',
    'Block Party', 'Grid Walker', 'Shape Shifter', 'Pattern Match', 'Quick Learner',
    'Level Up', 'Momentum', 'Flow State', 'Getting Good', 'Almost There',
    'Breakthrough', 'New Heights', 'Stepping Up', 'Cruising', 'Smooth Sailing',
    'Rolling Along', 'In The Zone', 'On Fire', 'Hot Streak', 'Victory Lap',
  ];

  static const _mediumTitles = [
    'Challenge Accepted', 'Real Deal', 'No More Easy', 'Stepping Up', 'Game On',
    'Pressure Test', 'Trial By Fire', 'Proving Ground', 'Serious Business', 'Focus Mode',
    'Concentration', 'Mind Games', 'Strategic Play', 'Think Ahead', 'Plan Attack',
    'Calculated Risk', 'Precision', 'Accuracy Test', 'Timing Is Key', 'Perfect Fit',
    'Puzzle Master', 'Block Wizard', 'Grid Genius', 'Line Legend', 'Combo King',
    'Score Crusher', 'Point Machine', 'Efficiency', 'Optimization', 'Peak Performance',
    'Maximum Output', 'High Gear', 'Turbo Mode', 'Overdrive', 'Beast Mode',
    'Unstoppable', 'Relentless', 'Determined', 'Focused Fire', 'Laser Sharp',
    'Chaos Intro', 'Bigger Grid', 'More Pieces', 'Chaos Rising', 'Storm Coming',
    'Wild Side', 'Unpredictable', 'Adapt Fast', 'Stay Alert', 'Grand Finale',
  ];

  static const _hardTitles = [
    'The Gauntlet', 'Trial of Fire', 'Intense Focus', 'Heavy Hitter', 'No Mercy',
    'Brutal Force', 'Crushing It', 'Domination', 'Supremacy', 'Elite Status',
    'Champion Rise', 'Glory Seeker', 'Legend Mode', 'Epic Battle', 'Boss Fight',
    'Ultimate Test', 'Supreme Challenge', 'Peak Difficulty', 'Max Pressure', 'Final Push',
    'Breaking Point', 'Edge of Glory', 'Last Stand', 'All or Nothing', 'Do or Die',
    'Chaos Storm', 'Grid Fury', 'Block Blitz', 'Line Lightning', 'Combo Thunder',
    'Score Tsunami', 'Point Avalanche', 'Victory Rush', 'Triumph Trail', 'Glory Road',
    'Champion Path', 'Legend Track', 'Master Route', 'Elite Journey', 'Supreme Quest',
    'Ultimate Voyage', 'Epic Expedition', 'Grand Adventure', 'Noble Pursuit', 'Heroic Mission',
    'Valor Test', 'Courage Trial', 'Bravery Check', 'Honor Bound', 'Legacy Builder',
  ];

  static const _expertTitles = [
    'Expert Zone', 'Pro League', 'Elite Arena', 'Master Class', 'Grand Master',
    'Legendary', 'Mythical', 'Immortal', 'Godlike', 'Transcendent',
    'Beyond Limits', 'Infinite Power', 'Eternal Glory', 'Timeless Skill', 'Ageless Mastery',
    'Divine Touch', 'Sacred Art', 'Ancient Wisdom', 'Cosmic Force', 'Universal Power',
    'Galactic Champion', 'Star Warrior', 'Nebula Knight', 'Void Master', 'Eclipse Lord',
    'Shadow King', 'Light Bringer', 'Storm Rider', 'Thunder God', 'Fire Lord',
  ];

  static const _masterTitles = [
    'The Impossible', 'Beyond Human', 'Godhood', 'Perfection', 'Absolute Power',
    'Supreme Being', 'The Pinnacle', 'Ultimate Form', 'Final Evolution', 'Omega Level',
    'True Master', 'Grand Champion', 'Eternal Legend', 'Immortal King', 'Divine Ruler',
    'Cosmic Emperor', 'Universal Lord', 'Infinite Master', 'The One', 'The Ultimate',
  ];
}

// Keep the old DailyChallenge class for backward compatibility
enum ChallengeType {
  clearLines,
  reachScore,
  useNoPowerUps,
  timeTrial,
  perfectStreak,
  comboChain,
}

class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final GameMode gameMode;
  final int targetValue;
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
}
