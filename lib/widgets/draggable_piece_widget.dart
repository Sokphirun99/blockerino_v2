import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';
import '../models/piece.dart';
import '../cubits/game/game_cubit.dart';
import '../cubits/game/game_state.dart';
import '../cubits/settings/settings_cubit.dart';
import '../config/app_config.dart';

// Safe vibration helper for web compatibility
void _safeVibrate({int duration = 50, int amplitude = 128}) {
  if (kIsWeb) return; // Vibration not supported on web
  try {
    Vibration.vibrate(duration: duration, amplitude: amplitude);
  } catch (e) {
    // Silently ignore vibration errors
  }
}

class DraggablePieceWidget extends StatefulWidget {
  final Piece piece;

  const DraggablePieceWidget({super.key, required this.piece});

  @override
  State<DraggablePieceWidget> createState() => _DraggablePieceWidgetState();
}

class _DraggablePieceWidgetState extends State<DraggablePieceWidget> {
  @override
  Widget build(BuildContext context) {
    // Get the actual board block size for 1:1 feedback scale
    // Default to 8x8 if board is null (safe fallback)
    final gameCubit = context.read<GameCubit>();
    final currentState = gameCubit.state;
    final boardSize = currentState is GameInProgress ? currentState.board.size : 8;
    final actualBlockSize = AppConfig.getBlockSize(context, boardSize);
    
    // Use actual size for feedback so it matches the board slots exactly
    final feedbackBlockSize = actualBlockSize;
    
    return Draggable<Piece>(
      data: widget.piece,
      maxSimultaneousDrags: 1,
      hitTestBehavior: HitTestBehavior.opaque, // Makes entire area tappable
      dragAnchorStrategy: (draggable, context, position) {
        // This makes the piece center on the finger
        // For even-sized pieces, we need to offset by 0.5 block size to align with grid
        final widthOffset = (widget.piece.width % 2 == 0) ? 0.5 : 0.0;
        final heightOffset = (widget.piece.height % 2 == 0) ? 0.5 : 0.0;
        
        return Offset(
          (widget.piece.width / 2 + widthOffset) * feedbackBlockSize, 
          (widget.piece.height / 2 + heightOffset) * feedbackBlockSize
        );
      },
      feedback: Material(
        color: Colors.transparent,
        elevation: 8,
        child: _PieceVisual(
          piece: widget.piece,
          blockSize: feedbackBlockSize,
          opacity: 0.9,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: _PieceVisual(
              piece: widget.piece,
              blockSize: 26.0, // Larger blocks like Block Blast
              opacity: 0.3,
            ),
          ),
        ),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: _PieceVisual(
            piece: widget.piece,
            blockSize: 26.0, // Larger blocks like Block Blast
            opacity: 1.0,
          ),
        ),
      ),
      onDragStarted: () {
        final settings = context.read<SettingsCubit>().state;
        if (settings.hapticsEnabled) {
          _safeVibrate(duration: 20);
        }
      },
      onDragEnd: (details) {
        if (!details.wasAccepted) {
          final settings = context.read<SettingsCubit>().state;
          if (settings.hapticsEnabled) {
            _safeVibrate(duration: 50);
          }
        }
      },
    );
  }
}

class _PieceVisual extends StatelessWidget {
  final Piece piece;
  final double blockSize;
  final double opacity;

  const _PieceVisual({
    required this.piece,
    required this.blockSize,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(piece.height, (row) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(piece.width, (col) {
            final isBlock = piece.shape[row][col];
            return Container(
              width: blockSize,
              height: blockSize,
              margin: EdgeInsets.zero,
              decoration: isBlock
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: _lightenColor(piece.color, 0.3).withValues(alpha: opacity),
                        width: 1,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _lightenColor(piece.color, 0.2).withValues(alpha: opacity),
                          piece.color.withValues(alpha: opacity),
                          _darkenColor(piece.color, 0.2).withValues(alpha: opacity),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: piece.color.withValues(alpha: 0.4 * opacity),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 2,
                          offset: const Offset(1, 2),
                        ),
                      ],
                    )
                  : null,
            );
          }),
        );
      }),
    );
  }

  Color _lightenColor(Color color, double amount) {
    return Color.fromARGB(
      color.a.toInt(),
      (color.r * 255 + (255 - color.r * 255) * amount).round().clamp(0, 255),
      (color.g * 255 + (255 - color.g * 255) * amount).round().clamp(0, 255),
      (color.b * 255 + (255 - color.b * 255) * amount).round().clamp(0, 255),
    );
  }

  Color _darkenColor(Color color, double amount) {
    return Color.fromARGB(
      color.a.toInt(),
      (color.r * 255 * (1 - amount)).round().clamp(0, 255),
      (color.g * 255 * (1 - amount)).round().clamp(0, 255),
      (color.b * 255 * (1 - amount)).round().clamp(0, 255),
    );
  }
}

// Drag target overlay for the board
class BoardDragTarget extends StatefulWidget {
  final Widget child;

  const BoardDragTarget({super.key, required this.child});

  @override
  State<BoardDragTarget> createState() => _BoardDragTargetState();
}

class _BoardDragTargetState extends State<BoardDragTarget> {
  int _lastGridX = -1;
  int _lastGridY = -1;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Piece>(
      onWillAcceptWithDetails: (details) => true,
      // Use the last known grid position to drop at shadow location
      onAcceptWithDetails: (details) {
        final gameCubit = context.read<GameCubit>();
        final settings = context.read<SettingsCubit>().state;
        
        // Drop at the last shadow position (where user sees it will land)
        final gridX = _lastGridX;
        final gridY = _lastGridY;
        
        if (gridX == -1 || gridY == -1) return; // No valid position
        
        final piece = details.data;
        final success = gameCubit.placePiece(piece, gridX, gridY);
        
        if (success && settings.hapticsEnabled) {
          _safeVibrate(duration: 30);
        } else if (!success && settings.hapticsEnabled) {
          _safeVibrate(duration: 100, amplitude: 255);
        }
        
        // Reset state
        _lastGridX = -1;
        _lastGridY = -1;
      },
      onMove: (details) {
        // Show hover preview while dragging - update immediately for responsiveness
        final gameCubit = context.read<GameCubit>();
        final currentState = gameCubit.state;
        if (currentState is! GameInProgress) return;
        
        final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) return;
        
        final localPosition = renderBox.globalToLocal(details.offset);
        final board = currentState.board;
        final piece = details.data;
        final blockSize = AppConfig.getBlockSize(context, board.size);
        
        final adjustedX = localPosition.dx - AppConfig.boardContainerPadding - AppConfig.boardBorderWidth;
        final adjustedY = localPosition.dy - AppConfig.boardContainerPadding - AppConfig.boardBorderWidth;
        
        // The finger/anchor is at the CENTER of the piece
        final pieceWidthInPixels = piece.width * blockSize;
        final pieceHeightInPixels = piece.height * blockSize;
        
        final topLeftX = adjustedX - (pieceWidthInPixels / 2);
        final topLeftY = adjustedY - (pieceHeightInPixels / 2);
        
        // Convert to grid coordinates
        final gridX = (topLeftX / blockSize).round();
        final gridY = (topLeftY / blockSize).round();
        
        // Only update if position changed (prevents unnecessary rebuilds)
        if (gridX != _lastGridX || gridY != _lastGridY) {
          gameCubit.showHoverPreview(piece, gridX, gridY);
          _lastGridX = gridX;
          _lastGridY = gridY;

                    // Only save position if it's potentially valid (non-negative)
          // This keeps the last valid position for dropping
          if (gridX >= 0 && gridY >= 0) {
            _lastGridX = gridX;
            _lastGridY = gridY;
          }

        }
      },
      onLeave: (data) {
        // Clear hover preview when dragging away
        final gameCubit = context.read<GameCubit>();
        gameCubit.clearHoverBlocks();
        _lastGridX = -1;
        _lastGridY = -1;
      },
      builder: (context, candidateData, rejectedData) {
        return widget.child;
      },
    );
  }
}
