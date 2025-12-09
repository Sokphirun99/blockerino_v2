import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import '../models/board.dart';
import '../config/app_config.dart';

class BoardGridWidget extends StatelessWidget {
  const BoardGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameStateProvider>(
      builder: (context, gameState, child) {
        final board = gameState.board;
        if (board == null) {
          return const Center(
            child: Text(
              'Loading board...',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        // Use shared AppConfig for consistent sizing
        final boardSize = AppConfig.getSize(context);

        return Container(
          width: boardSize,
          height: boardSize,
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e), // Dark blue-purple background
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.purple.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: CustomPaint(
              painter: GridLinesPainter(boardSize: board.size),
              child: Column(
                children: List.generate(board.size, (row) {
                  return Expanded(
                    child: Row(
                      children: List.generate(board.size, (col) {
                        final block = board.grid[row][col];
                        return Expanded(
                          child: _BlockCell(block: block),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for grid lines (like original)
class GridLinesPainter extends CustomPainter {
  final int boardSize;

  GridLinesPainter({required this.boardSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    final cellWidth = size.width / boardSize;
    final cellHeight = size.height / boardSize;

    // Draw vertical lines
    for (int i = 0; i <= boardSize; i++) {
      final x = i * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (int i = 0; i <= boardSize; i++) {
      final y = i * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BlockCell extends StatelessWidget {
  final BoardBlock block;

  const _BlockCell({
    required this.block,
  });

  @override
  Widget build(BuildContext context) {
    Color cellColor;
    double opacity;
    bool showGlow = false;
    bool isBreaking = false;

    switch (block.type) {
      case BlockType.filled:
        cellColor = block.color ?? Colors.blue;
        opacity = 1.0;
        break;
      case BlockType.hover:
        cellColor = block.color ?? Colors.blue;
        opacity = 0.5;
        break;
      case BlockType.hoverBreakFilled:
        // Show filled blocks that will be cleared with a glow effect
        cellColor = block.hoverBreakColor ?? block.color ?? Colors.red;
        opacity = 1.0;
        showGlow = true;
        isBreaking = true;
        break;
      case BlockType.hoverBreakEmpty:
        // Show empty spaces in lines that will be cleared
        cellColor = block.hoverBreakColor ?? Colors.red;
        opacity = 0.3;
        isBreaking = true;
        break;
      case BlockType.hoverBreak:
        cellColor = Colors.red;
        opacity = 0.7;
        isBreaking = true;
        break;
      case BlockType.empty:
        cellColor = const Color(0xFF2a2a4a); // Subtle purple-gray
        opacity = 0.3;
    }

    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: cellColor.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(3),
        border: block.type == BlockType.empty
            ? null // No border for empty - cleaner look
            : block.type == BlockType.filled
                ? Border.all(
                    color: _lightenColor(cellColor, 0.2),
                    width: 1,
                  )
                : isBreaking
                    ? Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 1.5,
                      )
                    : Border.all(
                        color: cellColor.withValues(alpha: 0.5),
                        width: 1,
                      ),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: cellColor.withValues(alpha: 0.8),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : block.type == BlockType.filled
                ? [
                    BoxShadow(
                      color: cellColor.withValues(alpha: 0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
        // Add 3D effect for filled blocks
        gradient: block.type == BlockType.filled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _lightenColor(cellColor, 0.15),
                  cellColor,
                  _darkenColor(cellColor, 0.15),
                ],
                stops: const [0.0, 0.5, 1.0],
              )
            : null,
      ),
    );
  }

  Color _lightenColor(Color color, double amount) {
    return Color.fromARGB(
      color.alpha,
      (color.red + (255 - color.red) * amount).round().clamp(0, 255),
      (color.green + (255 - color.green) * amount).round().clamp(0, 255),
      (color.blue + (255 - color.blue) * amount).round().clamp(0, 255),
    );
  }

  Color _darkenColor(Color color, double amount) {
    return Color.fromARGB(
      color.alpha,
      (color.red * (1 - amount)).round().clamp(0, 255),
      (color.green * (1 - amount)).round().clamp(0, 255),
      (color.blue * (1 - amount)).round().clamp(0, 255),
    );
  }
}
