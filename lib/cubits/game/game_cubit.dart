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
typedef LineClearCallback = void Function(List<ClearedBlockInfo> clearedBlocks, int lineCount);

/// Saved game state for a specific mode
class _SavedGameState {
  final Board board;
  final List<Piece> hand;
  final int score;
  final int combo;
  final int lastBrokenLine;
  final bool gameOver;

  _SavedGameState({
    required this.board,
    required this.hand,
    required this.score,
    required this.combo,
    required this.lastBrokenLine,
    required this.gameOver,
  });
}

class GameCubit extends Cubit<GameState> {
  final SettingsCubit? settingsCubit;
  final SoundService _soundService = SoundService();
  
  // Separate saved states for each game mode
  final Map<GameMode, _SavedGameState> _savedGames = {};
  
  // Random Bag System (Section 4.1 of technical document)
  static final List<int> _pieceBag = [];
  static int _bagIndex = 0;
  
  // Story mode timer
  Timer? _storyTimer;
  
  /// Callback for when lines are cleared (for particle effects)
  LineClearCallback? onLinesCleared;

  GameCubit({this.settingsCubit}) : super(const GameInitial()) {
    // Sync sound service with settings
    if (settingsCubit != null) {
      final settingsState = settingsCubit!.state;
      _soundService.setHapticsEnabled(settingsState.hapticsEnabled);
      _soundService.setSoundEnabled(settingsState.soundEnabled);
    }
    // Load saved games from persistent storage
    loadSavedGames();
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

  void startGame(GameMode mode, {StoryLevel? storyLevel}) {
    // Cancel any existing timer
    _storyTimer?.cancel();
    
    // Save current game state before switching modes (if there's an active game)
    final currentState = state;
    if (currentState is GameInProgress && currentState.gameMode != mode) {
      _saveCurrentGame(currentState);
    }
    
    // If coming from GameOver, clear the saved game for this mode
    if (currentState is GameOver && currentState.gameMode == mode) {
      _savedGames.remove(mode);
    }
    
    // Story mode doesn't support save/load - always start fresh
    if (storyLevel != null || mode == GameMode.story) {
      _startStoryGame(storyLevel!);
      return;
    }
    
    // Check if this mode has a saved game (and we're not in GameOver state)
    if (_savedGames.containsKey(mode) && currentState is! GameOver) {
      _loadSavedGame(mode);
    } else {
      // Start fresh game
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
    final config = GameModeConfig.fromMode(GameMode.story);
    final board = Board(size: config.boardSize);
    final hand = _generateRandomHand(config.handSize);
    
    // Check if power-ups are disabled
    final powerUpsDisabled = level.restrictions.any(
      (r) => r.toLowerCase().contains('no power') || r.toLowerCase().contains('without power')
    );
    
    emit(GameInProgress(
      board: board,
      hand: hand,
      score: 0,
      combo: 0,
      lastBrokenLine: 0,
      gameMode: GameMode.story,
      storyLevel: level,
      linesCleared: 0,
      timeRemaining: level.timeLimit ?? -1,
      powerUpsDisabled: powerUpsDisabled,
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
      if (currentState is! GameInProgress || currentState.timeRemaining <= 0) {
        timer.cancel();
        if (currentState is GameInProgress && currentState.timeRemaining == 0) {
          // Time's up - check if objectives were met
          _endStoryLevel(currentState, timeUp: true);
        }
        return;
      }
      
      emit(currentState.copyWith(timeRemaining: currentState.timeRemaining - 1));
    });
  }
  
  void _saveCurrentGame(GameInProgress currentState) {
    _savedGames[currentState.gameMode] = _SavedGameState(
      board: currentState.board.clone(),
      hand: List.from(currentState.hand),
      score: currentState.score,
      combo: currentState.combo,
      lastBrokenLine: currentState.lastBrokenLine,
      gameOver: false,
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
        };
      });
      
      await prefs.setString('savedGames', jsonEncode(savedGamesData));
    } catch (e) {
      debugPrint('Error saving games: $e');
    }
  }

  Future<void> loadSavedGames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGamesJson = prefs.getString('savedGames');
      
      if (savedGamesJson != null) {
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
            );
          } catch (e) {
            debugPrint('Error loading saved game for mode $modeStr: $e');
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading saved games: $e');
    }
  }

  void _loadSavedGame(GameMode mode) {
    final savedGame = _savedGames[mode];
    if (savedGame == null) return;
    
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
    
    currentState.board.clearHoverBlocks();
    emit(currentState.copyWith());
  }

  void showHoverPreview(Piece piece, int x, int y) {
    final currentState = state;
    if (currentState is! GameInProgress) return;
    
    currentState.board.clearHoverBlocks();
    
    if (currentState.board.canPlacePiece(piece, x, y)) {
      currentState.board.updateHoveredBreaks(piece, x, y);
      emit(currentState.copyWith());
    }
  }

  bool placePiece(Piece piece, int x, int y) {
    final currentState = state;
    if (currentState is! GameInProgress) return false;
    
    if (!currentState.board.canPlacePiece(piece, x, y)) {
      _soundService.playError();
      return false;
    }

    // Clear hover blocks and place the piece
    currentState.board.clearHoverBlocks();
    currentState.board.placePiece(piece, x, y, type: BlockType.filled);
    
    // Play place sound
    _soundService.playPlace();

    // Calculate score from placing blocks
    final pieceBlockCount = piece.getBlockCount();
    int newScore = currentState.score + pieceBlockCount;

    // Break lines and calculate combo
    final clearResult = currentState.board.breakLinesWithInfo();
    final linesBroken = clearResult.lineCount;
    
    // Track lines cleared for story mode
    int newLinesCleared = currentState.linesCleared + linesBroken;
    
    int newCombo = currentState.combo;
    int newLastBrokenLine = currentState.lastBrokenLine;
    
    if (linesBroken > 0) {
      newLastBrokenLine = 0;
      newCombo += linesBroken;
      
      // Score calculation
      final config = GameModeConfig.fromMode(currentState.gameMode);
      newScore += (linesBroken * config.boardSize * (newCombo / 2) * pieceBlockCount).round();
      
      // Play clear and combo sounds
      _soundService.playClear(linesBroken);
      if (newCombo > 1) {
        _soundService.playCombo(newCombo);
      }
      
      // Trigger particle effects callback
      if (onLinesCleared != null && clearResult.clearedBlocks.isNotEmpty) {
        onLinesCleared!(clearResult.clearedBlocks, linesBroken);
      }
    } else {
      newLastBrokenLine++;
      final config = GameModeConfig.fromMode(currentState.gameMode);
      if (newLastBrokenLine >= config.handSize) {
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

    // Check for game over
    final hasValidMove = currentState.board.hasAnyValidMove(newHand);
    debugPrint('Game Over Check: hasValidMove=$hasValidMove, hand size=${newHand.length}');
    
    // For story mode, only end on game over (no valid moves)
    if (currentState.storyLevel != null) {
      // Story mode: check for game over (no valid moves)
      // Let players continue playing to reach higher star thresholds
      if (!hasValidMove) {
        _endStoryLevel(currentState.copyWith(
          score: newScore,
          linesCleared: newLinesCleared,
          hand: newHand,
        ), failed: newScore < currentState.storyLevel!.targetScore);
        return true;
      }
    } else if (!hasValidMove) {
      // Regular mode: game over
      _soundService.playGameOver();
      settingsCubit?.updateHighScore(newScore);
      
      emit(GameOver(
        board: currentState.board,
        finalScore: newScore,
        gameMode: currentState.gameMode,
      ));
      return true;
    }
    
    // Continue game
    emit(GameInProgress(
      board: currentState.board,
      hand: newHand,
      score: newScore,
      combo: newCombo,
      lastBrokenLine: newLastBrokenLine,
      gameMode: currentState.gameMode,
      storyLevel: currentState.storyLevel,
      linesCleared: newLinesCleared,
      timeRemaining: currentState.timeRemaining,
      powerUpsDisabled: currentState.powerUpsDisabled,
    ));

    return true;
  }

  void resetGame() {
    _storyTimer?.cancel();
    final currentState = state;
    if (currentState is GameInProgress) {
      startGame(currentState.gameMode, storyLevel: currentState.storyLevel);
    } else if (currentState is GameOver) {
      startGame(currentState.gameMode, storyLevel: currentState.storyLevel);
    }
  }
  
  void _endStoryLevel(GameInProgress currentState, {bool failed = false, bool timeUp = false}) {
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
      
      _soundService.playPlace(); // Victory sound
      
      // Award coins if level completed
      if (stars > 0) {
        settingsCubit?.addCoins(level.coinReward);
      }
    } else {
      _soundService.playGameOver();
    }
    
    emit(GameOver(
      board: currentState.board,
      finalScore: score,
      gameMode: GameMode.story,
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
      shape: [[true]],
      color: const Color(0xFFFFD700),
    );
    
    final newHand = List<Piece>.from(currentState.hand)..add(wildPiece);
    _soundService.playPlace();
    
    emit(currentState.copyWith(hand: newHand));
    return true;
  }

  bool _activateRandomLineClear(GameInProgress currentState) {
    final board = currentState.board;
    
    // Find all rows and columns that have at least one block
    final filledRows = <int>[];
    final filledCols = <int>[];

    for (int row = 0; row < board.size; row++) {
      for (int col = 0; col < board.size; col++) {
        if (board.grid[row][col].type == BlockType.filled) {
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
      for (int col = 0; col < board.size; col++) {
        if (board.grid[selectedLine][col].type == BlockType.filled) {
          clearedBlocks.add(ClearedBlockInfo(
            row: selectedLine,
            col: col,
            color: board.grid[selectedLine][col].color!,
          ));
          board.grid[selectedLine][col] = BoardBlock(type: BlockType.empty);
        }
      }
    } else {
      // Clear column
      final col = -selectedLine - 1;
      for (int row = 0; row < board.size; row++) {
        if (board.grid[row][col].type == BlockType.filled) {
          clearedBlocks.add(ClearedBlockInfo(
            row: row,
            col: col,
            color: board.grid[row][col].color!,
          ));
          board.grid[row][col] = BoardBlock(type: BlockType.empty);
        }
      }
    }

    // Award points
    final newScore = currentState.score + (clearedBlocks.length * 10);
    _soundService.playClear(1);

    // Trigger particles
    if (onLinesCleared != null && clearedBlocks.isNotEmpty) {
      onLinesCleared!(clearedBlocks, 1);
    }

    emit(currentState.copyWith(score: newScore));
    return true;
  }

  bool _activateColorBomb(GameInProgress currentState) {
    final board = currentState.board;
    
    // Count blocks by color
    final colorCounts = <Color, int>{};
    for (int row = 0; row < board.size; row++) {
      for (int col = 0; col < board.size; col++) {
        final block = board.grid[row][col];
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
    for (int row = 0; row < board.size; row++) {
      for (int col = 0; col < board.size; col++) {
        final block = board.grid[row][col];
        if (block.type == BlockType.filled && block.color == mostCommonColor) {
          clearedBlocks.add(ClearedBlockInfo(
            row: row,
            col: col,
            color: block.color!,
          ));
          board.grid[row][col] = BoardBlock(type: BlockType.empty);
        }
      }
    }

    // Award points
    final newScore = currentState.score + (clearedBlocks.length * 15);
    _soundService.playClear(clearedBlocks.length ~/ board.size);

    // Trigger particles
    if (onLinesCleared != null && clearedBlocks.isNotEmpty) {
      onLinesCleared!(clearedBlocks, clearedBlocks.length ~/ board.size);
    }

    emit(currentState.copyWith(score: newScore));
    return true;
  }

  /// Generate random hand using Weighted Random Bag system (Section 4.1)
  /// This prevents clumping of hard pieces and ensures fair distribution
  List<Piece> _generateRandomHand(int count) {
    final hand = <Piece>[];
    
    for (int i = 0; i < count; i++) {
      // Refill bag if empty
      if (_bagIndex >= _pieceBag.length) {
        _refillPieceBag();
        _bagIndex = 0;
      }
      
      // Draw piece from bag
      final pieceIndex = _pieceBag[_bagIndex++];
      hand.add(Piece.fromShapeIndex(pieceIndex));
    }
    
    return hand;
  }
  
  /// Refill the piece bag with weighted distribution (Fisher-Yates shuffle)
  void _refillPieceBag() {
    _pieceBag.clear();
    
    // Add pieces based on distribution weights
    // Tier 1 (Easy): Small pieces - 50%
    for (int i = 0; i < 5; i++) {
      _pieceBag.addAll([22, 23, 24, 25, 26]); // Singles, doubles, triples
    }
    
    // Tier 2 (Medium): L-shapes, T-shapes - 35%
    for (int i = 0; i < 3; i++) {
      _pieceBag.addAll([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]);
    }
    
    // Tier 3 (Hard): Large pieces - 15%
    for (int i = 0; i < 2; i++) {
      _pieceBag.addAll([16, 17, 18, 19, 27, 28]); // 3x3, 4x1, 5x1
    }
    
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
