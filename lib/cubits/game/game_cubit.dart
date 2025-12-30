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
  final SettingsCubit? settingsCubit;
  final SoundService _soundService = SoundService();

  // Separate saved states for each game mode
  final Map<GameMode, _SavedGameState> _savedGames = {};

  // Random Bag System (Section 4.1 of technical document)
  // FIX: Changed from static to instance variables so each game session is independent
  List<int> _pieceBag = [];
  int _bagIndex = 0;
  int _bagRefillCount =
      0; // Track bag refills for rotating distribution fairness

  // Story mode timer
  Timer? _storyTimer;

  /// Callback for when lines are cleared (for particle effects)
  LineClearCallback? onLinesCleared;

  // CRITICAL FIX: Track if saved games are still loading
  bool _savedGamesLoaded = false;
  final Completer<void> _savedGamesLoadCompleter = Completer<void>();

  GameCubit({this.settingsCubit}) : super(const GameInitial()) {
    // Sync sound service with settings
    if (settingsCubit != null) {
      final settingsState = settingsCubit!.state;
      _soundService.setHapticsEnabled(settingsState.hapticsEnabled);
      _soundService.setSoundEnabled(settingsState.soundEnabled);
    }
    // Load saved games from persistent storage
    // CRITICAL FIX: Load saved games asynchronously and mark when complete
    loadSavedGames().then((_) {
      _savedGamesLoaded = true;
      if (!_savedGamesLoadCompleter.isCompleted) {
        _savedGamesLoadCompleter.complete();
      }
    }).catchError((e) {
      debugPrint('Error loading saved games: $e');
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
      debugPrint('Error: Story Mode started without a level');
      emit(
          const GameInitial()); // Reset to initial state instead of leaving inconsistent
      return;
    }

    // Check if this mode has a saved game (and we're not in GameOver state)
    if (_savedGames.containsKey(mode) && currentState is! GameOver) {
      debugPrint('Loading saved game for $mode');
      _loadSavedGame(mode);
    } else {
      debugPrint('No saved game found for $mode, starting fresh game');
      // Start fresh game
      _pieceBag.clear(); // Reset bag for new game
      _bagIndex = 0;
      _bagRefillCount =
          0; // CRITICAL FIX: Reset refill count for consistent rotation pattern

      final config = GameModeConfig.fromMode(mode);
      final board = Board(size: config.boardSize);
      final hand = _generateRandomHand(config.handSize);

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
    _pieceBag.clear(); // Reset bag for new story level
    _bagIndex = 0;
    _bagRefillCount =
        0; // CRITICAL FIX: Reset refill count for consistent rotation pattern

    // FIX: Use the story level's game mode, not hardcoded GameMode.story
    // Some story levels use GameMode.chaos or other modes
    final config = GameModeConfig.fromMode(level.gameMode);
    final board = Board(size: config.boardSize);
    final hand = _generateRandomHand(config.handSize);

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
    _savedGames[currentState.gameMode] = _SavedGameState(
      board: currentState.board.clone(),
      hand: List.from(currentState.hand),
      score: currentState.score,
      combo: currentState.combo,
      lastBrokenLine: currentState.lastBrokenLine,
      gameOver: false,
      pieceBag: List.from(_pieceBag), // Save current bag state
      bagIndex: _bagIndex, // Save current bag index
      bagRefillCount:
          _bagRefillCount, // CRITICAL FIX: Save refill count for rotating distribution
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
      debugPrint('Saved games to persistent storage: ${_savedGames.keys}');
    } catch (e) {
      debugPrint('Error saving games: $e');
    }
  }

  Future<void> loadSavedGames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGamesJson = prefs.getString('savedGames');

      if (savedGamesJson != null && savedGamesJson.isNotEmpty) {
        final Map<String, dynamic> savedGamesData = jsonDecode(savedGamesJson);
        debugPrint('Loading saved games from storage: ${savedGamesData.keys}');

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
              pieceBag:
                  List<int>.from(gameData['pieceBag'] ?? []), // Load bag state
              bagIndex: gameData['bagIndex'] ?? 0, // Load bag index
              bagRefillCount: gameData['bagRefillCount'] ??
                  0, // CRITICAL FIX: Load refill count (default to 0 for old saves)
            );
            debugPrint(
                'Successfully loaded saved game for $mode (score: ${gameData['score'] ?? 0})');
          } catch (e) {
            debugPrint('Error loading saved game for mode $modeStr: $e');
          }
        });
        debugPrint('Loaded ${_savedGames.length} saved game(s)');
      } else {
        debugPrint('No saved games found in storage');
      }
    } catch (e) {
      debugPrint('Error loading saved games: $e');
    }
  }

  void _loadSavedGame(GameMode mode) {
    final savedGame = _savedGames[mode];
    if (savedGame == null) {
      debugPrint('No saved game found for mode: $mode');
      return;
    }

    debugPrint(
        'Loading saved game for $mode: hand size=${savedGame.hand.length}, board size=${savedGame.board.size}');

    // Validate board size matches mode configuration
    // CRITICAL FIX: Prevents loading 8x8 board for Chaos mode (expects 10x10) or vice versa
    // This can happen if saved game data is corrupted or from a different version
    final config = GameModeConfig.fromMode(mode);
    debugPrint(
        'Mode config for $mode: hand size=${config.handSize}, board size=${config.boardSize}');

    if (savedGame.board.size != config.boardSize) {
      debugPrint(
          'Saved game has wrong board size (${savedGame.board.size} vs ${config.boardSize}). Creating fresh game.');
      // Remove corrupted save from memory and persistent storage
      _savedGames.remove(mode);
      _saveToPersistentStorage(); // Persist the removal so it's not reloaded on next app start
      // Start fresh game with correct size
      _pieceBag.clear();
      _bagIndex = 0;
      _bagRefillCount = 0; // CRITICAL FIX: Reset refill count for fresh game
      final board = Board(size: config.boardSize);
      final hand = _generateRandomHand(config.handSize);
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

    // CRITICAL FIX: Restore bag state BEFORE checking hand size
    // This ensures piece bag is restored even if hand size needs correction
    // Restoring bag state first maintains the random sequence integrity
    _pieceBag = List.from(savedGame.pieceBag);
    _bagIndex = savedGame.bagIndex;
    _bagRefillCount = savedGame
        .bagRefillCount; // CRITICAL FIX: Restore refill count for correct rotation pattern

    // CRITICAL FIX: Validate hand size matches mode configuration
    // BUG FIX: Preserve partial hands - only refill when hand is completely empty (0 pieces)
    // Hand should stay partial (e.g., 2/3 pieces) until all pieces are used
    List<Piece> hand = savedGame.hand;
    if (hand.length != config.handSize) {
      debugPrint(
          'Hand size mismatch (${hand.length} vs ${config.handSize}). Adjusting hand size.');

      if (hand.isEmpty) {
        // Hand is completely empty - refill to full size (normal game behavior)
        hand = _generateRandomHand(config.handSize);
        debugPrint('Hand was empty, refilled with ${config.handSize} pieces');
      } else if (hand.length > config.handSize) {
        // Hand is too large - trim to correct size (keep first N pieces)
        hand = hand.take(config.handSize).toList();
        debugPrint(
            'Trimmed hand from ${savedGame.hand.length} to ${hand.length} pieces');
      } else {
        // Hand is partial (e.g., 2/3 pieces) - preserve it as-is!
        // This is correct behavior - hand only refills when ALL pieces are used
        debugPrint(
            'Preserving partial hand with ${hand.length} pieces (expected ${config.handSize})');
        // Keep hand as-is, no changes needed
      }

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
      debugPrint(
          'Loading saved game with preserved hand: ${savedGame.hand.length} pieces');
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

    // CRITICAL FIX: Break lines on the NEW board, not the old one!
    // This ensures hover blocks are cleared and line breaking works correctly
    final clearResult = newBoard.breakLinesWithInfo();
    final linesBroken = clearResult.lineCount;

    // Track lines cleared for story mode
    int newLinesCleared = currentState.linesCleared + linesBroken;

    int newCombo = currentState.combo;
    int newLastBrokenLine = currentState.lastBrokenLine;

    if (linesBroken > 0) {
      newLastBrokenLine = 0;
      newCombo += linesBroken;

      // Score calculation - Simplified and balanced formula
      // Base line bonus: 10 points per line
      // Combo multiplier: Increases every 10 combo points (1x → 2x → 3x...)
      // CRITICAL FIX: Use floor() + 1 instead of ceil() for correct progression
      // 0-9 combo → 1x, 10-19 → 2x, 20-29 → 3x, etc.
      final comboMultiplier = ((newCombo / 10).floor() + 1).clamp(1, 10);
      final lineBonus = linesBroken * 10 * comboMultiplier; // Cap at 10x
      newScore += lineBonus;

      // Play clear and combo sounds
      // CRITICAL FIX: Pass hasCombo parameter to prevent double sound
      // If there's a combo, only play combo sound (not clear sound)
      final hasCombo = newCombo > 1;
      _soundService.playClear(linesBroken, hasCombo: hasCombo);
      if (hasCombo) {
        _soundService.playCombo(newCombo);
      }

      // Trigger particle effects callback
      if (onLinesCleared != null && clearResult.clearedBlocks.isNotEmpty) {
        onLinesCleared!(clearResult.clearedBlocks, linesBroken);
      }
    } else {
      newLastBrokenLine++;
      // FIX: Use constant 3-move buffer instead of handSize
      // This ensures consistent combo behavior across all game modes
      // Combo resets after 4 moves without clearing (allows 3 moves buffer)
      if (newLastBrokenLine > 3) {
        newCombo = 0;
      }
    }

    // Remove the piece from hand
    final newHand = List<Piece>.from(currentState.hand);
    newHand.removeWhere((p) => p.id == piece.id);

    // Refill hand if empty
    if (newHand.isEmpty) {
      final config = GameModeConfig.fromMode(currentState.gameMode);
      newHand.addAll(_generateRandomHand(config.handSize));
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

    return true;
  }

  void resetGame() {
    _storyTimer?.cancel();
    final currentState = state;
    if (currentState is GameInProgress) {
      // Fix: Remove saved game before starting a new one
      _savedGames.remove(currentState.gameMode);
      startGame(currentState.gameMode, storyLevel: currentState.storyLevel);
    } else if (currentState is GameOver) {
      _savedGames.remove(currentState.gameMode);
      startGame(currentState.gameMode, storyLevel: currentState.storyLevel);
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
    // BUG FIX #6: Prevent duplicate calls if game is already over
    if (state is GameOver) return;

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
  }

  // ========== Power-Up Methods ==========

  Future<void> triggerPowerUp(PowerUpType type) async {
    if (settingsCubit == null) return;

    final currentState = state;
    if (currentState is! GameInProgress) return;

    // Check if power-ups are disabled in story mode
    if (currentState.powerUpsDisabled) {
      debugPrint('Power-ups are disabled for this level');
      return;
    }

    // Check if user has the power-up
    if (settingsCubit!.getPowerUpCount(type) <= 0) return;

    bool success = false;

    switch (type) {
      case PowerUpType.shuffle:
        success = _activateShuffle(currentState);
        break;
      case PowerUpType.wildPiece:
        success = _activateWildPiece(currentState);
        break;
      case PowerUpType.lineClear:
        success = _activateRandomLineClear(currentState);
        break;
      case PowerUpType.bomb:
        success = false;
        break;
      case PowerUpType.colorBomb:
        success = _activateColorBomb(currentState);
        break;
    }

    if (success) {
      await settingsCubit!.usePowerUp(type);
    }
  }

  bool _activateShuffle(GameInProgress currentState) {
    final config = GameModeConfig.fromMode(currentState.gameMode);
    final newHand = _generateRandomHand(config.handSize);
    _soundService.playRefill();

    emit(currentState.copyWith(hand: newHand));
    return true;
  }

  bool _activateWildPiece(GameInProgress currentState) {
    final wildPiece = Piece(
      id: 'wild_${DateTime.now().millisecondsSinceEpoch}',
      shape: [
        [true]
      ],
      color: const Color(0xFFFFD700),
    );

    final newHand = List<Piece>.from(currentState.hand)..add(wildPiece);
    _soundService.playPlace();

    emit(currentState.copyWith(hand: newHand));
    return true;
  }

  bool _activateRandomLineClear(GameInProgress currentState) {
    // CRITICAL FIX: Clone board before mutation to ensure state change is detected
    final newBoard = currentState.board.clone();

    // Find all rows and columns that have at least one block
    final filledRows = <int>[];
    final filledCols = <int>[];

    for (int row = 0; row < newBoard.size; row++) {
      for (int col = 0; col < newBoard.size; col++) {
        if (newBoard.grid[row][col].type == BlockType.filled) {
          if (!filledRows.contains(row)) filledRows.add(row);
          if (!filledCols.contains(col)) filledCols.add(col);
        }
      }
    }

    if (filledRows.isEmpty && filledCols.isEmpty) return false;

    // Randomly pick a row or column
    final allLines = [...filledRows, ...filledCols.map((c) => -c - 1)];
    allLines.shuffle();
    final selectedLine = allLines.first;

    final clearedBlocks = <ClearedBlockInfo>[];

    if (selectedLine >= 0) {
      // Clear row
      for (int col = 0; col < newBoard.size; col++) {
        if (newBoard.grid[selectedLine][col].type == BlockType.filled) {
          clearedBlocks.add(ClearedBlockInfo(
            row: selectedLine,
            col: col,
            color: newBoard.grid[selectedLine][col].color!,
          ));
          newBoard.grid[selectedLine][col] =
              const BoardBlock(type: BlockType.empty);
        }
      }
    } else {
      // Clear column
      final col = -selectedLine - 1;
      for (int row = 0; row < newBoard.size; row++) {
        if (newBoard.grid[row][col].type == BlockType.filled) {
          clearedBlocks.add(ClearedBlockInfo(
            row: row,
            col: col,
            color: newBoard.grid[row][col].color!,
          ));
          newBoard.grid[row][col] = const BoardBlock(type: BlockType.empty);
        }
      }
    }

    // After modifying the grid, update the bitboard
    newBoard.updateBitboard();

    // Award points
    final newScore = currentState.score + (clearedBlocks.length * 10);
    _soundService.playClear(1);

    // Trigger particles
    if (onLinesCleared != null && clearedBlocks.isNotEmpty) {
      onLinesCleared!(clearedBlocks, 1);
    }

    // CRITICAL FIX: Emit with new board to trigger UI update
    emit(currentState.copyWith(
      board: newBoard,
      score: newScore,
    ));
    return true;
  }

  bool _activateColorBomb(GameInProgress currentState) {
    // CRITICAL FIX: Clone board before mutation to ensure state change is detected
    final newBoard = currentState.board.clone();

    // Count blocks by color
    final colorCounts = <Color, int>{};
    for (int row = 0; row < newBoard.size; row++) {
      for (int col = 0; col < newBoard.size; col++) {
        final block = newBoard.grid[row][col];
        if (block.type == BlockType.filled && block.color != null) {
          colorCounts[block.color!] = (colorCounts[block.color!] ?? 0) + 1;
        }
      }
    }

    if (colorCounts.isEmpty) return false;

    // Find most common color
    Color? mostCommonColor;
    int maxCount = 0;
    colorCounts.forEach((color, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommonColor = color;
      }
    });

    if (mostCommonColor == null) return false;

    // Clear all blocks of that color
    final clearedBlocks = <ClearedBlockInfo>[];
    for (int row = 0; row < newBoard.size; row++) {
      for (int col = 0; col < newBoard.size; col++) {
        final block = newBoard.grid[row][col];
        if (block.type == BlockType.filled && block.color == mostCommonColor) {
          clearedBlocks.add(ClearedBlockInfo(
            row: row,
            col: col,
            color: block.color!,
          ));
          newBoard.grid[row][col] = const BoardBlock(type: BlockType.empty);
        }
      }
    }

    // After modifying the grid, update the bitboard
    newBoard.updateBitboard();

    // Award points
    final newScore = currentState.score + (clearedBlocks.length * 15);
    _soundService.playClear(clearedBlocks.length ~/ newBoard.size);

    // Trigger particles
    if (onLinesCleared != null && clearedBlocks.isNotEmpty) {
      onLinesCleared!(clearedBlocks, clearedBlocks.length ~/ newBoard.size);
    }

    // CRITICAL FIX: Emit with new board to trigger UI update
    emit(currentState.copyWith(
      board: newBoard,
      score: newScore,
    ));
    return true;
  }

  /// Generate random hand using Weighted Random Bag system (Section 4.1)
  /// This prevents clumping of hard pieces and ensures fair distribution
  List<Piece> _generateRandomHand(int count) {
    final hand = <Piece>[];

    // Get theme colors from settings (if available)
    final themeColors = settingsCubit?.state.currentTheme.blockColors;

    for (int i = 0; i < count; i++) {
      // Refill bag if empty
      if (_bagIndex >= _pieceBag.length) {
        _refillPieceBag();
        _bagIndex = 0;
      }

      // Draw piece from bag
      final pieceIndex = _pieceBag[_bagIndex++];
      hand.add(Piece.fromShapeIndex(pieceIndex, themeColors: themeColors));
    }

    return hand;
  }

  /// Refill the piece bag with weighted distribution (Fisher-Yates shuffle)
  /// Target distribution: 50% Easy, 35% Medium, 15% Hard
  void _refillPieceBag() {
    _pieceBag.clear();
    _bagRefillCount++; // Increment counter for rotating distribution fairness

    // Easy pieces (Singles, Doubles, Triples): 20, 21, 22, 23, 24
    // Target: 50% of bag
    // Add 10 copies of each (5 pieces × 10 = 50 pieces = 50% of 100)
    for (int i = 0; i < 10; i++) {
      _pieceBag.addAll([20, 21, 22, 23, 24]);
    }

    // Medium pieces (L-shapes, T-shapes, etc.): 0-15
    // Target: 35% of bag (35 pieces total)
    // To ensure equal distribution: 35 / 16 = 2.1875 pieces each
    // Strategy: Add 2 copies of each piece (32 pieces), then rotate which 3 pieces get an extra copy
    for (int i = 0; i < 2; i++) {
      _pieceBag.addAll(List.generate(
          16, (index) => index)); // 0..15 (2 copies each = 32 pieces)
    }
    // CRITICAL FIX: Rotate which pieces get the extra copy to ensure equal probability over time
    // Instead of always adding to [0, 1, 2], rotate through all pieces for fairness
    final startIndex = (_bagRefillCount * 3) % 16;
    _pieceBag.addAll([
      startIndex % 16,
      (startIndex + 1) % 16,
      (startIndex + 2) % 16,
    ]); // Rotating distribution (total: 35 pieces)

    // Hard pieces (3x3, 4x1, 5x1): 16, 17, 18, 19, 25, 26
    // Target: 15% of bag (15 pieces total)
    // To ensure equal distribution: 15 / 6 = 2.5 pieces each
    // Strategy: Add 2 copies of each piece (12 pieces), then rotate which 3 pieces get an extra copy
    final hardPieces = [16, 17, 18, 19, 25, 26];
    for (int i = 0; i < 2; i++) {
      _pieceBag.addAll(hardPieces); // 2 copies each = 12 pieces
    }
    // CRITICAL FIX: Rotate which pieces get the extra copy to ensure equal probability over time
    // Instead of always adding to [16, 17, 18], rotate through all hard pieces for fairness
    final hardStartIndex = (_bagRefillCount * 3) % hardPieces.length;
    _pieceBag.addAll([
      hardPieces[hardStartIndex % hardPieces.length],
      hardPieces[(hardStartIndex + 1) % hardPieces.length],
      hardPieces[(hardStartIndex + 2) % hardPieces.length],
    ]); // Rotating distribution (total: 15 pieces)

    // Fisher-Yates shuffle with proper RNG
    final rng = math.Random();
    for (int i = _pieceBag.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final temp = _pieceBag[i];
      _pieceBag[i] = _pieceBag[j];
      _pieceBag[j] = temp;
    }
  }
}
