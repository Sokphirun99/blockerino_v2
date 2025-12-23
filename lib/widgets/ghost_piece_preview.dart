import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/piece.dart';
import '../config/app_config.dart';
import '../cubits/game/game_cubit.dart';
import '../cubits/game/game_state.dart';

/// A semi-transparent ghost preview of a piece that shows where it will be placed
/// This makes it instantly obvious if a piece fits
class GhostPiecePreview extends StatelessWidget {
  final Piece? piece;
  final int gridX;
  final int gridY;
  final bool isValid;

  const GhostPiecePreview({
    super.key,
    required this.piece,
    required this.gridX,
    required this.gridY,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    if (piece == null || gridX < 0 || gridY < 0) {
      return const SizedBox.shrink();
    }

    final gameCubit = context.read<GameCubit>();
    final currentState = gameCubit.state;
    if (currentState is! GameInProgress) return const SizedBox.shrink();

    final board = currentState.board;
    final blockSize = AppConfig.getBlockSize(context, board.size);

    // The GhostPiecePreview is already inside the Stack which is inside Padding(4.0)
    // So we don't need to add padding. Blocks are positioned using Expanded widgets
    // Each block has margin: EdgeInsets.all(1), so we need to account for that
    const blockMargin = 1.0; // Margin on each side of blocks

    // Calculate position on the board (relative to the Stack)
    // Blocks are positioned at (col * blockSize) with 1px margin on each side
    final offsetX = (gridX * blockSize) + blockMargin;
    final offsetY = (gridY * blockSize) + blockMargin;

    // Store piece in local variable to avoid repeated null checks
    final pieceData = piece!;

    return Positioned(
      left: offsetX,
      top: offsetY,
      child: SizedBox(
        width: pieceData.width * blockSize,
        height: pieceData.height * blockSize,
        child: Stack(
          children: [
            // Draw the piece shape
            for (int row = 0; row < pieceData.height; row++)
              for (int col = 0; col < pieceData.width; col++)
                if (pieceData.shape[row][col])
                  Positioned(
                    left: col * blockSize,
                    top: row * blockSize,
                    child: Container(
                      width: blockSize - 2, // Account for margin on both sides
                      height: blockSize - 2, // Account for margin on both sides
                      margin:
                          const EdgeInsets.all(1), // Match _BlockCell margin
                      decoration: BoxDecoration(
                        // Use single opacity level to preserve color accuracy
                        color: isValid
                            ? pieceData.color.withValues(alpha: 0.4)
                            : Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isValid
                              ? pieceData.color.withValues(alpha: 0.7)
                              : Colors.red.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: isValid
                            ? [
                                BoxShadow(
                                  color: pieceData.color.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
