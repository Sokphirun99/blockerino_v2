import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../models/piece.dart';
import '../providers/game_state_provider.dart';
import '../providers/settings_provider.dart';
import '../config/board_config.dart';

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
    // Calculate feedback offset to center piece on finger
    const feedbackBlockSize = 30.0;
    final pieceWidth = widget.piece.width * feedbackBlockSize;
    final pieceHeight = widget.piece.height * feedbackBlockSize;
    
    return Draggable<Piece>(
      data: widget.piece,
      maxSimultaneousDrags: 1,
      affinity: Axis.vertical, // Helps distinguish from scroll gestures
      feedback: Material(
        color: Colors.transparent,
        elevation: 8,
        child: Transform.translate(
          offset: Offset(-pieceWidth / 2, -pieceHeight - 30), // Center and lift above finger
          child: Transform.scale(
            scale: 1.3,
            child: _PieceVisual(
              piece: widget.piece,
              blockSize: feedbackBlockSize,
              opacity: 0.95,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _PieceVisual(
          piece: widget.piece,
          blockSize: 24,
          opacity: 0.3,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: _PieceVisual(
          piece: widget.piece,
          blockSize: 24,
          opacity: 1.0,
        ),
      ),
      onDragStarted: () {
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        if (settings.hapticsEnabled) {
          _safeVibrate(duration: 20);
        }
      },
      onDragEnd: (details) {
        if (!details.wasAccepted) {
          final settings = Provider.of<SettingsProvider>(context, listen: false);
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

// Drag target overlay for the board
class BoardDragTarget extends StatelessWidget {
  final Widget child;

  const BoardDragTarget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DragTarget<Piece>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final gameState = Provider.of<GameStateProvider>(context, listen: false);
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        
        // Calculate grid position from drop location
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.offset);
        
        // Convert to grid coordinates with proper padding consideration
        final board = gameState.board!;
        final piece = details.data;
        final blockSize = BoardConfig.getBlockSize(context, board.size);
        
        // Adjust for container padding and border
        final adjustedX = localPosition.dx - BoardConfig.containerPadding - BoardConfig.borderWidth;
        final adjustedY = localPosition.dy - BoardConfig.containerPadding - BoardConfig.borderWidth;
        
        // Calculate grid position - center the piece on the cursor
        final gridX = (adjustedX / blockSize).floor() - (piece.width ~/ 2);
        final gridY = (adjustedY / blockSize).floor() - (piece.height ~/ 2);
        
        final success = gameState.placePiece(piece, gridX, gridY);
        
        if (success && settings.hapticsEnabled) {
          _safeVibrate(duration: 30);
        } else if (!success && settings.hapticsEnabled) {
          _safeVibrate(duration: 100, amplitude: 255);
        }
      },
      onMove: (details) {
        // Show hover preview while dragging
        final gameState = Provider.of<GameStateProvider>(context, listen: false);
        final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) return;
        
        final localPosition = renderBox.globalToLocal(details.offset);
        final board = gameState.board!;
        final piece = details.data;
        final blockSize = BoardConfig.getBlockSize(context, board.size);
        
        final adjustedX = localPosition.dx - BoardConfig.containerPadding - BoardConfig.borderWidth;
        final adjustedY = localPosition.dy - BoardConfig.containerPadding - BoardConfig.borderWidth;
        
        // Center the piece on the cursor
        final gridX = (adjustedX / blockSize).floor() - (piece.width ~/ 2);
        final gridY = (adjustedY / blockSize).floor() - (piece.height ~/ 2);
        
        gameState.showHoverPreview(piece, gridX, gridY);
      },
      onLeave: (data) {
        // Clear hover preview when dragging away
        final gameState = Provider.of<GameStateProvider>(context, listen: false);
        gameState.clearHoverBlocks();
      },
      builder: (context, candidateData, rejectedData) {
        return child;
      },
    );
  }
}
