import 'game_mode.dart';
import 'board.dart';

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
  final List<String>
      restrictions; // e.g., "No power-ups", "Only 2 pieces per hand"
  final int starThreshold1; // Score for 1 star
  final int starThreshold2; // Score for 2 stars
  final int starThreshold3; // Score for 3 stars
  final int coinReward;
  final bool isUnlocked;
  final int starsEarned;

  // Block Quest features
  final List<PrefilledBlock> prefilledBlocks; // Pre-filled blocks at level start
  final List<IceBlock> iceBlocks; // Ice blocks that need 2 clears
  final List<StarPosition> starPositions; // Stars to collect
  final int? targetStars; // Number of stars to collect (objective)

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
    this.prefilledBlocks = const [],
    this.iceBlocks = const [],
    this.starPositions = const [],
    this.targetStars,
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
    List<PrefilledBlock>? prefilledBlocks,
    List<IceBlock>? iceBlocks,
    List<StarPosition>? starPositions,
    int? targetStars,
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
      prefilledBlocks: prefilledBlocks ?? this.prefilledBlocks,
      iceBlocks: iceBlocks ?? this.iceBlocks,
      starPositions: starPositions ?? this.starPositions,
      targetStars: targetStars ?? this.targetStars,
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
      starThreshold1: 250, // 1 star: Below target (allow some leniency)
      starThreshold2: 300, // 2 stars: Reach target (completion)
      starThreshold3: 500, // 3 stars: Exceed target significantly
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
      starThreshold1: 500, // 1 star: Below target
      starThreshold2: 600, // 2 stars: Reach target
      starThreshold3: 1000, // 3 stars: Exceed target
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
      starThreshold1: 1000, // 1 star: Below target
      starThreshold2: 1200, // 2 stars: Reach target
      starThreshold3: 1800, // 3 stars: Exceed target
      coinReward: 100,
    ),

    // World 2: Chaos Introduction
    StoryLevel(
      levelNumber: 4,
      title: 'Embrace Chaos',
      description: 'Try the Chaos mode',
      story:
          'Things are about to get wild! In Chaos mode, anything can happen.',
      gameMode: GameMode.chaos,
      difficulty: LevelDifficulty.medium,
      targetScore: 1500,
      starThreshold1: 1300, // 1 star: Below target
      starThreshold2: 1500, // 2 stars: Reach target
      starThreshold3: 2200, // 3 stars: Exceed target
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
      starThreshold1: 1700, // 1 star: Below target
      starThreshold2: 2000, // 2 stars: Reach target
      starThreshold3: 2800, // 3 stars: Exceed target
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
      starThreshold1: 2600, // 1 star: Below target
      starThreshold2: 3000, // 2 stars: Reach target
      starThreshold3: 4200, // 3 stars: Exceed target
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
      starThreshold1: 4300, // 1 star: Below target
      starThreshold2: 5000, // 2 stars: Reach target
      starThreshold3: 7000, // 3 stars: Exceed target
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
      starThreshold1: 7000, // 1 star: Below target
      starThreshold2: 8000, // 2 stars: Reach target
      starThreshold3: 12000, // 3 stars: Exceed target
      coinReward: 1000,
    ),
  ];
}
