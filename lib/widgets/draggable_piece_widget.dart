import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/piece.dart';
import '../cubits/game/game_cubit.dart';
import '../cubits/game/game_state.dart';
import '../cubits/settings/settings_cubit.dart';
import '../config/app_config.dart';

// #region agent log
int _dragLogCounter = 0;
void _dragDebugLog(
    String location, String hypothesisId, Map<String, dynamic> data) {
  _dragLogCounter++;
  debugPrint(
      '[DEBUG:$hypothesisId:#$_dragLogCounter] DragTarget.$location: $data');
}
// #endregion

// Intelligent haptics helper
Future<void> _intelligentHaptic(HapticFeedbackType type) async {
  if (kIsWeb) return; // Haptics not supported on web
  try {
    switch (type) {
      case HapticFeedbackType.pickup:
        await HapticFeedback.selectionClick(); // Very light tick
        break;
      case HapticFeedbackType.hoverValid:
        await HapticFeedback.lightImpact(); // Light tick for valid spot
        break;
      case HapticFeedbackType.drop:
        await HapticFeedback.mediumImpact(); // Medium thud
        break;
      case HapticFeedbackType.lineClear:
        await HapticFeedback.heavyImpact(); // Heavy vibration
        break;
      case HapticFeedbackType.error:
        await HapticFeedback.vibrate(); // Error vibration
        break;
    }
  } catch (e) {
    // Silently ignore haptic errors
  }
}

enum HapticFeedbackType {
  pickup,
  hoverValid,
  drop,
  lineClear,
  error,
}

/// Fat Finger fix: Calculate responsive Y offset to make piece float above finger
/// Uses ScreenUtil for consistent scaling across all devices and aspect ratios
/// This ensures the piece is always visible above the finger on phones, tablets, and foldables
/// Returns a positive value representing how many pixels the piece should float above the finger
double _getDragYOffset(BuildContext context) {
  // Use ScreenUtil for responsive sizing - 50 logical pixels that scale correctly
  // ScreenUtil handles device pixel ratio and aspect ratio automatically
  // Increased from 40 to 50 for better visibility (like Block Blast, Candy Crush)
  return 50.0.sp; // Scaled pixels that adapt to screen size
}

class DraggablePieceWidget extends StatefulWidget {
  final Piece piece;

  const DraggablePieceWidget({super.key, required this.piece});

  @override
  State<DraggablePieceWidget> createState() => _DraggablePieceWidgetState();
}

class _DraggablePieceWidgetState extends State<DraggablePieceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the actual board block size for 1:1 feedback scale
    // Default to 8x8 if board is null (safe fallback)
    final gameCubit = context.read<GameCubit>();
    final currentState = gameCubit.state;
    final boardSize =
        currentState is GameInProgress ? currentState.board.size : 8;
    final actualBlockSize = AppConfig.getBlockSize(context, boardSize);

    // Use actual size for feedback so it matches the board slots exactly
    final feedbackBlockSize = actualBlockSize;

    return Draggable<Piece>(
      data: widget.piece,
      maxSimultaneousDrags: 1,
      hitTestBehavior: HitTestBehavior.opaque, // Makes entire area tappable
      dragAnchorStrategy: (draggable, context, position) {
        // Fat Finger fix: Make piece float above finger for better visibility
        // The anchor point is set to piece center, but shifted upward so piece appears above finger
        // For even-sized pieces, we need to offset by 0.5 block size to align with grid
        final widthOffset = (widget.piece.width % 2 == 0) ? 0.5 : 0.0;
        final heightOffset = (widget.piece.height % 2 == 0) ? 0.5 : 0.0;
        final dragYOffset =
            _getDragYOffset(context); // Positive value (e.g., 50.0.sp)

        // Return offset from piece top-left to anchor point (finger position)
        // X: piece center (horizontal alignment)
        // Y: piece center minus Y offset (makes piece appear above finger)
        return Offset(
            (widget.piece.width / 2 + widthOffset) * feedbackBlockSize,
            (widget.piece.height / 2 + heightOffset) * feedbackBlockSize -
                dragYOffset);
      },
      feedback: Transform.scale(
        scale: 1.15, // Scale up by 15% when dragging - better visibility
        child: Material(
          color: Colors.transparent,
          elevation: 12, // Increased elevation for better shadow/visibility
          shadowColor: Colors.black.withValues(alpha: 0.5), // Stronger shadow
          child: Container(
            // Add subtle border for better contrast against any background
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: _PieceVisual(
              piece: widget.piece,
              blockSize: feedbackBlockSize,
              opacity: 1.0, // Full opacity for maximum visibility
            ),
          ),
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
      // Animate scale when picking up
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isDragging ? 1.0 : _scaleAnimation.value,
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
          );
        },
      ),
      onDragStarted: () {
        setState(() => _isDragging = true);
        _scaleController.forward();
        final settings = context.read<SettingsCubit>().state;
        if (settings.hapticsEnabled) {
          _intelligentHaptic(HapticFeedbackType.pickup);
        }
      },
      onDragEnd: (details) {
        setState(() => _isDragging = false);
        // Bounce effect: scale down then back up
        _scaleController.reverse().then((_) {
          if (mounted) {
            _scaleController.value = 0;
          }
        });

        final settings = context.read<SettingsCubit>().state;
        if (settings.hapticsEnabled) {
          if (details.wasAccepted) {
            _intelligentHaptic(HapticFeedbackType.drop);
          } else {
            _intelligentHaptic(HapticFeedbackType.error);
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
            // Check if block exists at this position
            final isBlock = piece.shape[row][col];

            return Container(
              width: blockSize,
              height: blockSize,
              margin: EdgeInsets.zero,
              decoration: isBlock
                  ? BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(4), // Slightly rounder
                      gradient: LinearGradient(
                        // <--- NEW: Gradient Effect
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          piece.color.withValues(alpha: opacity), // Base color
                          piece.color.withValues(
                              alpha: opacity * 0.8), // Slightly darker
                          piece.color
                              .withValues(alpha: opacity * 0.6), // Shadow
                        ],
                      ),
                      boxShadow: [
                        // <--- NEW: Neon Glow
                        BoxShadow(
                          color: piece.color.withValues(alpha: 0.4 * opacity),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        // <--- NEW: Highlight Edge
                        color: Colors.white.withValues(alpha: 0.3 * opacity),
                        width: 1,
                      ),
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
class BoardDragTarget extends StatefulWidget {
  final Widget child;
  final GlobalKey?
      gridKey; // Key to the inner grid widget for accurate coordinates

  const BoardDragTarget({super.key, required this.child, this.gridKey});

  @override
  State<BoardDragTarget> createState() => _BoardDragTargetState();
}

class _BoardDragTargetState extends State<BoardDragTarget> {
  int _lastGridX = -1;
  int _lastGridY = -1;

  /// Centralized "Finger-to-Grid" calculation
  /// Returns (gridX, gridY) or null if calculation fails or coordinates are invalid
  ({int gridX, int gridY})? _calculateGridPosition(
    BuildContext context,
    Offset globalOffset,
    Piece piece,
  ) {
    final gameCubit = context.read<GameCubit>();
    final currentState = gameCubit.state;
    if (currentState is! GameInProgress) return null;

    // 1. Get the Grid RenderBox
    RenderBox? gridRenderBox;
    if (widget.gridKey?.currentContext != null) {
      gridRenderBox =
          widget.gridKey!.currentContext!.findRenderObject() as RenderBox?;
    }

    // Fallback to DragTarget's RenderBox (less accurate)
    final fallbackRenderBox = context.findRenderObject() as RenderBox?;
    final renderBox = gridRenderBox ?? fallbackRenderBox;

    if (renderBox == null) return null;

    // 2. Convert Global Drop Coordinate to Local Grid Coordinate
    // CRITICAL FIX: details.offset represents the top-left corner of the dragged piece (visual feedback)
    // NOT the anchor point. The dragAnchorStrategy sets where the anchor is relative to the feedback widget,
    // but details.offset gives us the global position of the feedback widget's top-left corner.
    final localPosition = renderBox.globalToLocal(globalOffset);

    final board = currentState.board;
    final blockSize = AppConfig.getBlockSize(context, board.size);

    // details.offset is already the top-left corner of the feedback widget
    // So we can use it directly after converting to local coordinates
    double adjustedX = localPosition.dx;
    double adjustedY = localPosition.dy;

    // 3. Padding correction only needed if using fallback render box
    // When using gridRenderBox, we're already inside the padding, so no correction needed
    if (gridRenderBox == null) {
      // Fallback: subtract padding to get position relative to grid
      adjustedX -= AppConfig.boardContainerPadding;
      adjustedY -= AppConfig.boardContainerPadding;
    }

    // 4. Calculate Grid Coordinates
    // Using round() instead of floor() provides a better "magnetic" snap feel
    // when the piece is slightly off-center.
    final gridX = (adjustedX / blockSize).round();
    final gridY = (adjustedY / blockSize).round();

    // 6. Validate Bounds
    // Allow -1 for lenient edge detection (clamped later by logic)
    if (gridX < -1 || gridY < -1) return null;
    if (gridX + piece.width > board.size + 1 ||
        gridY + piece.height > board.size + 1) {
      return null;
    }

    return (gridX: gridX, gridY: gridY);
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<Piece>(
      onWillAcceptWithDetails: (details) => true,
      // Critical: Recalculate position fresh to avoid stale state issues
      onAcceptWithDetails: (details) {
        final gameCubit = context.read<GameCubit>();
        final settings = context.read<SettingsCubit>().state;
        final piece = details.data;

        // CRITICAL FIX: Always recalculate from current finger position
        // Never use cached position as fallback - it could be stale or from wrong drag session
        final gridPos = _calculateGridPosition(context, details.offset, piece);

        // If calculation fails, reject the drop (don't use stale cached position)
        if (gridPos == null) {
          gameCubit.clearHoverBlocks();
          _lastGridX = -1;
          _lastGridY = -1;
          if (settings.hapticsEnabled) {
            _intelligentHaptic(HapticFeedbackType.error);
          }
          return;
        }

        final gridX = gridPos.gridX;
        final gridY = gridPos.gridY;

        // CRITICAL FIX: Double-check placement validity before attempting
        // This prevents race conditions where board state changed between onMove and onAccept
        final currentState = gameCubit.state;
        if (currentState is! GameInProgress) {
          gameCubit.clearHoverBlocks();
          _lastGridX = -1;
          _lastGridY = -1;
          return;
        }

        // Validate placement one more time with current board state
        if (!currentState.board.canPlacePiece(piece, gridX, gridY)) {
          gameCubit.clearHoverBlocks();
          _lastGridX = -1;
          _lastGridY = -1;
          if (settings.hapticsEnabled) {
            _intelligentHaptic(HapticFeedbackType.error);
          }
          return;
        }

        // #region agent log
        _dragDebugLog('BoardDragTarget.onAcceptWithDetails', 'H1', {
          'gridX': gridX,
          'gridY': gridY,
          'lastGridX': _lastGridX,
          'lastGridY': _lastGridY,
          'pieceId': piece.id,
          'offset': details.offset.toString(),
          'MISMATCH': gridX != _lastGridX || gridY != _lastGridY,
        });
        // #endregion
        // Place the piece
        final success = gameCubit.placePiece(piece, gridX, gridY);

        if (settings.hapticsEnabled) {
          if (success) {
            // Drop haptic is handled in onDragEnd, but we can add line clear haptic here
            // Line clear haptic is handled by sound service
          } else {
            _intelligentHaptic(HapticFeedbackType.error);
          }
        }

        // Reset state
        _lastGridX = -1;
        _lastGridY = -1;
      },
      onMove: (details) {
        // Show hover preview while dragging
        final gameCubit = context.read<GameCubit>();
        final piece = details.data;

        final gridPos = _calculateGridPosition(context, details.offset, piece);
        if (gridPos == null) {
          // Invalid position - clear hover if we had one
          if (_lastGridX != -1 || _lastGridY != -1) {
            gameCubit.clearHoverBlocks();
            _lastGridX = -1;
            _lastGridY = -1;
          }
          return;
        }

        final gridX = gridPos.gridX;
        final gridY = gridPos.gridY;

        // Only update if position changed (prevents unnecessary rebuilds)
        if (gridX != _lastGridX || gridY != _lastGridY) {
          // OPTIMIZATION: Removed redundant canPlacePiece check here
          // showHoverPreview already validates the position internally
          // This eliminates duplicate expensive collision detection calls
          gameCubit.showHoverPreview(piece, gridX, gridY);

          // Haptic feedback when entering a new valid spot
          final currentState = gameCubit.state;
          if (currentState is GameInProgress) {
            final settings = context.read<SettingsCubit>().state;
            if (settings.hapticsEnabled &&
                currentState.hoverValid == true &&
                (_lastGridX == -1 || _lastGridY == -1)) {
              // Only vibrate when entering a new valid spot for the first time
              _intelligentHaptic(HapticFeedbackType.hoverValid);
            }
          }

          // Track last position for change detection
          _lastGridX = gridX;
          _lastGridY = gridY;
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
