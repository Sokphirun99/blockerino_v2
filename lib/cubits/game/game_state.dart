import 'package:equatable/equatable.dart';
import '../../models/board.dart';
import '../../models/piece.dart';
import '../../models/game_mode.dart';
import '../../models/story_level.dart';

/// Base class for all game states
abstract class GameState extends Equatable {
  const GameState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state when no game is loaded
class GameInitial extends GameState {
  const GameInitial();
}

/// State when a game is in progress
class GameInProgress extends GameState {
  final Board board;
  final List<Piece> hand;
  final int score;
  final int combo;
  final int lastBrokenLine;
  final GameMode gameMode;
  final bool showInvalidPreview;
  
  // Story mode specific fields
  final StoryLevel? storyLevel;
  final int linesCleared;
  final int timeRemaining; // in seconds, -1 = no limit
  final bool powerUpsDisabled;

  const GameInProgress({
    required this.board,
    required this.hand,
    required this.score,
    required this.combo,
    required this.lastBrokenLine,
    required this.gameMode,
    this.showInvalidPreview = false,
    this.storyLevel,
    this.linesCleared = 0,
    this.timeRemaining = -1,
    this.powerUpsDisabled = false,
  });

  @override
  List<Object?> get props => [
        board,
        hand,
        score,
        combo,
        lastBrokenLine,
        gameMode,
        showInvalidPreview,
        storyLevel,
        linesCleared,
        timeRemaining,
        powerUpsDisabled,
      ];

  GameInProgress copyWith({
    Board? board,
    List<Piece>? hand,
    int? score,
    int? combo,
    int? lastBrokenLine,
    GameMode? gameMode,
    bool? showInvalidPreview,
    StoryLevel? storyLevel,
    int? linesCleared,
    int? timeRemaining,
    bool? powerUpsDisabled,
  }) {
    return GameInProgress(
      board: board ?? this.board,
      hand: hand ?? this.hand,
      score: score ?? this.score,
      combo: combo ?? this.combo,
      lastBrokenLine: lastBrokenLine ?? this.lastBrokenLine,
      gameMode: gameMode ?? this.gameMode,
      showInvalidPreview: showInvalidPreview ?? this.showInvalidPreview,
      storyLevel: storyLevel ?? this.storyLevel,
      linesCleared: linesCleared ?? this.linesCleared,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      powerUpsDisabled: powerUpsDisabled ?? this.powerUpsDisabled,
    );
  }
}

/// State when the game is over
class GameOver extends GameState {
  final Board board;
  final int finalScore;
  final GameMode gameMode;
  final StoryLevel? storyLevel;
  final int starsEarned;
  final bool levelCompleted; // true if objectives met, false if failed

  const GameOver({
    required this.board,
    required this.finalScore,
    required this.gameMode,
    this.storyLevel,
    this.starsEarned = 0,
    this.levelCompleted = false,
  });

  @override
  List<Object?> get props => [board, finalScore, gameMode, storyLevel, starsEarned, levelCompleted];
}

/// State when loading a saved game
class GameLoading extends GameState {
  const GameLoading();
}
