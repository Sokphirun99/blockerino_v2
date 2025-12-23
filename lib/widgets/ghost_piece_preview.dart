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
    const padding =
        AppConfig.boardContainerPadding + AppConfig.boardBorderWidth;

    // Calculate position on the board
    final offsetX = padding + (gridX * blockSize);
    final offsetY = padding + (gridY * blockSize);

    // Store piece in local variable to avoid repeated null checks
    final pieceData = piece!;

    return Positioned(
      left: offsetX,
      top: offsetY,
      child: Opacity(
        opacity: isValid ? 0.4 : 0.2, // More transparent if invalid
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
                        width: blockSize - 2,
                        height: blockSize - 2,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: isValid
                              ? pieceData.color.withValues(alpha: 0.5)
                              : Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isValid
                                ? pieceData.color.withValues(alpha: 0.8)
                                : Colors.red.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: isValid
                              ? [
                                  BoxShadow(
                                    color:
                                        pieceData.color.withValues(alpha: 0.3),
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
      ),
    );
  }
}
