import 'package:flutter/material.dart';

/// Shared board configuration to ensure consistent sizing across
/// the visual board and drag target calculations
class BoardConfig {
  // Board size multipliers
  static const double widthMultiplier = 0.9;
  static const double heightMultiplier = 0.55;
  
  // Padding and border constants
  static const double containerPadding = 4.0;
  static const double borderWidth = 2.0;
  
  /// Calculate the board size based on screen dimensions
  /// This ensures the board fits properly and maintains aspect ratio
  static double getSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxWidth = screenWidth * widthMultiplier;
    final maxHeight = screenHeight * heightMultiplier;
    return maxWidth < maxHeight ? maxWidth : maxHeight;
  }
  
  /// Calculate the effective size (accounting for padding and borders)
  static double getEffectiveSize(BuildContext context) {
    final boardSize = getSize(context);
    return boardSize - (containerPadding * 2) - (borderWidth * 2);
  }
  
  /// Calculate block size for a given board size (8x8 or 10x10)
  static double getBlockSize(BuildContext context, int gridSize) {
    final effectiveSize = getEffectiveSize(context);
    return effectiveSize / gridSize;
  }
}
