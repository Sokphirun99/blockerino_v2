import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/piece.dart';
import '../config/app_config.dart';
import '../cubits/game/game_cubit.dart';
import '../cubits/game/game_state.dart';

// #region agent log
void _ghostDebugLog(String message, Map<String, dynamic> data) {
  debugPrint('[DEBUG:GHOST] $message: $data');
}
// #endregion

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
    // #region agent log
    _ghostDebugLog('build called', {
      'piece': piece?.id,
      'gridX': gridX,
      'gridY': gridY,
      'isValid': isValid,
    });
    // #endregion

    if (piece == null || gridX < 0 || gridY < 0) {
      // #region agent log
      _ghostDebugLog('early return - invalid params', {
        'pieceNull': piece == null,
        'gridX': gridX,
        'gridY': gridY,
      });
      // #endregion
      return const SizedBox.shrink();
    }

    final gameCubit = context.read<GameCubit>();
    final currentState = gameCubit.state;
    if (currentState is! GameInProgress) return const SizedBox.shrink();

    final board = currentState.board;

    // CRITICAL FIX: Calculate cell size to match actual grid layout
    // The grid is inside Padding(4.0), so available space is boardSize - 8
    // Each cell uses Expanded, so cell size = (boardSize - 8) / gridSize
    // This matches the actual grid cell size, not getBlockSize which accounts for borders
    final boardSize = AppConfig.getSize(context);
    final availableSize = boardSize -
        (AppConfig.boardContainerPadding * 2); // Subtract padding on both sides
    final cellSize =
        availableSize / board.size; // Size of each grid cell (including margin)
    const blockMargin =
        1.0; // Margin on each side of blocks (matches _BlockCell)

    // Calculate position on the board (relative to the Stack inside Padding)
    // The container should start at the cell boundary, blocks inside will have margins
    final offsetX = gridX * cellSize;
    final offsetY = gridY * cellSize;

    // Block size for individual blocks (cellSize - 2*margin)
    final blockSize = cellSize - (blockMargin * 2);

    // #region agent log
    _ghostDebugLog('positioning', {
      'boardSize': boardSize,
      'availableSize': availableSize,
      'cellSize': cellSize,
      'blockSize': blockSize,
      'offsetX': offsetX,
      'offsetY': offsetY,
      'gridX': gridX,
      'gridY': gridY,
      'gridSize': board.size,
    });
    // #endregion

    // Store piece in local variable to avoid repeated null checks
    final pieceData = piece!;

    return Positioned(
      left: offsetX,
      top: offsetY,
      child: SizedBox(
        width: pieceData.width *
            cellSize, // Use cellSize for total width (includes margins)
        height: pieceData.height *
            cellSize, // Use cellSize for total height (includes margins)
        child: Stack(
          children: [
            // Draw the piece shape
            for (int row = 0; row < pieceData.height; row++)
              for (int col = 0; col < pieceData.width; col++)
                if (pieceData.shape[row][col])
                  Positioned(
                    left: col * cellSize +
                        blockMargin, // Position within cell, accounting for margin
                    top: row * cellSize +
                        blockMargin, // Position within cell, accounting for margin
                    child: Container(
                      width:
                          blockSize, // Block size already accounts for margins
                      height:
                          blockSize, // Block size already accounts for margins
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
