import 'package:flutter/material.dart';
import '../models/board.dart';

/// Optimized board grid using CustomPaint for better performance
class OptimizedBoardGrid extends StatelessWidget {
  final Board board;
  final double cellSize;

  const OptimizedBoardGrid({
    super.key,
    required this.board,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(board.size * cellSize, board.size * cellSize),
        painter: BoardPainter(
          board: board,
          cellSize: cellSize,
        ),
      ),
    );
  }
}

/// Custom painter for efficient board rendering
class BoardPainter extends CustomPainter {
  final Board board;
  final double cellSize;

  // Color palette for blocks
  static const List<Color> blockColors = [
    Color(0xFF00D9FF), // Cyan
    Color(0xFFFF6B6B), // Red
    Color(0xFF4ECDC4), // Teal
    Color(0xFFFFE66D), // Yellow
    Color(0xFF95E1A3), // Mint
    Color(0xFFFF9FF3), // Pink
  ];

  // Background and grid colors
  static const Color backgroundColor = Color(0xFF1a1a2e);
  static const Color gridLineColor = Color(0xFF2d2d44);
  static const Color emptyBlockColor = Color(0xFF16213e);

  BoardPainter({
    required this.board,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridSize = board.size;
    final margin = 1.0; // Margin between cells
    final cellInnerSize = cellSize - (margin * 2);
    final cornerRadius = 4.0;

    // Draw grid background (single rectangle)
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ),
      backgroundPaint,
    );

    // Draw empty cells first
    final emptyPaint = Paint()
      ..style = PaintingStyle.fill;

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final x = col * cellSize + margin;
        final y = row * cellSize + margin;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, cellInnerSize, cellInnerSize),
          Radius.circular(cornerRadius),
        );

        // Checkerboard pattern for empty cells
        final isAlternate = (row + col) % 2 == 0;
        emptyPaint.color = isAlternate
            ? emptyBlockColor
            : emptyBlockColor.withValues(alpha: 0.8);

        canvas.drawRRect(rect, emptyPaint);
      }
    }

    // Draw grid lines
    final linePaint = Paint()
      ..color = gridLineColor.withValues(alpha: 0.3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Vertical lines
    for (int i = 1; i < gridSize; i++) {
      final x = i * cellSize;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        linePaint,
      );
    }

    // Horizontal lines
    for (int i = 1; i < gridSize; i++) {
      final y = i * cellSize;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
    }

    // Draw filled cells
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final block = board.grid[row][col];
        
        if (block.type == BlockType.filled) {
          final x = col * cellSize + margin;
          final y = row * cellSize + margin;
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, cellInnerSize, cellInnerSize),
            Radius.circular(cornerRadius),
          );

          // Get block color or use default
          final color = block.color ?? blockColors[col % blockColors.length];

          // Draw block background with gradient effect
          final blockPaint = Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withValues(alpha: 0.8),
                color.withValues(alpha: 0.6),
              ],
            ).createShader(Rect.fromLTWH(x, y, cellInnerSize, cellInnerSize));

          canvas.drawRRect(rect, blockPaint);

          // Draw border
          final borderPaint = Paint()
            ..color = Colors.white.withValues(alpha: 0.3)
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke;

          canvas.drawRRect(rect, borderPaint);

          // Draw shine/highlight on top
          final shinePaint = Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [
                Colors.white.withValues(alpha: 0.25),
                Colors.transparent,
              ],
            ).createShader(Rect.fromLTWH(x, y, cellInnerSize, cellInnerSize / 2));

          final shineRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 2, y + 2, cellInnerSize - 4, cellInnerSize / 2 - 2),
            Radius.circular(cornerRadius - 1),
          );

          canvas.drawRRect(shineRect, shinePaint);

          // Draw shadow at bottom
          final shadowPaint = Paint()
            ..color = Colors.black.withValues(alpha: 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

          final shadowRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 1, y + cellInnerSize - 4, cellInnerSize - 2, 4),
            Radius.circular(cornerRadius),
          );

          canvas.drawRRect(shadowRect, shadowPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(BoardPainter oldDelegate) {
    return board != oldDelegate.board || cellSize != oldDelegate.cellSize;
  }
}

/// Optimized hover preview painter for ghost pieces
class HoverPreviewPainter extends CustomPainter {
  final Board board;
  final double cellSize;
  final List<List<int>>? hoverPositions;
  final Color hoverColor;

  HoverPreviewPainter({
    required this.board,
    required this.cellSize,
    this.hoverPositions,
    this.hoverColor = const Color(0xFF4ECDC4),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hoverPositions == null || hoverPositions!.isEmpty) return;

    final margin = 1.0;
    final cellInnerSize = cellSize - (margin * 2);
    final cornerRadius = 4.0;

    final hoverPaint = Paint()
      ..color = hoverColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = hoverColor.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final pos in hoverPositions!) {
      final row = pos[0];
      final col = pos[1];

      if (row >= 0 && row < board.size && col >= 0 && col < board.size) {
        final x = col * cellSize + margin;
        final y = row * cellSize + margin;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, cellInnerSize, cellInnerSize),
          Radius.circular(cornerRadius),
        );

        canvas.drawRRect(rect, hoverPaint);
        canvas.drawRRect(rect, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(HoverPreviewPainter oldDelegate) {
    return hoverPositions != oldDelegate.hoverPositions ||
        hoverColor != oldDelegate.hoverColor;
  }
}
