import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../models/piece.dart';
import '../providers/game_state_provider.dart';
import '../providers/settings_provider.dart';

class DraggablePieceWidget extends StatefulWidget {
  final Piece piece;

  const DraggablePieceWidget({super.key, required this.piece});

  @override
  State<DraggablePieceWidget> createState() => _DraggablePieceWidgetState();
}

class _DraggablePieceWidgetState extends State<DraggablePieceWidget> {
  @override
  Widget build(BuildContext context) {
    return Draggable<Piece>(
      data: widget.piece,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.3,
          child: _PieceVisual(
            piece: widget.piece,
            blockSize: 32,
            opacity: 0.95,
          ),
        ),
      ),
      feedbackOffset: Offset(-widget.piece.width * 16, -widget.piece.height * 16),
      childWhenDragging: Opacity(
        opacity: 0.2,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: _PieceVisual(
            piece: widget.piece,
            blockSize: 28,
            opacity: 0.3,
          ),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: _PieceVisual(
          piece: widget.piece,
          blockSize: 28,
          opacity: 1.0,
        ),
      ),
      onDragStarted: () {
        // Optional: Add haptic feedback on drag start
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        if (settings.hapticsEnabled) {
          Vibration.vibrate(duration: 10);
        }
      },
      onDragEnd: (details) {
        if (!details.wasAccepted) {
          // Optional: Add haptic feedback on failed drop
          final settings = Provider.of<SettingsProvider>(context, listen: false);
          if (settings.hapticsEnabled) {
            Vibration.vibrate(duration: 50);
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
            margin: const EdgeInsets.all(0.5),
            decoration: isBlock
                ? BoxDecoration(
                    color: piece.color.withValues(alpha: opacity),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: piece.color.withValues(alpha: 0.5),
                        blurRadius: 3,
                        spreadRadius: 0.5,
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
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final maxWidth = screenWidth * 0.85;
        final maxHeight = screenHeight * 0.5;
        final maxSize = maxWidth < maxHeight ? maxWidth : maxHeight;
        const containerPadding = 4.0; // Padding from BoardGridWidget
        final effectiveSize = maxSize - (containerPadding * 2);
        final blockSize = effectiveSize / board.size;
        
        // Adjust for container padding
        final adjustedX = localPosition.dx - containerPadding;
        final adjustedY = localPosition.dy - containerPadding;
        
        // Calculate grid position - center the piece on the cursor
        final gridX = (adjustedX / blockSize).floor() - (piece.width ~/ 2);
        final gridY = (adjustedY / blockSize).floor() - (piece.height ~/ 2);
        
        final success = gameState.placePiece(piece, gridX, gridY);
        
        if (success && settings.hapticsEnabled) {
          Vibration.vibrate(duration: 30);
        } else if (!success && settings.hapticsEnabled) {
          Vibration.vibrate(duration: 100, amplitude: 255);
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
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final maxWidth = screenWidth * 0.85;
        final maxHeight = screenHeight * 0.5;
        final maxSize = maxWidth < maxHeight ? maxWidth : maxHeight;
        const containerPadding = 4.0;
        final effectiveSize = maxSize - (containerPadding * 2);
        final blockSize = effectiveSize / board.size;
        
        final adjustedX = localPosition.dx - containerPadding;
        final adjustedY = localPosition.dy - containerPadding;
        
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
