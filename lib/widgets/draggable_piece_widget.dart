import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/piece.dart';
import '../cubits/game/game_cubit.dart';
import '../cubits/game/game_state.dart';
import '../cubits/settings/settings_cubit.dart';
import '../config/app_config.dart';

// #region agent log
int _dragLogCounter = 0;
void _dragDebugLog(
    String location, String hypothesisId, Map<String, dynamic> data) {
  if (kDebugMode) {
    _dragLogCounter++;
    debugPrint(
        '[DEBUG:$hypothesisId:#$_dragLogCounter] DragTarget.$location: $data');
  }
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
/// Uses a responsive value based on screen height, clamped to prevent extreme scaling
/// The offset is applied in both dragAnchorStrategy and _calculateGridPosition
/// to ensure visual feedback matches actual placement
/// Returns a positive value representing how many pixels the piece should float above the finger
double _getDragYOffset(BuildContext context) {
  // TABLET FIX: Use responsive offset based on screen height
  // - Phones (height ~800): ~48-56 pixels
  // - Tablets (height ~1200+): ~72-80 pixels (capped)
  // Clamp prevents extreme values that caused coordinate mismatch
  final screenHeight = MediaQuery.of(context).size.height;
  final responsiveOffset = screenHeight * 0.06; // 6% of screen height
  return responsiveOffset.clamp(48.0, 80.0); // Min 48, Max 80 logical pixels
}

/// Scale factor applied to feedback during drag
/// IMPORTANT: This must match the scale value in Transform.scale in feedback widget
const double _feedbackScale = 1.15;

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
    _isDragging =
        false; // Reset state to prevent stale state on widget recreation
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
        // Fat Finger fix: Make piece float ABOVE finger for better visibility
        // The anchor point determines where the finger "grabs" the piece
        // A larger anchor Y offset means the piece appears higher above the finger
        //
        // TABLET FIX: Account for feedback scale factor
        // Transform.scale scales from center, but anchor is from top-left
        // We need to account for how scaling affects the visual position
        //
        // Even-sized piece alignment: subtract 0.5 to align with grid intersections
        final widthOffset = (widget.piece.width % 2 == 0) ? -0.5 : 0.0;
        final heightOffset = (widget.piece.height % 2 == 0) ? -0.5 : 0.0;
        final dragYOffset = _getDragYOffset(context);

        // Calculate base anchor at piece center
        final baseCenterX = (widget.piece.width / 2 + widthOffset) * feedbackBlockSize;
        final baseCenterY = (widget.piece.height / 2 + heightOffset) * feedbackBlockSize;
        
        // Return offset from piece top-left to anchor point (finger position)
        // X: piece center (horizontal alignment)
        // Y: piece center PLUS Y offset (anchor is below piece center, so piece appears ABOVE finger)
        return Offset(baseCenterX, baseCenterY + dragYOffset);
      },
      feedback: Transform.scale(
        scale: _feedbackScale, // Scale up when dragging - better visibility
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
        // BUG FIX #1: Check mounted before starting animation to prevent memory leak
        if (mounted) {
          // Bounce effect: scale down then back up
          _scaleController.reverse().then((_) {
            if (mounted) {
              _scaleController.value = 0;
            }
          });
        }

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

    // BUG FIX #5: Add debug logging for null renderBox
    if (renderBox == null) {
      if (kDebugMode) {
        debugPrint('WARNING: Cannot calculate grid position - renderBox is null');
      }
      return null;
    }

    // 2. Convert Global Drop Coordinate to Local Grid Coordinate
    // CRITICAL FIX: details.offset represents the top-left corner of the dragged piece (visual feedback)
    // NOT the anchor point. The dragAnchorStrategy sets where the anchor is relative to the feedback widget,
    // but details.offset gives us the global position of the feedback widget's top-left corner.
    final localPosition = renderBox.globalToLocal(globalOffset);

    final board = currentState.board;
    // CRITICAL FIX: Use cell size (effectiveSize / gridSize) for grid coordinate calculation
    // This matches exactly how the ghost preview calculates positions
    // The effectiveSize accounts for border + padding, and cell size matches Expanded widget division
    // ✅ VERIFIED: Uses same calculation as ghost_piece_preview.dart
    // Both use: effectiveSize = AppConfig.getEffectiveSize(context)
    // Both use: cellSize = effectiveSize / board.size
    // This ensures ghost preview positioning matches actual placement - NOT a bug
    final effectiveSize = AppConfig.getEffectiveSize(context);
    final cellSize = effectiveSize /
        board.size; // Full cell size (matches Expanded division)

    // details.offset is already the top-left corner of the feedback widget
    // So we can use it directly after converting to local coordinates
    double adjustedX = localPosition.dx;
    double adjustedY = localPosition.dy;

    // 3. Padding correction only needed if using fallback render box
    // When using gridRenderBox, we're already inside the padding, so no correction needed
    if (gridRenderBox == null) {
      // Fallback: subtract border and padding to get position relative to grid
      // Border (2.0 * 2) + Padding (4.0 * 2) = 12.0
      adjustedX -= AppConfig.boardContainerPadding + AppConfig.boardBorderWidth;
      adjustedY -= AppConfig.boardContainerPadding + AppConfig.boardBorderWidth;
    }

    // 4. Compensate for the "Fat Finger" offset from dragAnchorStrategy
    // The dragAnchorStrategy shifts the visual piece ABOVE the finger by dragYOffset
    // The visual feedback shows the piece higher than the finger position
    // To place the piece where it VISUALLY appears, we need to add the offset back
    // This ensures: what you see is where the piece lands
    final dragYOffset = _getDragYOffset(context);
    adjustedY += dragYOffset;

    // 5. Calculate Grid Coordinates using full cell size
    // Using round() instead of floor() provides a better "magnetic" snap feel
    // when the piece is slightly off-center.
    final gridX = (adjustedX / cellSize).round();
    final gridY = (adjustedY / cellSize).round();

    // BUG FIX #3: Strict validation - reject negative coordinates and out-of-bounds
    // No clamping or lenient edge detection - coordinates must be valid
    if (gridX < 0 || gridY < 0) return null;
    if (gridX + piece.width > board.size || gridY + piece.height > board.size) {
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

        // BUG FIX #6: Additional bounds validation with current board state
        // Protects against race conditions where board size changed
        if (gridX < 0 ||
            gridY < 0 ||
            gridX + piece.width > currentState.board.size ||
            gridY + piece.height > currentState.board.size) {
          gameCubit.clearHoverBlocks();
          _lastGridX = -1;
          _lastGridY = -1;
          if (settings.hapticsEnabled) {
            _intelligentHaptic(HapticFeedbackType.error);
          }
          return;
        }

        // CRITICAL FIX: Validate placement one more time with current board state
        // This prevents race conditions where board size or state changed between
        // position calculation and placement (e.g., mode switch, piece placement, etc.)
        if (!currentState.board.canPlacePiece(piece, gridX, gridY)) {
          gameCubit.clearHoverBlocks();
          _lastGridX = -1;
          _lastGridY = -1;
          if (settings.hapticsEnabled) {
            _intelligentHaptic(HapticFeedbackType.error);
          }
          return; // Reject placement
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

        // OPTIMIZATION: Validate bounds BEFORE calling showHoverPreview
        // This prevents unnecessary state emissions when moving between invalid positions
        final currentState = gameCubit.state;
        if (currentState is! GameInProgress) {
          if (_lastGridX != -1 || _lastGridY != -1) {
            gameCubit.clearHoverBlocks();
            _lastGridX = -1;
            _lastGridY = -1;
          }
          return;
        }

        // Validate bounds immediately - don't call showHoverPreview for invalid positions
        if (gridX < 0 ||
            gridY < 0 ||
            gridX + piece.width > currentState.board.size ||
            gridY + piece.height > currentState.board.size) {
          // Out of bounds - clear hover if we had one
          if (_lastGridX != -1 || _lastGridY != -1) {
            gameCubit.clearHoverBlocks();
            _lastGridX = -1;
            _lastGridY = -1;
          }
          return; // Don't call showHoverPreview for invalid positions
        }

        // Only update if position changed (prevents unnecessary rebuilds)
        if (gridX != _lastGridX || gridY != _lastGridY) {
          // Now call showHoverPreview only for valid grid positions
          // OPTIMIZATION: showHoverPreview validates placement internally
          gameCubit.showHoverPreview(piece, gridX, gridY);

          // Haptic feedback when entering a new valid spot
          final settings = context.read<SettingsCubit>().state;
          if (settings.hapticsEnabled &&
              currentState.hoverValid == true &&
              (_lastGridX == -1 || _lastGridY == -1)) {
            // Only vibrate when entering a new valid spot for the first time
            _intelligentHaptic(HapticFeedbackType.hoverValid);
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
