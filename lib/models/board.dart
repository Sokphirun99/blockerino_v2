import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'piece.dart';

enum BlockType {
  empty,
  filled,
  blocked, // Obstacle cell - cannot be filled
  hover,
  hoverBreak, // Will show lines that are about to be cleared
  hoverBreakFilled, // Filled blocks in lines that will be cleared
  hoverBreakEmpty, // Empty blocks in lines that will be cleared
  ice, // Ice block - 1 hit remaining (cracked)
  ice2, // Ice block - 2 hits remaining (solid)
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
  final List<StarPosition> collectedStars; // Stars collected in this clear

  LineClearResult({
    required this.lineCount,
    required this.clearedBlocks,
    this.collectedStars = const [],
  });
}

/// Position of a star on the board
class StarPosition {
  final int row;
  final int col;

  const StarPosition({required this.row, required this.col});

  String get key => '$row-$col';
}

/// Pre-filled block for level initialization
class PrefilledBlock {
  final int row;
  final int col;
  final Color color;

  const PrefilledBlock({required this.row, required this.col, required this.color});
}

/// Ice block for level initialization
class IceBlock {
  final int row;
  final int col;
  final int hits; // 1 or 2

  const IceBlock({required this.row, required this.col, this.hits = 2});
}

class BoardBlock {
  final BlockType type;
  final Color? color;
  final Color? hoverBreakColor; // Color to show for hover break effect

  const BoardBlock({
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardBlock &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          color == other.color &&
          hoverBreakColor == other.hoverBreakColor;

  @override
  int get hashCode => Object.hash(type, color, hoverBreakColor);
}

class Board {
  final int size;
  late List<List<BoardBlock>> grid;
  late BigInt _collisionBitboard; // Bitboard for O(1) collision detection (includes blocked)
  late BigInt _lineBitboard; // Bitboard for O(1) line completion checks (excludes blocked)
  late List<BigInt> _rowMasks; // Pre-calculated masks for O(1) row checks
  late List<BigInt> _colMasks; // Pre-calculated masks for O(1) column checks
  Set<String> starPositions = {}; // Track star positions as "row-col"

  Board({required this.size, bool addObstacles = false}) {
    grid = List.generate(
      size,
      (i) => List.generate(
        size,
        (j) => const BoardBlock(type: BlockType.empty),
      ),
    );
    
    // Add obstacles for adventure/chaos mode
    if (addObstacles) {
      _addRandomObstacles();
    }
    
    _initializeMasks();
    _updateBitboard();
  }

  Board.fromGrid(this.size, this.grid, {Set<String>? stars}) {
    starPositions = stars ?? {};
    _initializeMasks();
    _updateBitboard();
  }

  /// Initialize board with pre-filled blocks for Block Quest levels
  void initializeWithPrefilled(List<PrefilledBlock> blocks) {
    for (final block in blocks) {
      if (block.row >= 0 && block.row < size && block.col >= 0 && block.col < size) {
        grid[block.row][block.col] = BoardBlock(
          type: BlockType.filled,
          color: block.color,
        );
      }
    }
    _updateBitboard();
  }

  /// Initialize ice blocks for Block Quest levels
  void initializeIceBlocks(List<IceBlock> blocks) {
    const iceColor = Color(0xFF89CFF0); // Light ice blue
    for (final block in blocks) {
      if (block.row >= 0 && block.row < size && block.col >= 0 && block.col < size) {
        grid[block.row][block.col] = BoardBlock(
          type: block.hits >= 2 ? BlockType.ice2 : BlockType.ice,
          color: iceColor,
        );
      }
    }
    _updateBitboard();
  }

  /// Initialize star positions for Block Quest levels
  void initializeStars(List<StarPosition> stars) {
    starPositions = stars.map((s) => s.key).toSet();
  }

  /// Check if a cell has a star
  bool hasStar(int row, int col) => starPositions.contains('$row-$col');

  /// Add random obstacle blocks for adventure mode
  void _addRandomObstacles() {
    final rng = math.Random(DateTime.now().millisecondsSinceEpoch);
    final obstacleCount = (size * size * 0.10).round(); // 10% of board (reduced for better gameplay)
    final obstacles = <int>{};
    final maxCells = size * size;

    // Generate random positions for obstacles using proper RNG
    int attempts = 0;
    while (obstacles.length < obstacleCount && attempts < maxCells * 2) {
      final pos = rng.nextInt(maxCells);
      obstacles.add(pos);
      attempts++;
    }

    // Place obstacles on board
    for (final pos in obstacles) {
      final row = pos ~/ size;
      final col = pos % size;
      grid[row][col] = const BoardBlock(
        type: BlockType.blocked,
        color: Color(0xFF2d3748), // Dark gray for obstacles
      );
    }
  }

  /// Pre-calculate row and column masks for O(1) line checking
  /// Masks exclude blocked cells - lines with blocked cells can still be completed
  /// by filling all non-blocked cells in that line
  void _initializeMasks() {
    _rowMasks = List.generate(size, (row) {
      BigInt mask = BigInt.zero;
      for (int col = 0; col < size; col++) {
        // Only include non-blocked cells in the mask
        if (grid[row][col].type != BlockType.blocked) {
          mask |= BigInt.one << (row * size + col);
        }
      }
      return mask;
    });

    _colMasks = List.generate(size, (col) {
      BigInt mask = BigInt.zero;
      for (int row = 0; row < size; row++) {
        // Only include non-blocked cells in the mask
        if (grid[row][col].type != BlockType.blocked) {
          mask |= BigInt.one << (row * size + col);
        }
      }
      return mask;
    });
  }

  /// Updates both bitboard representations of the grid
  /// - _collisionBitboard: For piece placement (includes blocked cells)
  /// - _lineBitboard: For line completion (excludes blocked cells)
  void _updateBitboard() {
    _collisionBitboard = BigInt.zero;
    _lineBitboard = BigInt.zero;
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        final type = grid[row][col].type;
        final bit = BigInt.one << (row * size + col);

        // Collision bitboard includes ALL solid cells
        if (type == BlockType.filled ||
            type == BlockType.blocked ||
            type == BlockType.ice ||
            type == BlockType.ice2) {
          _collisionBitboard |= bit;
        }

        // Line bitboard excludes blocked cells (they prevent line completion)
        if (type == BlockType.filled ||
            type == BlockType.ice ||
            type == BlockType.ice2) {
          _lineBitboard |= bit;
        }
      }
    }
  }

  /// Public method to update the bitboard
  void updateBitboard() {
    _updateBitboard();
  }

  bool canPlacePiece(Piece piece, int x, int y) {
    // NOTE: Bitboard sync check removed from here for performance
    // It was running on every canPlacePiece call (hundreds of times per frame)
    // If bitboard sync issues occur, they should be fixed at the source (placePiece, power-ups, etc.)

    // 1. Boundary Checks (O(1)) - More forgiving for easier placement
    // Allow slight edge cases (within 1 pixel tolerance)
    if (x < -1 || y < -1) {
      return false;
    }
    if (x + piece.width > size + 1 || y + piece.height > size + 1) {
      return false;
    }

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

    // Check intersection using collision bitboard (includes blocked cells)
    final hasCollision = (_collisionBitboard & pieceMask) != BigInt.zero;
    if (hasCollision) {
      return false;
    }

    return true;
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
          grid[row][col] = const BoardBlock(type: BlockType.empty);
        } else if (blockType == BlockType.hoverBreakFilled) {
          grid[row][col] = BoardBlock(
            type: BlockType.filled,
            color: grid[row][col].color,
          );
        } else if (blockType == BlockType.hoverBreak) {
          grid[row][col] = const BoardBlock(type: BlockType.empty);
        }
        // Note: BlockType.hover is no longer used (replaced by GhostPiecePreview widget)
      }
    }

    // CRITICAL FIX: Update bitboard after clearing hover blocks
    // The bitboard includes hoverBreakFilled blocks, so when we clear them from the grid,
    // we must update the bitboard to reflect the change. Without this, canPlacePiece will
    // incorrectly detect collisions with the ghost piece that was just cleared.
    _updateBitboard();
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

    // Helper to check if a cell is filled (includes ice blocks)
    // NOTE: Blocked cells are NOT included - they are permanent obstacles
    // that prevent line completion (players must work around them)
    bool isCellFilled(BlockType type) {
      return type == BlockType.filled ||
          type == BlockType.ice ||
          type == BlockType.ice2;
    }

    // Check rows
    for (int row = 0; row < size; row++) {
      bool isFull = true;
      for (int col = 0; col < size; col++) {
        final blockType = grid[row][col].type;
        // Skip blocked cells - they don't count for line completion
        if (blockType == BlockType.blocked) continue;
        final isPieceCell = tempPieceCells.contains('$row-$col');
        if (!isCellFilled(blockType) && !isPieceCell) {
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
        // Skip blocked cells - they don't count for line completion
        if (blockType == BlockType.blocked) continue;
        final isPieceCell = tempPieceCells.contains('$row-$col');
        if (!isCellFilled(blockType) && !isPieceCell) {
          isFull = false;
          break;
        }
      }
      if (isFull) colsToClear.add(col);
    }

    // If there are lines to clear, mark them with hover break
    if (rowsToClear.isNotEmpty || colsToClear.isNotEmpty) {
      void markCellForBreak(int row, int col) {
        final isPieceCell = tempPieceCells.contains('$row-$col');
        final blockType = grid[row][col].type;

        // Mark filled blocks for break preview (NOT ice - they keep their type for correct restoration)
        if (blockType == BlockType.filled) {
          grid[row][col] = BoardBlock(
            type: BlockType.hoverBreakFilled,
            color: grid[row][col].color,
            hoverBreakColor: piece.color,
          );
        } else if (blockType == BlockType.empty || isPieceCell) {
          grid[row][col] = BoardBlock(
            type: BlockType.hoverBreakEmpty,
            color: piece.color,
            hoverBreakColor: piece.color,
          );
        }
        // Ice blocks and blocked cells stay as they are (ice will still be part of the clear)
      }

      for (int row in rowsToClear) {
        for (int col = 0; col < size; col++) {
          markCellForBreak(row, col);
        }
      }

      for (int col in colsToClear) {
        for (int row = 0; row < size; row++) {
          markCellForBreak(row, col);
        }
      }
    }
  }

  /// Break complete lines and return info about cleared blocks
  /// Returns a tuple of (lineCount, clearedBlocks) for particle effects
  /// Handles ice blocks (need 2 clears) and star collection
  LineClearResult breakLinesWithInfo() {
    List<int> rowsToClear = [];
    List<int> colsToClear = [];
    List<ClearedBlockInfo> clearedBlocks = [];
    List<StarPosition> collectedStars = [];

    // Check rows using O(1) bitwise operations (uses line bitboard - excludes blocked)
    for (int row = 0; row < size; row++) {
      if ((_lineBitboard & _rowMasks[row]) == _rowMasks[row]) {
        rowsToClear.add(row);
      }
    }

    // Check columns using O(1) bitwise operations (uses line bitboard - excludes blocked)
    for (int col = 0; col < size; col++) {
      if ((_lineBitboard & _colMasks[col]) == _colMasks[col]) {
        colsToClear.add(col);
      }
    }

    // Collect info about blocks to clear (before clearing)
    // Calculate delays for ripple effect (from center outward)
    Set<String> processedPositions = {};
    final centerCol = size / 2.0;
    final centerRow = size / 2.0;
    const delayPerUnit = 30; // 30ms delay per unit distance from center
    const iceColor = Color(0xFF89CFF0);

    // Process all positions that will be affected
    void processPosition(int row, int col, double distanceFromCenter) {
      final key = '$row-$col';
      if (processedPositions.contains(key)) return;
      processedPositions.add(key);

      final block = grid[row][col];
      final delay = (distanceFromCenter * delayPerUnit).toInt();

      // Collect star if present
      if (starPositions.contains(key)) {
        collectedStars.add(StarPosition(row: row, col: col));
        starPositions.remove(key);
      }

      // Add to cleared blocks for particle effects (except ice2 which just cracks)
      if (block.type != BlockType.ice2) {
        clearedBlocks.add(ClearedBlockInfo(
          row: row,
          col: col,
          color: block.color,
          delayMs: delay,
        ));
      }
    }

    for (int row in rowsToClear) {
      for (int col = 0; col < size; col++) {
        final distanceFromCenter = (col - centerCol).abs();
        processPosition(row, col, distanceFromCenter);
      }
    }

    for (int col in colsToClear) {
      for (int row = 0; row < size; row++) {
        final distanceFromCenter = (row - centerRow).abs();
        processPosition(row, col, distanceFromCenter);
      }
    }

    // Clear lines with ice block handling
    // Track cleared cells to prevent double-clearing ice blocks at intersections
    final clearedCells = <String>{};

    void clearCell(int row, int col) {
      final key = '$row-$col';
      // Skip if already cleared this cell (prevents ice2->ice->empty in one move)
      if (clearedCells.contains(key)) return;
      clearedCells.add(key);

      final block = grid[row][col];
      if (block.type == BlockType.ice2) {
        // Ice block with 2 hits -> crack it (1 hit remaining)
        grid[row][col] = const BoardBlock(type: BlockType.ice, color: iceColor);
      } else if (block.type == BlockType.ice) {
        // Ice block with 1 hit -> clear it
        grid[row][col] = const BoardBlock(type: BlockType.empty);
      } else if (block.type != BlockType.blocked) {
        // Regular block -> clear it (but not obstacles)
        grid[row][col] = const BoardBlock(type: BlockType.empty);
      }
    }

    for (int row in rowsToClear) {
      for (int col = 0; col < size; col++) {
        clearCell(row, col);
      }
    }

    for (int col in colsToClear) {
      for (int row = 0; row < size; row++) {
        clearCell(row, col);
      }
    }

    if (rowsToClear.isNotEmpty || colsToClear.isNotEmpty) {
      _updateBitboard();
    }

    return LineClearResult(
      lineCount: rowsToClear.length + colsToClear.length,
      clearedBlocks: clearedBlocks,
      collectedStars: collectedStars,
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
    return Board.fromGrid(size, newGrid, stars: Set.from(starPositions));
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

  /// Check if the board is completely empty (no filled blocks)
  bool isEmpty() {
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (grid[row][col].type == BlockType.filled) {
          return false;
        }
      }
    }
    return true;
  }

  /// Count total filled cells
  int getFilledCount() {
    int count = 0;
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (grid[row][col].type == BlockType.filled) count++;
      }
    }
    return count;
  }

  /// Get all filled block positions as (row, col) pairs
  List<(int row, int col)> getFilledPositions() {
    final positions = <(int, int)>[];
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (grid[row][col].type == BlockType.filled) {
          positions.add((row, col));
        }
      }
    }
    return positions;
  }

  /// Get color distribution on the board
  Map<Color, int> getColorDistribution() {
    final distribution = <Color, int>{};
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        final block = grid[row][col];
        if (block.type == BlockType.filled && block.color != null) {
          distribution[block.color!] = (distribution[block.color!] ?? 0) + 1;
        }
      }
    }
    return distribution;
  }

  /// Find the most common color on the board
  Color? getMostCommonColor() {
    final distribution = getColorDistribution();
    if (distribution.isEmpty) return null;

    Color? mostCommon;
    int maxCount = 0;
    distribution.forEach((color, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommon = color;
      }
    });
    return mostCommon;
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
      'stars': starPositions.toList(),
    };
  }

  factory Board.fromJson(Map<String, dynamic> json) {
    final size = json['size'] as int;
    final gridData = json['grid'] as List;
    final starsData = json['stars'] as List?;

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

    final stars = starsData?.map((s) => s.toString()).toSet() ?? <String>{};
    return Board.fromGrid(size, grid, stars: stars);
  }
}
