import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import '../../models/board.dart';
import '../../models/piece.dart';
import '../../models/game_mode.dart';
import '../../models/story_level.dart';
import '../../models/power_up.dart';
import '../../services/sound_service.dart';
import '../../services/mission_service.dart';
import '../../services/scoring_service.dart';
import '../../services/piece_generation_service.dart';
import '../../services/power_up_service.dart';
import '../../models/daily_mission.dart';
import '../settings/settings_cubit.dart';
import 'game_state.dart';

/// Callback type for line clear events with particle info
typedef LineClearCallback = void Function(
    List<ClearedBlockInfo> clearedBlocks, int lineCount);

/// Saved game state for a specific mode
class _SavedGameState {
  final Board board;
  final List<Piece> hand;
  final int score;
  final int combo;
  final int lastBrokenLine;
  final bool gameOver;
  final List<int> pieceBag; // Save bag state to prevent reroll exploits
  final int bagIndex; // Save bag index
  final int
      bagRefillCount; // Save bag refill count for rotating distribution fairness

  _SavedGameState({
    required this.board,
    required this.hand,
    required this.score,
    required this.combo,
    required this.lastBrokenLine,
    required this.gameOver,
    required this.pieceBag,
    required this.bagIndex,
    required this.bagRefillCount,
  });
}

class GameCubit extends Cubit<GameState> {
  // Chaos Mode constants
  static const int _chaosEventMinMoves = 10;
  static const int _chaosEventInterval = 18;
  static const int _chaosEventDuration = 5;
  static const double _chaosEventProbability = 0.5;

  final SettingsCubit? settingsCubit;

  // Services
  final SoundService _soundService = SoundService();
  final ScoringService _scoringService = ScoringService();
  final PieceGenerationService _pieceService = PieceGenerationService();
  late final PowerUpService _powerUpService;

  // Separate saved states for each game mode
  final Map<GameMode, _SavedGameState> _savedGames = {};

  // Chaos Mode event tracking
  int _moveCount = 0;
  bool _doublePointsActive = false;
  int _doublePointsLeft = 0;

  // Mission tracking
  int _perfectClearCount = 0;
  int _maxComboReached = 0;
  final MissionService _missionService = MissionService();

  // Story mode timer
  Timer? _storyTimer;

  // Flag to prevent duplicate story level completion
  bool _isEndingStoryLevel = false;

  /// Callback for when lines are cleared (for particle effects)
  LineClearCallback? onLinesCleared;

  // CRITICAL FIX: Track if saved games are still loading
  bool _savedGamesLoaded = false;
  final Completer<void> _savedGamesLoadCompleter = Completer<void>();

  GameCubit({this.settingsCubit}) : super(const GameInitial()) {
    // Initialize power-up service with dependencies
    _powerUpService = PowerUpService(
      soundService: _soundService,
      pieceService: _pieceService,
    );

    // Sync sound service with settings
    if (settingsCubit != null) {
      final settingsState = settingsCubit!.state;
      _soundService.setHapticsEnabled(settingsState.hapticsEnabled);
      _soundService.setSoundEnabled(settingsState.soundEnabled);
    }

    // Load saved games asynchronously
    loadSavedGames().then((_) {
      _savedGamesLoaded = true;
      if (!_savedGamesLoadCompleter.isCompleted) {
        _savedGamesLoadCompleter.complete();
      }
    }).catchError((e) {
      // Error logged only in debug mode
      assert(() {
        debugPrint('Error loading saved games: $e');
        return true;
      }());
      _savedGamesLoaded = true;
      if (!_savedGamesLoadCompleter.isCompleted) {
        _savedGamesLoadCompleter.complete();
      }
    });
  }

  // Check if there's an active game in progress
  bool get hasActiveGame => state is GameInProgress;

  // Check if a specific mode has a saved game
  bool hasSavedGame(GameMode mode) => _savedGames.containsKey(mode);

  // Get current game mode (if in progress)
  GameMode? get currentGameMode {
    final currentState = state;
    if (currentState is GameInProgress) {
      return currentState.gameMode;
    }
    return null;
  }

  Future<void> startGame(GameMode mode, {StoryLevel? storyLevel}) async {
    // CRITICAL FIX: Wait for saved games to load before starting game
    // This ensures saved games are available when checking if a saved game exists
    if (!_savedGamesLoaded) {
      await _savedGamesLoadCompleter.future;
    }

    // Cancel any existing timer
    _storyTimer?.cancel();

    // Start background music
    _soundService.playBGM();

    // Save current game state before switching modes (if there's an active game)
    final currentState = state;

    // Determine the actual game mode we'll be using
    // Story levels can use any mode (chaos, classic, etc.), so use level's mode if provided
    final targetMode = storyLevel?.gameMode ?? mode;

    // Save current game if mode is changing (even for story mode transitions)
    if (currentState is GameInProgress && currentState.gameMode != targetMode) {
      _saveCurrentGame(currentState);
    }

    // If coming from GameOver, clear the saved game for this mode
    if (currentState is GameOver && currentState.gameMode == targetMode) {
      _savedGames.remove(targetMode);
      _saveToPersistentStorage(); // Persist the removal
    }

    // Story mode doesn't support save/load - always start fresh
    // FIX: Check for storyLevel but still handle mode transitions properly
    if (storyLevel != null) {
      // Use the story level's game mode, not the passed mode parameter
      _startStoryGame(storyLevel);
      return;
    }

    // BUG FIX #7: If mode is story but no level provided, reset to initial state
    if (mode == GameMode.story) {
      emit(
          const GameInitial()); // Reset to initial state instead of leaving inconsistent
      return;
    }

    // Check if this mode has a saved game (and we're not in GameOver state)
    if (_savedGames.containsKey(mode) && currentState is! GameOver) {
      _loadSavedGame(mode);
    } else {
      // Start fresh game
      _pieceService.reset();
      _resetMissionTracking();

      final config = GameModeConfig.fromMode(mode);
      final board = Board(size: config.boardSize);
      final themeColors = settingsCubit?.state.currentTheme.blockColors;
      final hand = _pieceService.generateHand(config.handSize, themeColors: themeColors);

      emit(GameInProgress(
        board: board,
        hand: hand,
        score: 0,
        combo: 0,
        lastBrokenLine: 0,
        gameMode: mode,
      ));
    }
  }

  void _startStoryGame(StoryLevel level) {
    // Reset flag for new story level
    _isEndingStoryLevel = false;

    _pieceService.reset();
    _resetMissionTracking();

    final config = GameModeConfig.fromMode(level.gameMode);
    final board = Board(size: config.boardSize);
    final themeColors = settingsCubit?.state.currentTheme.blockColors;
    final hand = _pieceService.generateHand(config.handSize, themeColors: themeColors);

    // Check if power-ups are disabled
    final powerUpsDisabled = level.restrictions.any((r) =>
        r.toLowerCase().contains('no power') ||
        r.toLowerCase().contains('without power'));

    // Calculate exact end time for timestamp-based timing (prevents timer cheating)
    final DateTime? levelEndTime =
        level.timeLimit != null && level.timeLimit! > 0
            ? DateTime.now().add(Duration(seconds: level.timeLimit!))
            : null;

    emit(GameInProgress(
      board: board,
      hand: hand,
      score: 0,
      combo: 0,
      lastBrokenLine: 0,
      gameMode: level
          .gameMode, // FIX: Use level's game mode, not hardcoded GameMode.story
      storyLevel: level,
      linesCleared: 0,
      timeRemaining: level.timeLimit ?? -1,
      powerUpsDisabled: powerUpsDisabled,
      levelEndTime: levelEndTime,
    ));

    // Start timer if level has time limit
    if (level.timeLimit != null && level.timeLimit! > 0) {
      _startStoryTimer();
    }
  }

  void _startStoryTimer() {
    _storyTimer?.cancel();
    _storyTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentState = state;
      if (currentState is! GameInProgress ||
          currentState.levelEndTime == null) {
        timer.cancel();
        return;
      }

      // Calculate remaining time based on wall clock (prevents timer cheating)
      final now = DateTime.now();
      final remaining = currentState.levelEndTime!.difference(now).inSeconds;

      if (remaining <= 0) {
        // Time's up - check if objectives were met
        timer.cancel();
        _endStoryLevel(currentState, timeUp: true);
      } else {
        emit(currentState.copyWith(timeRemaining: remaining));
      }
    });
  }

  /// Pause the story mode timer (e.g., when user navigates away)
  /// This prevents the timer from continuing in the background
  void pauseTimer() {
    _storyTimer?.cancel();
  }

  void _saveCurrentGame(GameInProgress currentState) {
    final bagState = _pieceService.getState();
    _savedGames[currentState.gameMode] = _SavedGameState(
      board: currentState.board.clone(),
      hand: List.from(currentState.hand),
      score: currentState.score,
      combo: currentState.combo,
      lastBrokenLine: currentState.lastBrokenLine,
      gameOver: false,
      pieceBag: bagState['pieceBag'],
      bagIndex: bagState['bagIndex'],
      bagRefillCount: bagState['bagRefillCount'],
    );
    _saveToPersistentStorage();
  }

  void saveGame() {
    final currentState = state;
    if (currentState is GameInProgress) {
      _saveCurrentGame(currentState);
    }
  }

  Future<void> _saveToPersistentStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> savedGamesData = {};

      _savedGames.forEach((mode, gameState) {
        savedGamesData[mode.toString()] = {
          'board': gameState.board.toJson(),
          'hand': gameState.hand.map((p) => p.toJson()).toList(),
          'score': gameState.score,
          'combo': gameState.combo,
          'lastBrokenLine': gameState.lastBrokenLine,
          'gameOver': gameState.gameOver,
          'pieceBag':
              gameState.pieceBag, // Serialize bag to prevent reroll exploits
          'bagIndex': gameState.bagIndex, // Serialize bag index
          'bagRefillCount':
              gameState.bagRefillCount, // CRITICAL FIX: Serialize refill count
        };
      });

      await prefs.setString('savedGames', jsonEncode(savedGamesData));
    } catch (e) {
      // Error logged only in debug mode
      assert(() {
        debugPrint('Error saving games: $e');
        return true;
      }());
    }
  }

  Future<void> loadSavedGames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGamesJson = prefs.getString('savedGames');

      if (savedGamesJson != null && savedGamesJson.isNotEmpty) {
        final Map<String, dynamic> savedGamesData = jsonDecode(savedGamesJson);

        savedGamesData.forEach((modeStr, gameData) {
          try {
            final mode = GameMode.values.firstWhere(
              (m) => m.toString() == modeStr,
              orElse: () => GameMode.classic,
            );

            final board = Board.fromJson(gameData['board']);
            final handData = gameData['hand'] as List;
            final hand = handData.map((p) => Piece.fromJson(p)).toList();

            _savedGames[mode] = _SavedGameState(
              board: board,
              hand: hand,
              score: gameData['score'] ?? 0,
              combo: gameData['combo'] ?? 0,
              lastBrokenLine: gameData['lastBrokenLine'] ?? 0,
              gameOver: gameData['gameOver'] ?? false,
              pieceBag: List<int>.from(gameData['pieceBag'] ?? []),
              bagIndex: gameData['bagIndex'] ?? 0,
              bagRefillCount: gameData['bagRefillCount'] ?? 0,
            );
          } catch (e) {
            // Error logged only in debug mode
            assert(() {
              debugPrint('Error loading saved game for mode $modeStr: $e');
              return true;
            }());
          }
        });
      }
    } catch (e) {
      // Error logged only in debug mode
      assert(() {
        debugPrint('Error loading saved games: $e');
        return true;
      }());
    }
  }

  void _loadSavedGame(GameMode mode) {
    final savedGame = _savedGames[mode];
    if (savedGame == null) {
      return;
    }

    // Validate board size matches mode configuration
    final config = GameModeConfig.fromMode(mode);

    if (savedGame.board.size != config.boardSize) {
      // Remove corrupted save and start fresh
      _savedGames.remove(mode);
      _saveToPersistentStorage();
      _pieceService.reset();
      final board = Board(size: config.boardSize);
      final themeColors = settingsCubit?.state.currentTheme.blockColors;
      final hand = _pieceService.generateHand(config.handSize, themeColors: themeColors);
      emit(GameInProgress(
        board: board,
        hand: hand,
        score: 0,
        combo: 0,
        lastBrokenLine: 0,
        gameMode: mode,
      ));
      return;
    }

    // Restore bag state before checking hand size
    _pieceService.restoreState({
      'pieceBag': savedGame.pieceBag,
      'bagIndex': savedGame.bagIndex,
      'bagRefillCount': savedGame.bagRefillCount,
    });

    // Validate and adjust hand size if needed
    List<Piece> hand = savedGame.hand;
    if (hand.length != config.handSize) {
      final themeColors = settingsCubit?.state.currentTheme.blockColors;
      if (hand.isEmpty) {
        // Hand is completely empty - refill to full size
        hand = _pieceService.generateHand(config.handSize, themeColors: themeColors);
      } else if (hand.length > config.handSize) {
        // Hand is too large - trim to correct size
        hand = hand.take(config.handSize).toList();
      }
      // Partial hands are preserved as-is (normal game behavior)

      if (savedGame.gameOver) {
        emit(GameOver(
          board: savedGame.board,
          finalScore: savedGame.score,
          gameMode: mode,
        ));
      } else {
        final correctedState = GameInProgress(
          board: savedGame.board,
          hand: hand, // Use adjusted hand preserving saved pieces
          score: savedGame.score,
          combo: savedGame.combo,
          lastBrokenLine: savedGame.lastBrokenLine,
          gameMode: mode,
        );
        emit(correctedState);
        // Save corrected game state to persistent storage
        _saveCurrentGame(correctedState);
      }
      return;
    }

    if (savedGame.gameOver) {
      emit(GameOver(
        board: savedGame.board,
        finalScore: savedGame.score,
        gameMode: mode,
      ));
    } else {
      emit(GameInProgress(
        board: savedGame.board,
        hand: savedGame.hand,
        score: savedGame.score,
        combo: savedGame.combo,
        lastBrokenLine: savedGame.lastBrokenLine,
        gameMode: mode,
      ));
    }
  }

  void clearHoverBlocks() {
    final currentState = state;
    if (currentState is! GameInProgress) return;

    // CRITICAL FIX: Clone board and clear hover breaks to remove line clear preview
    // We need to clear the hoverBreak block types from the board when dragging stops
    final newBoard = currentState.board.clone();
    newBoard.clearHoverBlocks(); // This clears hoverBreak types from the board

    emit(currentState.copyWith(
      board: newBoard,
      hoverPiece: null,
      hoverX: null,
      hoverY: null,
      hoverValid: null,
    ));
  }

  void showHoverPreview(Piece piece, int x, int y) {
    final currentState = state;
    if (currentState is! GameInProgress) return;

    // BUG FIX #4: Don't skip update if board has hover blocks from previous state
    // This ensures hover preview is recalculated after piece placement
    // OPTIMIZATION: Don't rebuild if the hover position hasn't changed AND board is clean
    if (currentState.hoverPiece?.id == piece.id &&
        currentState.hoverX == x &&
        currentState.hoverY == y &&
        !_boardHasHoverBlocks(currentState.board)) {
      return; // Position unchanged and board is clean, skip expensive operations
    }

    // Check if piece can be placed
    final canPlace = currentState.board.canPlacePiece(piece, x, y);

    // CRITICAL FIX: Clone board and update hover breaks to show which lines will be cleared
    // This visualization is important for user experience - users need to see which lines
    // will be cleared when placing a piece. The performance cost is acceptable for this feature.
    final newBoard = currentState.board.clone();
    newBoard.clearHoverBlocks(); // Clear any previous hover breaks

    if (canPlace) {
      // Only show hover breaks if the piece can actually be placed
      newBoard.updateHoveredBreaks(piece, x, y);
    }

    // Update hover preview with board that includes hover break visualization
    emit(currentState.copyWith(
      board: newBoard,
      hoverPiece: piece,
      hoverX: x,
      hoverY: y,
      hoverValid: canPlace,
    ));
  }

  // BUG FIX #4: Helper method to check if board has hover blocks
  bool _boardHasHoverBlocks(Board board) {
    for (int row = 0; row < board.size; row++) {
      for (int col = 0; col < board.size; col++) {
        final blockType = board.grid[row][col].type;
        if (blockType == BlockType.hoverBreakFilled ||
            blockType == BlockType.hoverBreakEmpty ||
            blockType == BlockType.hoverBreak) {
          return true;
        }
      }
    }
    return false;
  }

  bool placePiece(Piece piece, int x, int y) {
    final currentState = state;
    if (currentState is! GameInProgress) return false;

    final canPlace = currentState.board.canPlacePiece(piece, x, y);
    if (!canPlace) {
      _soundService.playError();
      // CRITICAL FIX: Clear hover blocks even on failed placement
      // This prevents hover blocks from persisting on screen
      final newBoard = currentState.board.clone();
      newBoard.clearHoverBlocks();
      emit(currentState.copyWith(
        board: newBoard,
        hoverPiece: null,
        hoverX: null,
        hoverY: null,
        hoverValid: null,
      ));

      return false;
    }

    // Clone board before mutation
    final newBoard = currentState.board.clone();

    // Clear hover blocks and place the piece
    newBoard.clearHoverBlocks();
    newBoard.placePiece(piece, x, y, type: BlockType.filled);

    // Play place sound
    _soundService.playPlace();

    // Calculate score from placing blocks
    final pieceBlockCount = piece.getBlockCount();
    int newScore = currentState.score + pieceBlockCount;

    // Break lines on the new board
    final clearResult = newBoard.breakLinesWithInfo();
    final linesBroken = clearResult.lineCount;

    // Track lines cleared for story mode
    int newLinesCleared = currentState.linesCleared + linesBroken;

    // Update combo state using scoring service
    final (newCombo, newLastBrokenLine) = _scoringService.updateComboState(
      linesBroken: linesBroken,
      currentCombo: currentState.combo,
      lastBrokenLine: currentState.lastBrokenLine,
    );

    if (linesBroken > 0) {
      // Calculate score using scoring service
      final lineScore = _scoringService.calculateLineClearScore(
        linesBroken: linesBroken,
        currentCombo: newCombo,
        doublePointsActive: _doublePointsActive,
      );
      newScore += lineScore;

      // Check for perfect clear
      if (newBoard.isEmpty()) {
        final perfectClearBonus = _scoringService.calculatePerfectClearBonus(newCombo);
        newScore += perfectClearBonus;
        _perfectClearCount++;
      }

      // Track max combo for missions
      if (newCombo > _maxComboReached) {
        _maxComboReached = newCombo;
      }

      // Play clear and combo sounds
      final hasCombo = newCombo > 1;
      _soundService.playClear(linesBroken, hasCombo: hasCombo);
      if (hasCombo) {
        _soundService.playCombo(newCombo);
      }

      // Trigger particle effects callback
      if (onLinesCleared != null && clearResult.clearedBlocks.isNotEmpty) {
        onLinesCleared!(clearResult.clearedBlocks, linesBroken);
      }
    }

    // Remove the piece from hand
    final newHand = List<Piece>.from(currentState.hand);
    newHand.removeWhere((p) => p.id == piece.id);

    // Refill hand if empty
    if (newHand.isEmpty) {
      final config = GameModeConfig.fromMode(currentState.gameMode);
      final themeColors = settingsCubit?.state.currentTheme.blockColors;
      newHand.addAll(_pieceService.generateAdaptiveHand(
        config.handSize,
        newBoard,
        themeColors: themeColors,
      ));
      _soundService.playRefill();
    }

    // CHECK FOR VICTORY: Story mode level completion
    if (currentState.storyLevel != null) {
      final level = currentState.storyLevel!;
      final scoreComplete = newScore >= level.targetScore;
      final linesComplete =
          level.targetLines == null || newLinesCleared >= level.targetLines!;

      if (scoreComplete && linesComplete) {
        // Victory! Level objectives met
        _endStoryLevel(
          currentState.copyWith(
            board: newBoard,
            score: newScore,
            linesCleared: newLinesCleared,
            hand: newHand,
          ),
        );
        return true;
      }
    }

    // Check for game over using the NEW board state
    // CRITICAL FIX: Use newBoard instead of currentState.board
    final hasValidMove = newBoard.hasAnyValidMove(newHand);

    // For story mode, only end on game over (no valid moves)
    if (currentState.storyLevel != null) {
      // Story mode: check for game over (no valid moves)
      // Let players continue playing to reach higher star thresholds
      if (!hasValidMove) {
        _endStoryLevel(
            currentState.copyWith(
              board: newBoard, // FIX: Use the modified board
              score: newScore,
              linesCleared: newLinesCleared,
              hand: newHand,
            ),
            failed: newScore < currentState.storyLevel!.targetScore);
        return true;
      }
    } else if (!hasValidMove) {
      // Regular mode: game over
      _soundService.stopBGM();
      _soundService.playGameOver();
      settingsCubit?.updateHighScore(newScore);

      // Track mission progress
      _trackMissionProgress(
        gameMode: currentState.gameMode,
        finalScore: newScore,
        linesCleared: newLinesCleared,
        maxCombo: _maxComboReached,
        perfectClears: _perfectClearCount,
      );

      // Reset tracking for next game
      _resetMissionTracking();

      emit(GameOver(
        board: newBoard, // FIX: Use the modified board with placed piece
        finalScore: newScore,
        gameMode: currentState.gameMode,
      ));
      return true;
    }

    // Continue game
    final newState = GameInProgress(
      board:
          newBoard, // CRITICAL FIX: Use the modified board with placed piece and cleared lines
      hand: newHand,
      score: newScore,
      combo: newCombo,
      lastBrokenLine: newLastBrokenLine,
      gameMode: currentState.gameMode,
      storyLevel: currentState.storyLevel,
      linesCleared: newLinesCleared,
      timeRemaining: currentState.timeRemaining,
      powerUpsDisabled: currentState.powerUpsDisabled,
      levelEndTime: currentState.levelEndTime,
    );

    emit(newState);

    // CRITICAL FIX: Auto-save game after each piece placement
    // This ensures the game is saved continuously, not just when navigating away
    // Prevents losing progress if app is closed unexpectedly
    // Only save for non-story modes (story mode doesn't support save/load)
    if (currentState.storyLevel == null) {
      _saveCurrentGame(newState);
    }

    // Check for Chaos events
    _checkChaosEvent();

    return true;
  }

  void resetGame() {
    _storyTimer?.cancel();
    final currentState = state;
    if (currentState is GameInProgress || currentState is GameOver) {
      // ✅ Clear saved game first
      final gameMode = currentState is GameInProgress
          ? currentState.gameMode
          : (currentState as GameOver).gameMode;
      final storyLevel =
          currentState is GameInProgress ? currentState.storyLevel : null;

      _savedGames.remove(gameMode);
      _saveToPersistentStorage();

      // Reset services
      _pieceService.reset();

      // Reset Chaos mode variables
      _moveCount = 0;
      _doublePointsActive = false;
      _doublePointsLeft = 0;

      startGame(gameMode, storyLevel: storyLevel);
    }
  }

  /// Public method to complete a story level when objectives are met
  void completeStoryLevel() {
    final currentState = state;
    if (currentState is! GameInProgress) return;
    if (currentState.storyLevel == null) return;

    // Check if objectives are actually met
    final level = currentState.storyLevel!;
    final scoreComplete = currentState.score >= level.targetScore;
    final linesComplete = level.targetLines == null ||
        currentState.linesCleared >= level.targetLines!;

    if (scoreComplete && linesComplete) {
      _endStoryLevel(currentState);
    }
  }

  void _endStoryLevel(GameInProgress currentState,
      {bool failed = false, bool timeUp = false}) {
    // Prevent duplicate calls
    if (state is GameOver) {
      return;
    }

    if (_isEndingStoryLevel) {
      return;
    }

    // Set flag to prevent duplicate calls
    _isEndingStoryLevel = true;

    _storyTimer?.cancel();

    final level = currentState.storyLevel!;
    final score = currentState.score;

    // Calculate stars based on score
    int stars = 0;
    bool completed = !failed && !timeUp;

    if (completed) {
      if (score >= level.starThreshold3) {
        stars = 3;
      } else if (score >= level.starThreshold2) {
        stars = 2;
      } else if (score >= level.starThreshold1) {
        stars = 1;
      }

      _soundService.stopBGM();
      _soundService.playPlace(); // Victory sound

      // Award coins if level completed
      if (stars > 0) {
        settingsCubit?.addCoins(level.coinReward);
      }
    } else {
      _soundService.stopBGM();
      _soundService.playGameOver();
    }

    // Track mission progress for story mode games too
    _trackMissionProgress(
      gameMode: currentState.gameMode,
      finalScore: score,
      linesCleared: currentState.linesCleared,
      maxCombo: _maxComboReached,
      perfectClears: _perfectClearCount,
    );
    _resetMissionTracking();

    // BUG FIX #1: Use currentState.gameMode instead of hardcoded GameMode.story
    // Story levels can use different game modes (chaos, classic, etc.)
    emit(GameOver(
      board: currentState.board,
      finalScore: score,
      gameMode: currentState.gameMode, // FIX: Use level's actual game mode
      storyLevel: level,
      starsEarned: stars,
      levelCompleted: completed,
    ));

    // Reset flag after emitting (in case of future reuse)
    _isEndingStoryLevel = false;
  }

  // ========== Mission Tracking ==========

  /// Track mission progress when game ends
  Future<void> _trackMissionProgress({
    required GameMode gameMode,
    required int finalScore,
    required int linesCleared,
    required int maxCombo,
    required int perfectClears,
  }) async {
    try {
      // Track games played
      await _missionService.addMissionProgress(MissionType.playGames, 1);

      // Track lines cleared
      if (linesCleared > 0) {
        await _missionService.addMissionProgress(
            MissionType.clearLines, linesCleared);
      }

      // Track high score
      if (finalScore > 0) {
        await _missionService.trackHighScore(finalScore);
      }

      // Track max combo
      if (maxCombo > 0) {
        await _missionService.trackMaxCombo(maxCombo);
      }

      // Track perfect clears
      if (perfectClears > 0) {
        await _missionService.addMissionProgress(
            MissionType.perfectClears, perfectClears);
      }

      // Track chaos mode games
      if (gameMode == GameMode.chaos) {
        await _missionService.addMissionProgress(MissionType.useChaosMode, 1);
      }

    } catch (e) {
      // Error logged only in debug mode
      assert(() {
        debugPrint('Error tracking missions: $e');
        return true;
      }());
    }
  }

  /// Reset mission tracking variables for new game
  void _resetMissionTracking() {
    _perfectClearCount = 0;
    _maxComboReached = 0;
  }

  // ========== Chaos Mode Events ==========

  /// Check and trigger random Chaos Mode events
  void _checkChaosEvent() {
    final currentState = state;
    if (currentState is! GameInProgress) return;

    // Only for Chaos mode
    if (currentState.gameMode != GameMode.chaos) return;

    _moveCount++;

    // If event is active, count down
    if (_doublePointsActive) {
      _doublePointsLeft--;
      if (_doublePointsLeft <= 0) {
        _doublePointsActive = false;
      }
      return;
    }

    // Random chance to trigger chaos event
    if (_moveCount > _chaosEventMinMoves &&
        _moveCount % _chaosEventInterval == 0 &&
        math.Random().nextDouble() > _chaosEventProbability) {
      _doublePointsActive = true;
      _doublePointsLeft = _chaosEventDuration;
      // TODO: Show UI notification to player when 2X points activates
    }
  }

  // ========== Power-Up Methods ==========

  Future<void> triggerPowerUp(PowerUpType type) async {
    if (settingsCubit == null) return;

    final currentState = state;
    if (currentState is! GameInProgress) return;

    // Check if power-ups are disabled in story mode
    if (currentState.powerUpsDisabled) {
      return;
    }

    // Check if user has the power-up
    if (settingsCubit!.getPowerUpCount(type) <= 0) return;

    // Use power-up service
    final themeColors = settingsCubit?.state.currentTheme.blockColors;
    final result = _powerUpService.activate(
      type: type,
      board: currentState.board,
      hand: currentState.hand,
      gameMode: currentState.gameMode,
      themeColors: themeColors,
    );

    if (result.success) {
      // Apply result to state
      var newState = currentState;

      if (result.newBoard != null) {
        newState = newState.copyWith(
          board: result.newBoard,
          score: currentState.score + result.scoreGained,
        );
      }

      if (result.newHand != null) {
        newState = newState.copyWith(hand: result.newHand);
      }

      // Trigger particle effects
      if (onLinesCleared != null && result.clearedBlocks.isNotEmpty) {
        onLinesCleared!(result.clearedBlocks, 1);
      }

      emit(newState);
      await settingsCubit!.usePowerUp(type);
    }
  }

}
