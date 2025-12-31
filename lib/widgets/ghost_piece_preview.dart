import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/piece.dart';
import '../models/board.dart';
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
    // BUG FIX #1 & #2: Early validation with proper null checks and bounds checking
    if (piece == null) return const SizedBox.shrink();

    // Explicit assertion with local variable - prevents null safety issues
    final pieceData = piece!;

    // BUG FIX #3: Use select to rebuild when board changes (e.g., mode switch)
    // This ensures ghost preview always uses current board size for positioning
    final board = context.select<GameCubit, Board?>((cubit) {
      final state = cubit.state;
      return state is GameInProgress ? state.board : null;
    });

    if (board == null) return const SizedBox.shrink();

    // BUG FIX #1: Comprehensive bounds checking including far edges
    // Check if piece fits within board boundaries
    if (gridX < 0 ||
        gridY < 0 ||
        gridX + pieceData.width > board.size ||
        gridY + pieceData.height > board.size) {
      return const SizedBox.shrink();
    }

    // CRITICAL FIX: Calculate cell size to match actual grid layout
    // The Stack (gridKey) is inside Padding(4.0) which is inside Container with border(2.0)
    // So available space = boardSize - (border * 2) - (padding * 2) = boardSize - 12
    // Use getEffectiveSize to get the correct Stack size, then divide by grid size
    // ✅ VERIFIED: Uses same calculation as draggable_piece_widget.dart
    // Both use: effectiveSize = AppConfig.getEffectiveSize(context)
    // Both use: cellSize = effectiveSize / board.size
    // This ensures ghost preview positioning matches actual placement - NOT a bug
    // This matches exactly how the Expanded widgets divide the space
    final effectiveSize = AppConfig.getEffectiveSize(context);
    final cellSize = effectiveSize /
        board.size; // Exact cell size (matches Expanded division)
    const blockMargin =
        1.0; // Margin on each side of blocks (matches _BlockCell)

    // BUG FIX #6: Defensive programming - ensure coordinates are non-negative
    // (Should be guaranteed by early return, but adds safety)
    final safeGridX = gridX.clamp(0, board.size - 1);
    final safeGridY = gridY.clamp(0, board.size - 1);

    // Calculate position on the board (relative to the Stack inside Padding)
    // The container should start at the cell boundary, blocks inside will have margins
    final offsetX = safeGridX * cellSize;
    final offsetY = safeGridY * cellSize;

    // Block size for individual blocks (cellSize - 2*margin)
    final blockSize = cellSize - (blockMargin * 2);

    // CRITICAL FIX: Positioned must be a direct child of Stack
    // RepaintBoundary is moved inside Positioned to isolate repaints
    return Positioned(
      left: offsetX,
      top: offsetY,
      child: RepaintBoundary(
        // Isolate ghost preview repaints for better performance during drag
        child: SizedBox(
          width: pieceData.width * cellSize, // Total width
          height: pieceData.height * cellSize, // Total height
          child: Stack(
            children: [
              // Draw the piece shape
              for (int row = 0; row < pieceData.height; row++)
                for (int col = 0; col < pieceData.width; col++)
                  if (pieceData.shape[row][col])
                    Positioned(
                      left: col * cellSize + blockMargin,
                      top: row * cellSize + blockMargin,
                      child: Container(
                        width:
                            blockSize, // No extra margin needed - already accounted
                        height:
                            blockSize, // No extra margin needed - already accounted
                        // REMOVED: margin: EdgeInsets.all(1) - this was causing double margin
                        decoration: BoxDecoration(
                          // Improved visibility: higher opacity and better contrast
                          color: isValid
                              ? pieceData.color
                                  .withValues(alpha: 0.6) // Increased from 0.4
                              : Colors.red.withValues(
                                  alpha:
                                      0.4), // Changed from grey, increased opacity
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isValid
                                ? pieceData.color.withValues(
                                    alpha: 1.0) // More visible border
                                : Colors.red.withValues(
                                    alpha:
                                        0.9), // Strong red border for invalid
                            width: 2.5, // Slightly thicker for visibility
                          ),
                          boxShadow: [
                            // Always show shadow for better visibility
                            BoxShadow(
                              color: isValid
                                  ? pieceData.color.withValues(alpha: 0.5)
                                  : Colors.red.withValues(alpha: 0.4),
                              blurRadius: isValid ? 12 : 8,
                              spreadRadius: isValid ? 2 : 1,
                            ),
                            // Additional glow for valid placements
                            if (isValid)
                              BoxShadow(
                                color: pieceData.color.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                          ],
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
