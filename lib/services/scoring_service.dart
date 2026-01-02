import '../models/board.dart';

/// Service for handling game scoring calculations
class ScoringService {
  // Scoring multipliers (Fibonacci-based for exponential combo rewards)
  static const List<int> comboMultipliers = [
    1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144
  ];

  // Scoring constants
  static const int perfectClearBaseBonus = 1000;
  static const int perfectClearComboMultiplier = 100;
  static const int comboResetBuffer = 3;

  /// Calculate score from clearing lines
  /// Returns the points earned from this line clear
  int calculateLineClearScore({
    required int linesBroken,
    required int currentCombo,
    required bool doublePointsActive,
  }) {
    if (linesBroken <= 0) return 0;

    // Get combo multiplier from Fibonacci sequence
    final comboIndex = (currentCombo - 1).clamp(0, comboMultipliers.length - 1);
    final comboMultiplier = comboMultipliers[comboIndex];

    // Multi-line bonus
    final multiLineBonus = getMultiLineBonus(linesBroken);

    // Calculate final score
    final basePoints = linesBroken * 10;
    var finalPoints = (basePoints * comboMultiplier * multiLineBonus).toInt();

    // Apply chaos mode double points
    if (doublePointsActive) {
      finalPoints *= 2;
    }

    return finalPoints;
  }

  /// Get multi-line bonus multiplier
  double getMultiLineBonus(int linesBroken) {
    if (linesBroken >= 4) return 3.0; // Quad clear
    if (linesBroken >= 3) return 2.0; // Triple clear
    if (linesBroken >= 2) return 1.5; // Double clear
    return 1.0; // Single clear
  }

  /// Calculate perfect clear bonus
  int calculatePerfectClearBonus(int currentCombo) {
    return perfectClearBaseBonus + (currentCombo * perfectClearComboMultiplier);
  }

  /// Check if the board is completely empty
  bool isBoardEmpty(Board board) {
    for (int row = 0; row < board.size; row++) {
      for (int col = 0; col < board.size; col++) {
        if (board.grid[row][col].type == BlockType.filled) {
          return false;
        }
      }
    }
    return true;
  }

  /// Update combo state after placing a piece
  /// Returns (newCombo, newLastBrokenLine)
  (int, int) updateComboState({
    required int linesBroken,
    required int currentCombo,
    required int lastBrokenLine,
  }) {
    if (linesBroken > 0) {
      // Lines cleared - increment combo and reset counter to 0 (just broke lines)
      return (currentCombo + 1, 0);
    } else {
      // No lines cleared - increment counter, possibly reset combo
      final newLastBrokenLine = lastBrokenLine + 1;
      final newCombo = newLastBrokenLine > comboResetBuffer ? 0 : currentCombo;
      return (newCombo, newLastBrokenLine);
    }
  }
}
