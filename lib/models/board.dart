import 'package:flutter/material.dart';
import 'piece.dart';

enum BlockType {
  empty,
  filled,
  hover,
  hoverBreak, // Will show lines that are about to be cleared
  hoverBreakFilled, // Filled blocks in lines that will be cleared
  hoverBreakEmpty, // Empty blocks in lines that will be cleared
}

/// Info about a cleared block for particle effects
class ClearedBlockInfo {
  final int row;
  final int col;
  final Color? color;
  final int delayMs; // Delay for ripple effect animation

  ClearedBlockInfo({
    required this.row,
    required this.col,
    this.color,
    this.delayMs = 0,
  });
}

/// Result of line clearing operation
class LineClearResult {
  final int lineCount;
  final List<ClearedBlockInfo> clearedBlocks;

  LineClearResult({
    required this.lineCount,
    required this.clearedBlocks,
  });
}

class BoardBlock {
  final BlockType type;
  final Color? color;
  final Color? hoverBreakColor; // Color to show for hover break effect

  BoardBlock({
    required this.type,
    this.color,
    this.hoverBreakColor,
  });

  BoardBlock copyWith({BlockType? type, Color? color, Color? hoverBreakColor}) {
    return BoardBlock(
      type: type ?? this.type,
      color: color ?? this.color,
      hoverBreakColor: hoverBreakColor ?? this.hoverBreakColor,
    );
  }
}

class Board {
  final int size;
  late List<List<BoardBlock>> grid;
  late BigInt _bitboard; // Bitboard for O(1) collision detection
  late List<BigInt> _rowMasks; // Pre-calculated masks for O(1) row checks
  late List<BigInt> _colMasks; // Pre-calculated masks for O(1) column checks

  Board({required this.size}) {
    grid = List.generate(
      size,
      (i) => List.generate(
        size,
        (j) => BoardBlock(type: BlockType.empty),
      ),
    );
    _initializeMasks();
    _updateBitboard();
  }

  Board.fromGrid(this.size, this.grid) {
    _initializeMasks();
    _updateBitboard();
  }

  /// Pre-calculate row and column masks for O(1) line checking
  void _initializeMasks() {
    _rowMasks = List.generate(size, (row) {
      BigInt mask = BigInt.zero;
      for (int col = 0; col < size; col++) {
        mask |= BigInt.one << (row * size + col);
      }
      return mask;
    });

    _colMasks = List.generate(size, (col) {
      BigInt mask = BigInt.zero;
      for (int row = 0; row < size; row++) {
        mask |= BigInt.one << (row * size + col);
      }
      return mask;
    });
  }

  /// Updates the bitboard representation of the grid
  void _updateBitboard() {
    _bitboard = BigInt.zero;
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (grid[row][col].type == BlockType.filled ||
            grid[row][col].type == BlockType.hoverBreakFilled) {
          _bitboard |= BigInt.one << (row * size + col);
        }
      }
    }
  }

  /// Public method to update the bitboard
  void updateBitboard() {
    _updateBitboard();
  }

  bool canPlacePiece(Piece piece, int x, int y) {
    // 1. Boundary Checks (O(1)) - More forgiving for easier placement
    // Allow slight edge cases (within 1 pixel tolerance)
    if (x < -1 || y < -1) return false;
    if (x + piece.width > size + 1 || y + piece.height > size + 1) return false;

    // Clamp coordinates to valid range for actual collision check
    final clampedX = x.clamp(0, size - piece.width);
    final clampedY = y.clamp(0, size - piece.height);

    // If clamping changed the position significantly (>1 cell), reject
    // This allows for slight rounding errors but prevents major misalignment
    if ((clampedX - x).abs() > 1 || (clampedY - y).abs() > 1) {
      return false;
    }

    // Use clamped coordinates for the actual check
    final checkX = clampedX;
    final checkY = clampedY;

    // 2. Bitwise Collision Check (O(1) effectively)
    // Construct piece mask shifted to (checkX, checkY) - use clamped coordinates
    BigInt pieceMask = BigInt.zero;
    for (int r = 0; r < piece.height; r++) {
      for (int c = 0; c < piece.width; c++) {
        if (piece.shape[r][c]) {
          pieceMask |= BigInt.one << ((checkY + r) * size + (checkX + c));
        }
      }
    }

    // Check intersection
    return (_bitboard & pieceMask) == BigInt.zero;
  }

  void placePiece(Piece piece, int x, int y,
      {BlockType type = BlockType.filled}) {
    // Clamp coordinates to ensure piece fits within bounds
    final clampedX = x.clamp(0, size - piece.width);
    final clampedY = y.clamp(0, size - piece.height);

    for (int row = 0; row < piece.height; row++) {
      for (int col = 0; col < piece.width; col++) {
        if (piece.shape[row][col]) {
          final boardX = clampedX + col;
          final boardY = clampedY + row;
          // Double-check bounds (safety check)
          if (boardX >= 0 && boardX < size && boardY >= 0 && boardY < size) {
            grid[boardY][boardX] = BoardBlock(
              type: type,
              color: piece.color,
            );
          }
        }
      }
    }
    // Update bitboard after placement
    if (type == BlockType.filled) {
      _updateBitboard();
    }
  }

  void clearHoverBlocks() {
    // Clear hover break indicators (line-clearing preview)
    // Note: Piece preview is handled by GhostPiecePreview widget, not BlockType.hover
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        final blockType = grid[row][col].type;
        if (blockType == BlockType.hoverBreakEmpty) {
          grid[row][col] = BoardBlock(type: BlockType.empty);
        } else if (blockType == BlockType.hoverBreakFilled) {
          grid[row][col] = BoardBlock(
            type: BlockType.filled,
            color: grid[row][col].color,
          );
        } else if (blockType == BlockType.hoverBreak) {
          grid[row][col] = BoardBlock(type: BlockType.empty);
        }
        // Note: BlockType.hover is no longer used (replaced by GhostPiecePreview widget)
      }
    }
  }

  // Update hover blocks to show which lines will be cleared
  // NOTE: Piece preview is handled by GhostPiecePreview widget, not BlockType.hover
  // This method only marks which lines will be cleared (hoverBreak types)
  void updateHoveredBreaks(Piece piece, int x, int y) {
    // Temporarily mark piece cells to check for line completion
    // We'll use a temporary marker that won't be rendered
    final tempPieceCells = <String>{};
    for (int row = 0; row < piece.height; row++) {
      for (int col = 0; col < piece.width; col++) {
        if (piece.shape[row][col]) {
          final boardX = x + col;
          final boardY = y + row;
          if (boardX >= 0 && boardX < size && boardY >= 0 && boardY < size) {
            tempPieceCells.add('$boardY-$boardX');
          }
        }
      }
    }

    // Check which rows and columns would be complete
    Set<int> rowsToClear = {};
    Set<int> colsToClear = {};

    // Check rows
    for (int row = 0; row < size; row++) {
      bool isFull = true;
      for (int col = 0; col < size; col++) {
        final blockType = grid[row][col].type;
        final isPieceCell = tempPieceCells.contains('$row-$col');
        if (blockType != BlockType.filled && !isPieceCell) {
          isFull = false;
          break;
        }
      }
      if (isFull) rowsToClear.add(row);
    }

    // Check columns
    for (int col = 0; col < size; col++) {
      bool isFull = true;
      for (int row = 0; row < size; row++) {
        final blockType = grid[row][col].type;
        final isPieceCell = tempPieceCells.contains('$row-$col');
        if (blockType != BlockType.filled && !isPieceCell) {
          isFull = false;
          break;
        }
      }
      if (isFull) colsToClear.add(col);
    }

    // If there are lines to clear, mark them with hover break
    if (rowsToClear.isNotEmpty || colsToClear.isNotEmpty) {
      for (int row in rowsToClear) {
        for (int col = 0; col < size; col++) {
          final isPieceCell = tempPieceCells.contains('$row-$col');
          if (grid[row][col].type == BlockType.filled) {
            grid[row][col] = BoardBlock(
              type: BlockType.hoverBreakFilled,
              color: grid[row][col].color,
              hoverBreakColor: piece.color,
            );
          } else if (grid[row][col].type == BlockType.empty || isPieceCell) {
            grid[row][col] = BoardBlock(
              type: BlockType.hoverBreakEmpty,
              color: piece.color,
              hoverBreakColor: piece.color,
            );
          }
        }
      }

      for (int col in colsToClear) {
        for (int row = 0; row < size; row++) {
          final isPieceCell = tempPieceCells.contains('$row-$col');
          if (grid[row][col].type == BlockType.filled) {
            grid[row][col] = BoardBlock(
              type: BlockType.hoverBreakFilled,
              color: grid[row][col].color,
              hoverBreakColor: piece.color,
            );
          } else if (grid[row][col].type == BlockType.empty || isPieceCell) {
            grid[row][col] = BoardBlock(
              type: BlockType.hoverBreakEmpty,
              color: piece.color,
              hoverBreakColor: piece.color,
            );
          }
        }
      }
    }
  }

  /// Break complete lines and return info about cleared blocks
  /// Returns a tuple of (lineCount, clearedBlocks) for particle effects
  LineClearResult breakLinesWithInfo() {
    List<int> rowsToClear = [];
    List<int> colsToClear = [];
    List<ClearedBlockInfo> clearedBlocks = [];

    // Check rows using O(1) bitwise operations
    for (int row = 0; row < size; row++) {
      if ((_bitboard & _rowMasks[row]) == _rowMasks[row]) {
        rowsToClear.add(row);
      }
    }

    // Check columns using O(1) bitwise operations
    for (int col = 0; col < size; col++) {
      if ((_bitboard & _colMasks[col]) == _colMasks[col]) {
        colsToClear.add(col);
      }
    }

    // Collect info about blocks to clear (before clearing)
    // Calculate delays for ripple effect (from center outward)
    Set<String> clearedPositions = {};
    final centerCol = size / 2.0;
    final centerRow = size / 2.0;
    const delayPerUnit = 30; // 30ms delay per unit distance from center

    for (int row in rowsToClear) {
      for (int col = 0; col < size; col++) {
        final key = '$row-$col';
        if (!clearedPositions.contains(key)) {
          clearedPositions.add(key);
          // Calculate distance from center for ripple delay
          final distanceFromCenter = (col - centerCol).abs();
          final delay = (distanceFromCenter * delayPerUnit).toInt();
          clearedBlocks.add(ClearedBlockInfo(
            row: row,
            col: col,
            color: grid[row][col].color,
            delayMs: delay,
          ));
        }
      }
    }

    for (int col in colsToClear) {
      for (int row = 0; row < size; row++) {
        final key = '$row-$col';
        if (!clearedPositions.contains(key)) {
          clearedPositions.add(key);
          // Calculate distance from center for ripple delay
          final distanceFromCenter = (row - centerRow).abs();
          final delay = (distanceFromCenter * delayPerUnit).toInt();
          clearedBlocks.add(ClearedBlockInfo(
            row: row,
            col: col,
            color: grid[row][col].color,
            delayMs: delay,
          ));
        }
      }
    }

    // Clear lines
    for (int row in rowsToClear) {
      for (int col = 0; col < size; col++) {
        grid[row][col] = BoardBlock(type: BlockType.empty);
      }
    }

    for (int col in colsToClear) {
      for (int row = 0; row < size; row++) {
        grid[row][col] = BoardBlock(type: BlockType.empty);
      }
    }

    if (rowsToClear.isNotEmpty || colsToClear.isNotEmpty) {
      _updateBitboard();
    }

    return LineClearResult(
      lineCount: rowsToClear.length + colsToClear.length,
      clearedBlocks: clearedBlocks,
    );
  }

  int breakLines() {
    return breakLinesWithInfo().lineCount;
  }

  Board clone() {
    final newGrid = List.generate(
      size,
      (row) => List.generate(
        size,
        (col) => grid[row][col].copyWith(),
      ),
    );
    return Board.fromGrid(size, newGrid);
  }

  /// Optimized deadlock detection (Section 4.4 of technical document)
  /// Uses early exit and space mapping for O(k*N^2) -> O(k*N) average case
  bool hasAnyValidMove(List<Piece> hand) {
    // Early exit: If hand is empty, no valid moves
    if (hand.isEmpty) {
      return false;
    }

    // Early exit: Calculate largest contiguous empty region
    final maxEmptyRegion = _getLargestEmptyRegion();
    final minPieceSize =
        hand.map((p) => p.getBlockCount()).reduce((a, b) => a < b ? a : b);

    // Fail-fast: If largest empty space < smallest piece, game over
    if (maxEmptyRegion < minPieceSize) {
      return false;
    }

    // Check each piece against all positions
    for (var piece in hand) {
      for (int row = 0; row < size; row++) {
        for (int col = 0; col < size; col++) {
          if (canPlacePiece(piece, col, row)) {
            return true; // Early exit on first valid move
          }
        }
      }
    }
    return false;
  }

  /// Calculate largest contiguous empty region for optimization
  int _getLargestEmptyRegion() {
    int maxRegion = 0;
    final visited = List.generate(size, (_) => List.filled(size, false));

    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (grid[row][col].type == BlockType.empty && !visited[row][col]) {
          final regionSize = _floodFillCount(row, col, visited);
          if (regionSize > maxRegion) maxRegion = regionSize;
        }
      }
    }
    return maxRegion;
  }

  /// Flood fill to count contiguous empty cells
  int _floodFillCount(int row, int col, List<List<bool>> visited) {
    if (row < 0 || row >= size || col < 0 || col >= size) return 0;
    if (visited[row][col] || grid[row][col].type != BlockType.empty) return 0;

    visited[row][col] = true;
    int count = 1;

    // Check 4 neighbors (non-recursive for stack safety)
    final queue = <List<int>>[
      [row, col]
    ];
    int queueIndex = 0;

    while (queueIndex < queue.length) {
      final current = queue[queueIndex++];
      final r = current[0];
      final c = current[1];

      final neighbors = [
        [r - 1, c],
        [r + 1, c],
        [r, c - 1],
        [r, c + 1]
      ];

      for (final neighbor in neighbors) {
        final nr = neighbor[0];
        final nc = neighbor[1];
        if (nr >= 0 &&
            nr < size &&
            nc >= 0 &&
            nc < size &&
            !visited[nr][nc] &&
            grid[nr][nc].type == BlockType.empty) {
          visited[nr][nc] = true;
          count++;
          queue.add([nr, nc]);
        }
      }
    }

    return count;
  }

  /// Get board density (percentage of filled cells) for adaptive piece generation
  double getDensity() {
    int filledCount = 0;
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (grid[row][col].type == BlockType.filled) filledCount++;
      }
    }
    return filledCount / (size * size);
  }

  // Serialization methods
  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'grid': grid
          .map((row) => row
              .map((block) => {
                    'type': block.type.index,
                    'color': block.color
                        ?.toARGB32(), // Use toARGB32() instead of deprecated .value
                  })
              .toList())
          .toList(),
    };
  }

  factory Board.fromJson(Map<String, dynamic> json) {
    final size = json['size'] as int;
    final gridData = json['grid'] as List;

    final grid = List.generate(
      size,
      (row) => List.generate(
        size,
        (col) {
          final blockData = gridData[row][col] as Map<String, dynamic>;
          final typeIndex = blockData['type'] as int;
          final colorValue = blockData['color'] as int?;

          return BoardBlock(
            type: BlockType.values[typeIndex],
            color: colorValue != null ? Color(colorValue) : null,
          );
        },
      ),
    );

    return Board.fromGrid(size, grid);
  }
}
