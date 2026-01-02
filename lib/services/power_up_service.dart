import 'package:flutter/material.dart';
import '../models/board.dart';
import '../models/piece.dart';
import '../models/power_up.dart';
import '../models/game_mode.dart';
import 'sound_service.dart';
import 'piece_generation_service.dart';

/// Result of activating a power-up
class PowerUpResult {
  final bool success;
  final Board? newBoard;
  final int scoreGained;
  final List<ClearedBlockInfo> clearedBlocks;
  final List<Piece>? newHand;

  const PowerUpResult({
    required this.success,
    this.newBoard,
    this.scoreGained = 0,
    this.clearedBlocks = const [],
    this.newHand,
  });

  static const PowerUpResult failed = PowerUpResult(success: false);
}

/// Service for handling power-up activation
class PowerUpService {
  final SoundService _soundService;
  final PieceGenerationService _pieceService;

  PowerUpService({
    required SoundService soundService,
    required PieceGenerationService pieceService,
  })  : _soundService = soundService,
        _pieceService = pieceService;

  /// Activate a power-up and return the result
  PowerUpResult activate({
    required PowerUpType type,
    required Board board,
    required List<Piece> hand,
    required GameMode gameMode,
    List<Color>? themeColors,
  }) {
    switch (type) {
      case PowerUpType.shuffle:
        return _activateShuffle(gameMode, themeColors);
      case PowerUpType.wildPiece:
        return _activateWildPiece(hand);
      case PowerUpType.lineClear:
        return _activateRandomLineClear(board);
      case PowerUpType.bomb:
        return _activateBomb(board);
      case PowerUpType.colorBomb:
        return _activateColorBomb(board);
    }
  }

  /// Shuffle - Replace hand with new random pieces
  PowerUpResult _activateShuffle(GameMode gameMode, List<Color>? themeColors) {
    final config = GameModeConfig.fromMode(gameMode);
    final newHand = _pieceService.generateHand(
      config.handSize,
      themeColors: themeColors,
    );
    _soundService.playRefill();

    return PowerUpResult(
      success: true,
      newHand: newHand,
    );
  }

  /// Wild Piece - Add a single-block golden piece to hand
  PowerUpResult _activateWildPiece(List<Piece> currentHand) {
    final wildPiece = Piece(
      id: 'wild_${DateTime.now().millisecondsSinceEpoch}',
      shape: [
        [true]
      ],
      color: const Color(0xFFFFD700),
    );

    final newHand = List<Piece>.from(currentHand)..add(wildPiece);
    _soundService.playPlace();

    return PowerUpResult(
      success: true,
      newHand: newHand,
    );
  }

  /// Bomb - Clear a 3x3 area with the most filled blocks
  PowerUpResult _activateBomb(Board originalBoard) {
    final board = originalBoard.clone();

    // Find the most filled 3x3 area
    int bestRow = 0;
    int bestCol = 0;
    int maxBlocks = 0;

    for (int row = 0; row < board.size - 2; row++) {
      for (int col = 0; col < board.size - 2; col++) {
        int blockCount = 0;
        for (int dr = 0; dr < 3; dr++) {
          for (int dc = 0; dc < 3; dc++) {
            if (board.grid[row + dr][col + dc].type == BlockType.filled) {
              blockCount++;
            }
          }
        }
        if (blockCount > maxBlocks) {
          maxBlocks = blockCount;
          bestRow = row;
          bestCol = col;
        }
      }
    }

    if (maxBlocks == 0) return PowerUpResult.failed;

    // Clear the 3x3 area
    final clearedBlocks = <ClearedBlockInfo>[];
    for (int dr = 0; dr < 3; dr++) {
      for (int dc = 0; dc < 3; dc++) {
        final row = bestRow + dr;
        final col = bestCol + dc;
        if (board.grid[row][col].type == BlockType.filled) {
          clearedBlocks.add(ClearedBlockInfo(
            row: row,
            col: col,
            color: board.grid[row][col].color!,
          ));
          board.grid[row][col] = const BoardBlock(type: BlockType.empty);
        }
      }
    }

    board.updateBitboard();
    _soundService.playClear(clearedBlocks.length);

    return PowerUpResult(
      success: true,
      newBoard: board,
      scoreGained: clearedBlocks.length * 15,
      clearedBlocks: clearedBlocks,
    );
  }

  /// Line Clear - Clear a random filled row or column
  PowerUpResult _activateRandomLineClear(Board originalBoard) {
    final board = originalBoard.clone();

    // Find all rows and columns with at least one block
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

    if (filledRows.isEmpty && filledCols.isEmpty) {
      return PowerUpResult.failed;
    }

    // Randomly pick a row or column (negative = column)
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
          board.grid[selectedLine][col] = const BoardBlock(type: BlockType.empty);
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
          board.grid[row][col] = const BoardBlock(type: BlockType.empty);
        }
      }
    }

    board.updateBitboard();
    _soundService.playClear(1);

    return PowerUpResult(
      success: true,
      newBoard: board,
      scoreGained: clearedBlocks.length * 10,
      clearedBlocks: clearedBlocks,
    );
  }

  /// Color Bomb - Clear all blocks of the most common color
  PowerUpResult _activateColorBomb(Board originalBoard) {
    final board = originalBoard.clone();

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

    if (colorCounts.isEmpty) return PowerUpResult.failed;

    // Find most common color
    Color? mostCommonColor;
    int maxCount = 0;
    colorCounts.forEach((color, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommonColor = color;
      }
    });

    if (mostCommonColor == null) return PowerUpResult.failed;

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
          board.grid[row][col] = const BoardBlock(type: BlockType.empty);
        }
      }
    }

    board.updateBitboard();
    _soundService.playClear(clearedBlocks.length ~/ board.size);

    return PowerUpResult(
      success: true,
      newBoard: board,
      scoreGained: clearedBlocks.length * 15,
      clearedBlocks: clearedBlocks,
    );
  }
}
