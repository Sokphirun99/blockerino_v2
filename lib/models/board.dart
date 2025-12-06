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

  Board({required this.size}) {
    grid = List.generate(
      size,
      (i) => List.generate(
        size,
        (j) => BoardBlock(type: BlockType.empty),
      ),
    );
  }

  Board.fromGrid(this.size, this.grid);

  bool canPlacePiece(Piece piece, int x, int y) {
    if (x < 0 || y < 0) return false;
    if (x + piece.width > size || y + piece.height > size) return false;

    for (int row = 0; row < piece.height; row++) {
      for (int col = 0; col < piece.width; col++) {
        if (piece.shape[row][col]) {
          final boardX = x + col;
          final boardY = y + row;
          if (grid[boardY][boardX].type == BlockType.filled) {
            return false;
          }
        }
      }
    }
    return true;
  }

  void placePiece(Piece piece, int x, int y, {BlockType type = BlockType.filled}) {
    for (int row = 0; row < piece.height; row++) {
      for (int col = 0; col < piece.width; col++) {
        if (piece.shape[row][col]) {
          final boardX = x + col;
          final boardY = y + row;
          grid[boardY][boardX] = BoardBlock(
            type: type,
            color: piece.color,
          );
        }
      }
    }
  }

  void clearHoverBlocks() {
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        final blockType = grid[row][col].type;
        if (blockType == BlockType.hover ||
            blockType == BlockType.hoverBreakEmpty) {
          grid[row][col] = BoardBlock(type: BlockType.empty);
        } else if (blockType == BlockType.hoverBreakFilled) {
          grid[row][col] = BoardBlock(
            type: BlockType.filled,
            color: grid[row][col].color,
          );
        } else if (blockType == BlockType.hoverBreak) {
          grid[row][col] = BoardBlock(type: BlockType.empty);
        }
      }
    }
  }

  // Update hover blocks to show which lines will be cleared
  void updateHoveredBreaks(Piece piece, int x, int y) {
    // First place the piece temporarily as hover
    for (int row = 0; row < piece.height; row++) {
      for (int col = 0; col < piece.width; col++) {
        if (piece.shape[row][col]) {
          final boardX = x + col;
          final boardY = y + row;
          grid[boardY][boardX] = BoardBlock(
            type: BlockType.hover,
            color: piece.color,
          );
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
        if (blockType != BlockType.filled && blockType != BlockType.hover) {
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
        if (blockType != BlockType.filled && blockType != BlockType.hover) {
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
          if (grid[row][col].type == BlockType.filled) {
            grid[row][col] = BoardBlock(
              type: BlockType.hoverBreakFilled,
              color: grid[row][col].color,
              hoverBreakColor: piece.color,
            );
          } else if (grid[row][col].type == BlockType.empty || 
                     grid[row][col].type == BlockType.hover) {
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
          if (grid[row][col].type == BlockType.filled) {
            grid[row][col] = BoardBlock(
              type: BlockType.hoverBreakFilled,
              color: grid[row][col].color,
              hoverBreakColor: piece.color,
            );
          } else if (grid[row][col].type == BlockType.empty ||
                     grid[row][col].type == BlockType.hover) {
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

  int breakLines() {
    List<int> rowsToClear = [];
    List<int> colsToClear = [];

    // Check rows
    for (int row = 0; row < size; row++) {
      bool isFull = true;
      for (int col = 0; col < size; col++) {
        if (grid[row][col].type != BlockType.filled) {
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
        if (grid[row][col].type != BlockType.filled) {
          isFull = false;
          break;
        }
      }
      if (isFull) colsToClear.add(col);
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

    return rowsToClear.length + colsToClear.length;
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

  bool hasAnyValidMove(List<Piece> hand) {
    for (var piece in hand) {
      for (int row = 0; row < size; row++) {
        for (int col = 0; col < size; col++) {
          if (canPlacePiece(piece, col, row)) {
            return true;
          }
        }
      }
    }
    return false;
  }
}
