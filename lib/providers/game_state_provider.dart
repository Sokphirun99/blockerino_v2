import 'package:flutter/material.dart';
import '../models/board.dart';
import '../models/piece.dart';
import '../models/game_mode.dart';
import '../models/power_up.dart';
import '../services/sound_service.dart';
import 'settings_provider.dart';

/// Callback type for line clear events with particle info
typedef LineClearCallback = void Function(List<ClearedBlockInfo> clearedBlocks, int lineCount);

class GameStateProvider extends ChangeNotifier {
  Board? _board;
  List<Piece> _hand = [];
  int _score = 0;
  int _combo = 0;
  int _lastBrokenLine = 0;
  GameMode _gameMode = GameMode.classic;
  bool _gameOver = false;
  final SettingsProvider? _settingsProvider;
  final SoundService _soundService = SoundService();
  
  /// Callback for when lines are cleared (for particle effects)
  LineClearCallback? onLinesCleared;

  Board? get board => _board;
  List<Piece> get hand => _hand;
  int get score => _score;
  int get combo => _combo;
  bool get gameOver => _gameOver;
  GameMode get gameMode => _gameMode;
  int get movesUntilComboReset => _lastBrokenLine;

  GameStateProvider({SettingsProvider? settingsProvider})
      : _settingsProvider = settingsProvider {
    // Sync sound service with settings
    if (settingsProvider != null) {
      _soundService.setHapticsEnabled(settingsProvider.hapticsEnabled);
      _soundService.setSoundEnabled(settingsProvider.soundEnabled);
    }
  }

  void startGame(GameMode mode) {
    _gameMode = mode;
    final config = GameModeConfig.fromMode(mode);
    _board = Board(size: config.boardSize);
    _hand = _generateRandomHand(config.handSize);
    _score = 0;
    _combo = 0;
    _lastBrokenLine = 0;
    _gameOver = false;
    notifyListeners();
  }

  List<Piece> _generateRandomHand(int count) {
    return PieceLibrary.createRandomHand(count);
  }

  void clearHoverBlocks() {
    _board?.clearHoverBlocks();
    notifyListeners();
  }

  void showHoverPreview(Piece piece, int x, int y) {
    if (_board == null) return;
    
    _board!.clearHoverBlocks();
    
    if (_board!.canPlacePiece(piece, x, y)) {
      _board!.updateHoveredBreaks(piece, x, y);
      notifyListeners();
    }
  }

  bool placePiece(Piece piece, int x, int y) {
    if (_board == null) return false;
    if (!_board!.canPlacePiece(piece, x, y)) {
      _soundService.playError();
      return false;
    }

    // Clear hover blocks and place the piece
    _board!.clearHoverBlocks();
    _board!.placePiece(piece, x, y, type: BlockType.filled);
    
    // Play place sound
    _soundService.playPlace();

    // Calculate score from placing blocks
    final pieceBlockCount = piece.getBlockCount();
    _score += pieceBlockCount;

    // Break lines and calculate combo - use new method with info
    final clearResult = _board!.breakLinesWithInfo();
    final linesBroken = clearResult.lineCount;
    
    if (linesBroken > 0) {
      _lastBrokenLine = 0;
      _combo += linesBroken;
      
      // Score calculation matching blockerino-master:
      // linesBroken * boardSize * (combo / 2) * pieceBlockCount
      final config = GameModeConfig.fromMode(_gameMode);
      _score += (linesBroken * config.boardSize * (_combo / 2) * pieceBlockCount).round();
      
      // Play clear and combo sounds
      _soundService.playClear(linesBroken);
      if (_combo > 1) {
        _soundService.playCombo(_combo);
      }
      
      // Trigger particle effects callback
      if (onLinesCleared != null && clearResult.clearedBlocks.isNotEmpty) {
        onLinesCleared!(clearResult.clearedBlocks, linesBroken);
      }
    } else {
      _lastBrokenLine++;
      final config = GameModeConfig.fromMode(_gameMode);
      if (_lastBrokenLine >= config.handSize) {
        _combo = 0;
      }
    }

    // Remove the piece from hand
    _hand.removeWhere((p) => p.id == piece.id);

    // Refill hand if empty
    if (_hand.isEmpty) {
      final config = GameModeConfig.fromMode(_gameMode);
      _hand = _generateRandomHand(config.handSize);
      _soundService.playRefill();
    }

    // Check for game over
    final hasValidMove = _board!.hasAnyValidMove(_hand);
    debugPrint('Game Over Check: hasValidMove=$hasValidMove, hand size=${_hand.length}');
    if (!hasValidMove) {
      _gameOver = true;
      _soundService.playGameOver();
      // Update high score
      _settingsProvider?.updateHighScore(_score);
    }

    notifyListeners();
    return true;
  }

  void resetGame() {
    startGame(_gameMode);
  }

  // ========== Power-Up Methods ==========

  /// Trigger a power-up effect
  Future<void> triggerPowerUp(PowerUpType type) async {
    if (_settingsProvider == null) return;
    
    // Check if user has the power-up
    if (_settingsProvider.getPowerUpCount(type) <= 0) return;

    bool success = false;

    switch (type) {
      case PowerUpType.shuffle:
        success = _activateShuffle();
        break;
      case PowerUpType.wildPiece:
        success = _activateWildPiece();
        break;
      case PowerUpType.lineClear:
        success = _activateRandomLineClear();
        break;
      case PowerUpType.bomb:
        // Bomb requires position selection - handled separately
        success = false;
        break;
      case PowerUpType.colorBomb:
        success = _activateColorBomb();
        break;
    }

    if (success) {
      await _settingsProvider.usePowerUp(type);
      notifyListeners();
    }
  }

  /// Shuffle: Replace all hand pieces with new random ones
  bool _activateShuffle() {
    final config = GameModeConfig.fromMode(_gameMode);
    _hand = _generateRandomHand(config.handSize);
    _soundService.playRefill();
    return true;
  }

  /// Wild Piece: Add a 1x1 piece that can be placed anywhere
  bool _activateWildPiece() {
    final wildPiece = Piece(
      id: 'wild_${DateTime.now().millisecondsSinceEpoch}',
      shape: [[true]],
      color: const Color(0xFFFFD700), // Gold color for wild piece
    );
    _hand.add(wildPiece);
    _soundService.playPlace();
    notifyListeners();
    return true;
  }

  /// Line Clear: Clear a random filled row or column
  bool _activateRandomLineClear() {
    if (_board == null) return false;

    // Find all rows and columns that have at least one block
    final filledRows = <int>[];
    final filledCols = <int>[];

    for (int row = 0; row < _board!.size; row++) {
      for (int col = 0; col < _board!.size; col++) {
        if (_board!.grid[row][col].type == BlockType.filled) {
          if (!filledRows.contains(row)) filledRows.add(row);
          if (!filledCols.contains(col)) filledCols.add(col);
        }
      }
    }

    if (filledRows.isEmpty && filledCols.isEmpty) return false;

    // Randomly pick a row or column
    final allLines = [...filledRows, ...filledCols.map((c) => -c - 1)]; // Negative for cols
    allLines.shuffle();
    final selectedLine = allLines.first;

    final clearedBlocks = <ClearedBlockInfo>[];

    if (selectedLine >= 0) {
      // Clear row
      for (int col = 0; col < _board!.size; col++) {
        if (_board!.grid[selectedLine][col].type == BlockType.filled) {
          clearedBlocks.add(ClearedBlockInfo(
            row: selectedLine,
            col: col,
            color: _board!.grid[selectedLine][col].color!,
          ));
          _board!.grid[selectedLine][col] = BoardBlock(type: BlockType.empty);
        }
      }
    } else {
      // Clear column
      final col = -selectedLine - 1;
      for (int row = 0; row < _board!.size; row++) {
        if (_board!.grid[row][col].type == BlockType.filled) {
          clearedBlocks.add(ClearedBlockInfo(
            row: row,
            col: col,
            color: _board!.grid[row][col].color!,
          ));
          _board!.grid[row][col] = BoardBlock(type: BlockType.empty);
        }
      }
    }

    // Award points
    _score += clearedBlocks.length * 10;
    _soundService.playClear(1);

    // Trigger particles
    if (onLinesCleared != null && clearedBlocks.isNotEmpty) {
      onLinesCleared!(clearedBlocks, 1);
    }

    notifyListeners();
    return true;
  }

  /// Color Bomb: Clear all blocks of the most common color
  bool _activateColorBomb() {
    if (_board == null) return false;

    // Count blocks by color
    final colorCounts = <Color, int>{};
    for (int row = 0; row < _board!.size; row++) {
      for (int col = 0; col < _board!.size; col++) {
        final block = _board!.grid[row][col];
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
    for (int row = 0; row < _board!.size; row++) {
      for (int col = 0; col < _board!.size; col++) {
        final block = _board!.grid[row][col];
        if (block.type == BlockType.filled && block.color == mostCommonColor) {
          clearedBlocks.add(ClearedBlockInfo(
            row: row,
            col: col,
            color: block.color!,
          ));
          _board!.grid[row][col] = BoardBlock(type: BlockType.empty);
        }
      }
    }

    // Award points
    _score += clearedBlocks.length * 15;
    _soundService.playClear(clearedBlocks.length ~/ _board!.size);

    // Trigger particles
    if (onLinesCleared != null && clearedBlocks.isNotEmpty) {
      onLinesCleared!(clearedBlocks, clearedBlocks.length ~/ _board!.size);
    }

    notifyListeners();
    return true;
  }
}
