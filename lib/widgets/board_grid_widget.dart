import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import '../models/board.dart';

class BoardGridWidget extends StatelessWidget {
  const BoardGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameStateProvider>(
      builder: (context, gameState, child) {
        final board = gameState.board;
        if (board == null) return const SizedBox.shrink();

        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        // Use smaller of width or available height, with padding considerations
        final maxWidth = screenWidth * 0.85;
        final maxHeight = screenHeight * 0.5; // Max 50% of screen height
        final maxSize = maxWidth < maxHeight ? maxWidth : maxHeight;

        return Container(
          width: maxSize,
          height: maxSize,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
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
        );
      },
    );
  }
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

    switch (block.type) {
      case BlockType.filled:
        cellColor = block.color ?? Colors.blue;
        opacity = 1.0;
        break;
      case BlockType.hover:
        cellColor = block.color ?? Colors.blue;
        opacity = 0.4;
        break;
      case BlockType.hoverBreakFilled:
        // Show filled blocks that will be cleared with a glow effect
        cellColor = block.hoverBreakColor ?? block.color ?? Colors.red;
        opacity = 0.9;
        break;
      case BlockType.hoverBreakEmpty:
        // Show empty spaces in lines that will be cleared
        cellColor = block.hoverBreakColor ?? Colors.red;
        opacity = 0.5;
        break;
      case BlockType.hoverBreak:
        cellColor = Colors.red;
        opacity = 0.7;
        break;
      case BlockType.empty:
        cellColor = Colors.grey[800]!;
        opacity = 0.3;
    }

    return Container(
      margin: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        color: cellColor.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(2),
        border: block.type == BlockType.empty
            ? Border.all(color: Colors.grey[700]!, width: 0.5)
            : block.type == BlockType.hoverBreakFilled || 
              block.type == BlockType.hoverBreakEmpty
              ? Border.all(color: cellColor.withValues(alpha: 1.0), width: 1.5)
              : null,
        boxShadow: block.type == BlockType.hoverBreakFilled || 
                  block.type == BlockType.hoverBreakEmpty
            ? [
                BoxShadow(
                  color: cellColor.withValues(alpha: 0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}
