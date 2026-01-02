import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/piece.dart';
import '../models/board.dart';

/// Service for generating game pieces using weighted random bag system
class PieceGenerationService {
  // Piece distribution constants
  static const List<int> easyPieceIndices = [20, 21, 22, 23, 24];
  static const List<int> hardPieceIndices = [16, 17, 18, 19, 25, 26];
  static const int mediumPieceCount = 16; // Indices 0-15

  // Bag system state
  List<int> _pieceBag = [];
  int _bagIndex = 0;
  int _bagRefillCount = 0;

  /// Reset the bag system for a new game
  void reset() {
    _pieceBag.clear();
    _bagIndex = 0;
    _bagRefillCount = 0;
  }

  /// Get current bag state for saving
  Map<String, dynamic> getState() {
    return {
      'pieceBag': List<int>.from(_pieceBag),
      'bagIndex': _bagIndex,
      'bagRefillCount': _bagRefillCount,
    };
  }

  /// Restore bag state from saved game
  void restoreState(Map<String, dynamic> state) {
    _pieceBag = List<int>.from(state['pieceBag'] ?? []);
    _bagIndex = state['bagIndex'] ?? 0;
    _bagRefillCount = state['bagRefillCount'] ?? 0;
  }

  /// Generate a random hand of pieces
  List<Piece> generateHand(int count, {List<Color>? themeColors}) {
    final hand = <Piece>[];

    for (int i = 0; i < count; i++) {
      // Refill bag if empty
      if (_bagIndex >= _pieceBag.length) {
        _refillBag();
        _bagIndex = 0;
      }

      // Draw piece from bag
      final pieceIndex = _pieceBag[_bagIndex++];
      hand.add(Piece.fromShapeIndex(pieceIndex, themeColors: themeColors));
    }

    return hand;
  }

  /// Generate hand with adaptive distribution based on board state
  List<Piece> generateAdaptiveHand(
    int count,
    Board board, {
    List<Color>? themeColors,
  }) {
    // Update distribution based on board density before generating
    _updateDistributionForBoard(board);
    return generateHand(count, themeColors: themeColors);
  }

  /// Calculate board density (0.0 to 1.0)
  double _calculateBoardDensity(Board board) {
    final totalCells = board.size * board.size;
    int filledCells = 0;

    for (int row = 0; row < board.size; row++) {
      for (int col = 0; col < board.size; col++) {
        if (board.grid[row][col].type == BlockType.filled) {
          filledCells++;
        }
      }
    }

    return filledCells / totalCells;
  }

  /// Update piece distribution based on board state
  void _updateDistributionForBoard(Board board) {
    // Only refill if bag needs refilling
    if (_bagIndex < _pieceBag.length) return;

    final density = _calculateBoardDensity(board);
    _refillBagWithDensity(density);
    _bagIndex = 0;
  }

  /// Get distribution percentages based on board density
  (int easy, int medium, int hard) _getDistribution(double density) {
    if (density > 0.75) {
      // Board almost full - give easier pieces (mercy mode)
      return (70, 25, 5);
    } else if (density > 0.60) {
      return (60, 30, 10);
    } else if (density > 0.40) {
      return (50, 35, 15);
    } else {
      // Board empty - can give harder pieces
      return (45, 35, 20);
    }
  }

  /// Refill bag with default distribution
  void _refillBag() {
    _refillBagWithDistribution(50, 35, 15);
  }

  /// Refill bag based on board density
  void _refillBagWithDensity(double density) {
    final (easy, medium, hard) = _getDistribution(density);
    _refillBagWithDistribution(easy, medium, hard);
  }

  /// Refill the piece bag with specified distribution
  void _refillBagWithDistribution(int easyCount, int mediumCount, int hardCount) {
    _pieceBag.clear();
    _bagRefillCount++;

    // Add easy pieces
    _addPiecesToBag(easyPieceIndices, easyCount);

    // Add medium pieces (indices 0-15)
    _addMediumPiecesToBag(mediumCount);

    // Add hard pieces
    _addPiecesToBag(hardPieceIndices, hardCount);

    // Fisher-Yates shuffle
    _shuffleBag();
  }

  /// Add pieces of a category to the bag
  void _addPiecesToBag(List<int> pieceIndices, int totalCount) {
    final perPiece = totalCount ~/ pieceIndices.length;
    final remainder = totalCount % pieceIndices.length;

    // Add base count for each piece type
    for (int i = 0; i < perPiece; i++) {
      _pieceBag.addAll(pieceIndices);
    }

    // Add remainder with rotation for fairness
    for (int i = 0; i < remainder; i++) {
      _pieceBag.add(pieceIndices[(_bagRefillCount + i) % pieceIndices.length]);
    }
  }

  /// Add medium pieces (special handling for 16 piece types)
  void _addMediumPiecesToBag(int totalCount) {
    final perPiece = totalCount ~/ mediumPieceCount;
    final remainder = totalCount % mediumPieceCount;

    for (int i = 0; i < perPiece; i++) {
      _pieceBag.addAll(List.generate(mediumPieceCount, (index) => index));
    }

    // Rotate starting index for fairness
    final startIndex = (_bagRefillCount * 3) % mediumPieceCount;
    for (int i = 0; i < remainder; i++) {
      _pieceBag.add((startIndex + i) % mediumPieceCount);
    }
  }

  /// Shuffle the bag using Fisher-Yates algorithm
  void _shuffleBag() {
    final rng = math.Random();
    for (int i = _pieceBag.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final temp = _pieceBag[i];
      _pieceBag[i] = _pieceBag[j];
      _pieceBag[j] = temp;
    }
  }
}
