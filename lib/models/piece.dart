import 'package:flutter/material.dart';
import 'dart:math' as math;

class PieceShape {
  final List<List<bool>> matrix;
  final double distributionPoints;

  const PieceShape({
    required this.matrix,
    required this.distributionPoints,
  });
}

class Piece {
  final String id;
  final List<List<bool>> shape;
  final Color color;

  Piece({
    required this.id,
    required this.shape,
    required this.color,
  });

  int get width => shape.isEmpty ? 0 : shape[0].length;
  int get height => shape.length;

  int getBlockCount() {
    int count = 0;
    for (var row in shape) {
      for (var cell in row) {
        if (cell) count++;
      }
    }
    return count;
  }

  Piece copyWith({String? id, List<List<bool>>? shape, Color? color}) {
    return Piece(
      id: id ?? this.id,
      shape: shape ?? this.shape,
      color: color ?? this.color,
    );
  }

  // Serialization methods
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shape': shape,
      'color': color.value,
    };
  }

  factory Piece.fromJson(Map<String, dynamic> json) {
    return Piece(
      id: json['id'] as String,
      shape: (json['shape'] as List).map((row) => 
        (row as List).map((cell) => cell as bool).toList()
      ).toList(),
      color: Color(json['color'] as int),
    );
  }

  // Static factory for random piece
  static Piece random() => PieceLibrary.createRandomPiece();
  
  /// Create piece from shape index (for bag system)
  static Piece fromShapeIndex(int index, {List<Color>? themeColors}) {
    return PieceLibrary.createPieceFromIndex(index, themeColors: themeColors);
  }
}

// Predefined piece shapes from blockerino-master with distribution points
class PieceLibrary {
  static const List<PieceShape> pieceShapes = [
    // L-shapes (8 rotations)
    PieceShape(matrix: [[true, false, false], [true, true, true]], distributionPoints: 2),
    PieceShape(matrix: [[true, true], [true, false], [true, false]], distributionPoints: 2),
    PieceShape(matrix: [[true, true, true], [false, false, true]], distributionPoints: 2),
    PieceShape(matrix: [[false, true], [false, true], [true, true]], distributionPoints: 2),
    PieceShape(matrix: [[false, false, true], [true, true, true]], distributionPoints: 2),
    PieceShape(matrix: [[true, false], [true, false], [true, true]], distributionPoints: 2),
    PieceShape(matrix: [[true, true, true], [true, false, false]], distributionPoints: 2),
    PieceShape(matrix: [[true, true], [false, true], [false, true]], distributionPoints: 2),

    // Triangle shapes (4 rotations)
    PieceShape(matrix: [[true, true, true], [false, true, false]], distributionPoints: 1.5),
    PieceShape(matrix: [[true, false], [true, true], [true, false]], distributionPoints: 1.5),
    PieceShape(matrix: [[false, true, false], [true, true, true]], distributionPoints: 1.5),
    PieceShape(matrix: [[false, true], [true, true], [false, true]], distributionPoints: 1.5),

    // Z/S shapes (4 rotations)
    PieceShape(matrix: [[false, true, true], [true, true, false]], distributionPoints: 1),
    PieceShape(matrix: [[true, false], [true, true], [false, true]], distributionPoints: 1),
    PieceShape(matrix: [[true, true, false], [false, true, true]], distributionPoints: 1),
    PieceShape(matrix: [[false, true], [true, true], [true, false]], distributionPoints: 1),

    // 3x3 square
    PieceShape(matrix: [[true, true, true], [true, true, true], [true, true, true]], distributionPoints: 3),

    // 2x2 square
    PieceShape(matrix: [[true, true], [true, true]], distributionPoints: 6),

    // 4x1 vertical
    PieceShape(matrix: [[true], [true], [true], [true]], distributionPoints: 2),

    // 1x4 horizontal
    PieceShape(matrix: [[true, true, true, true]], distributionPoints: 2),

    // 3x1 vertical
    PieceShape(matrix: [[true], [true], [true]], distributionPoints: 4),

    // 1x3 horizontal
    PieceShape(matrix: [[true, true, true]], distributionPoints: 4),

    // 2x1 vertical
    PieceShape(matrix: [[true], [true]], distributionPoints: 8),

    // 1x2 horizontal
    PieceShape(matrix: [[true, true]], distributionPoints: 8),

    // Single block
    PieceShape(matrix: [[true]], distributionPoints: 12),

    // 5x1 vertical
    PieceShape(matrix: [[true], [true], [true], [true], [true]], distributionPoints: 1),

    // 1x5 horizontal
    PieceShape(matrix: [[true, true, true, true, true]], distributionPoints: 1),
  ];

  static final List<Color> colors = [
    const Color(0xFFFF4757), // Vibrant Red
    const Color(0xFF1E90FF), // Dodger Blue
    const Color(0xFF2ED573), // Bright Green
    const Color(0xFFFFD700), // Gold
    const Color(0xFFFF6348), // Coral Orange
    const Color(0xFF9B59B6), // Royal Purple
    const Color(0xFF00D2D3), // Cyan
    const Color(0xFFFF69B4), // Hot Pink
  ];

  static Piece createRandomPiece({List<Color>? themeColors}) {
    final random = math.Random();
    final colorPalette = themeColors ?? colors;
    
    // Calculate total distribution points
    double totalPoints = 0;
    for (var shape in pieceShapes) {
      totalPoints += shape.distributionPoints;
    }

    // Weighted random selection
    double randomValue = random.nextDouble() * totalPoints;
    double currentSum = 0;
    
    for (var shape in pieceShapes) {
      currentSum += shape.distributionPoints;
      if (randomValue <= currentSum) {
        final colorIndex = random.nextInt(colorPalette.length);
        return Piece(
          id: 'piece_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(10000)}',
          shape: shape.matrix,
          color: colorPalette[colorIndex],
        );
      }
    }

    // Fallback (should never reach here)
    final shapeIndex = random.nextInt(pieceShapes.length);
    final colorIndex = random.nextInt(colorPalette.length);
    return Piece(
      id: 'piece_${DateTime.now().millisecondsSinceEpoch}',
      shape: pieceShapes[shapeIndex].matrix,
      color: colorPalette[colorIndex],
    );
  }

  static List<Piece> createRandomHand(int count, {List<Color>? themeColors}) {
    return List.generate(count, (index) {
      return createRandomPiece(themeColors: themeColors);
    });
  }
  
  /// Create piece from specific index (for bag system)
  static Piece createPieceFromIndex(int index, {List<Color>? themeColors}) {
    final random = math.Random();
    final colorPalette = themeColors ?? colors;
    if (index < 0 || index >= pieceShapes.length) {
      index = random.nextInt(pieceShapes.length);
    }
    
    final shape = pieceShapes[index];
    final colorIndex = random.nextInt(colorPalette.length);
    
    return Piece(
      id: 'piece_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(10000)}',
      shape: shape.matrix,
      color: colorPalette[colorIndex],
    );
  }
}