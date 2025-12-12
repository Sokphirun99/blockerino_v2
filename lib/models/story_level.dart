import 'game_mode.dart';

enum LevelDifficulty {
  easy,
  medium,
  hard,
  expert,
}

class StoryLevel {
  final int levelNumber;
  final String title;
  final String description;
  final String story;
  final GameMode gameMode;
  final LevelDifficulty difficulty;
  final int targetScore;
  final int? targetLines;
  final int? timeLimit; // in seconds, null = no limit
  final List<String> restrictions; // e.g., "No power-ups", "Only 2 pieces per hand"
  final int starThreshold1; // Score for 1 star
  final int starThreshold2; // Score for 2 stars
  final int starThreshold3; // Score for 3 stars
  final int coinReward;
  final bool isUnlocked;
  final int starsEarned;

  const StoryLevel({
    required this.levelNumber,
    required this.title,
    required this.description,
    required this.story,
    required this.gameMode,
    required this.difficulty,
    required this.targetScore,
    this.targetLines,
    this.timeLimit,
    this.restrictions = const [],
    required this.starThreshold1,
    required this.starThreshold2,
    required this.starThreshold3,
    required this.coinReward,
    this.isUnlocked = false,
    this.starsEarned = 0,
  });

  StoryLevel copyWith({
    int? levelNumber,
    String? title,
    String? description,
    String? story,
    GameMode? gameMode,
    LevelDifficulty? difficulty,
    int? targetScore,
    int? targetLines,
    int? timeLimit,
    List<String>? restrictions,
    int? starThreshold1,
    int? starThreshold2,
    int? starThreshold3,
    int? coinReward,
    bool? isUnlocked,
    int? starsEarned,
  }) {
    return StoryLevel(
      levelNumber: levelNumber ?? this.levelNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      story: story ?? this.story,
      gameMode: gameMode ?? this.gameMode,
      difficulty: difficulty ?? this.difficulty,
      targetScore: targetScore ?? this.targetScore,
      targetLines: targetLines ?? this.targetLines,
      timeLimit: timeLimit ?? this.timeLimit,
      restrictions: restrictions ?? this.restrictions,
      starThreshold1: starThreshold1 ?? this.starThreshold1,
      starThreshold2: starThreshold2 ?? this.starThreshold2,
      starThreshold3: starThreshold3 ?? this.starThreshold3,
      coinReward: coinReward ?? this.coinReward,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      starsEarned: starsEarned ?? this.starsEarned,
    );
  }

  static const List<StoryLevel> allLevels = [
    // World 1: Tutorial
    StoryLevel(
      levelNumber: 1,
      title: 'First Steps',
      description: 'Learn the basics of block placement',
      story: 'Welcome to Blockerino! Let\'s start your journey...',
      gameMode: GameMode.story,
      difficulty: LevelDifficulty.easy,
      targetScore: 300,
      starThreshold1: 300,
      starThreshold2: 500,
      starThreshold3: 700,
      coinReward: 50,
      isUnlocked: true,
    ),
    StoryLevel(
      levelNumber: 2,
      title: 'Line Breaker',
      description: 'Clear multiple lines to win',
      story: 'Now try clearing multiple lines at once for bonus points!',
      gameMode: GameMode.story,
      difficulty: LevelDifficulty.easy,
      targetScore: 600,
      starThreshold1: 600,
      starThreshold2: 1000,
      starThreshold3: 1400,
      coinReward: 75,
    ),
    StoryLevel(
      levelNumber: 3,
      title: 'Combo Master',
      description: 'Learn to create combos',
      story: 'Combos multiply your score. Can you chain them?',
      gameMode: GameMode.story,
      difficulty: LevelDifficulty.medium,
      targetScore: 1200,
      starThreshold1: 1200,
      starThreshold2: 1800,
      starThreshold3: 2500,
      coinReward: 100,
    ),
    
    // World 2: Chaos Introduction
    StoryLevel(
      levelNumber: 4,
      title: 'Embrace Chaos',
      description: 'Try the Chaos mode',
      story: 'Things are about to get wild! In Chaos mode, anything can happen.',
      gameMode: GameMode.chaos,
      difficulty: LevelDifficulty.medium,
      targetScore: 1500,
      starThreshold1: 1500,
      starThreshold2: 2200,
      starThreshold3: 3000,
      coinReward: 150,
    ),
    StoryLevel(
      levelNumber: 5,
      title: 'Speed Run',
      description: 'Race against time',
      story: 'Can you think fast enough? Complete this level quickly!',
      gameMode: GameMode.story,
      difficulty: LevelDifficulty.medium,
      targetScore: 2000,
      timeLimit: 180,
      starThreshold1: 2000,
      starThreshold2: 2800,
      starThreshold3: 3500,
      coinReward: 200,
    ),
    
    // World 3: Expert Challenges
    StoryLevel(
      levelNumber: 6,
      title: 'Purist Challenge',
      description: 'No mistakes allowed',
      story: 'Every move counts. Can you achieve perfection?',
      gameMode: GameMode.story,
      difficulty: LevelDifficulty.hard,
      targetScore: 3000,
      restrictions: ['No invalid placements allowed', 'Perfect play only'],
      starThreshold1: 3000,
      starThreshold2: 4200,
      starThreshold3: 6000,
      coinReward: 300,
    ),
    StoryLevel(
      levelNumber: 7,
      title: 'Marathon',
      description: 'Endurance test',
      story: 'How long can you survive? This is the ultimate test!',
      gameMode: GameMode.chaos,
      difficulty: LevelDifficulty.hard,
      targetScore: 5000,
      starThreshold1: 5000,
      starThreshold2: 7000,
      starThreshold3: 10000,
      coinReward: 500,
    ),
    StoryLevel(
      levelNumber: 8,
      title: 'Master\'s Trial',
      description: 'The final challenge',
      story: 'You\'ve come so far. Now face the ultimate challenge!',
      gameMode: GameMode.chaos,
      difficulty: LevelDifficulty.expert,
      targetScore: 8000,
      timeLimit: 300,
      starThreshold1: 8000,
      starThreshold2: 12000,
      starThreshold3: 18000,
      coinReward: 1000,
    ),
  ];
}
