import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/game/game_cubit.dart';
import '../cubits/game/game_state.dart';
import '../cubits/settings/settings_cubit.dart';
import '../models/board.dart';
import '../config/app_config.dart';
import 'ghost_piece_preview.dart';

class BoardGridWidget extends StatelessWidget {
  final GlobalKey? gridKey;

  const BoardGridWidget({super.key, this.gridKey});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<SettingsCubit>().state.currentTheme;

    // Use BlocBuilder to react to game state changes (mode changes)
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, gameState) {
        // Use consistent container size for both modes
        // The visual difference comes from the number of cells (8x8 vs 10x10)
        // Blocks will naturally be smaller in chaos mode due to more cells
        final containerSize = AppConfig.getSize(context);

        return Container(
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            color: theme.boardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.blockColors.first.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.blockColors.first.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Stack(
              key: gridKey,
              clipBehavior: Clip.none,
              children: [
                // LAYER 1: The Static Grid (HEAVY)
                // This ignores hover updates and only rebuilds on piece placement
                const _StaticBoardLayer(),

                // LAYER 2: The Ghost Piece (LIGHT)
                // This listens to hover updates and rebuilds frequently
                const _GhostOverlayLayer(),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// This layer ONLY rebuilds when the board structure changes (place/clear)
/// It ignores hover events completely.
class _StaticBoardLayer extends StatelessWidget {
  const _StaticBoardLayer();

  @override
  Widget build(BuildContext context) {
    // Select specific data to prevent unnecessary rebuilds
    return BlocSelector<GameCubit, GameState, Board?>(
      selector: (state) {
        if (state is GameInProgress) return state.board;
        if (state is GameOver) return state.board;
        return null;
      },
      builder: (context, board) {
        if (board == null) {
          return const Center(
              child: Text('Loading...', style: TextStyle(color: Colors.white)));
        }

        final theme = context.read<SettingsCubit>().state.currentTheme;

        // RepaintBoundary caches the expensive grid as an image
        return RepaintBoundary(
          child: Stack(
            children: [
              // Grid lines layer - must fill the available space
              Positioned.fill(
                child: CustomPaint(
                  painter: GridLinesPainter(
                    boardSize: board.size,
                    lineColor: theme.blockColors.first.withValues(alpha: 0.15),
                  ),
                ),
              ),
              // Grid cells layer
              Column(
                children: List.generate(board.size, (row) {
                  return Expanded(
                    child: Row(
                      children: List.generate(board.size, (col) {
                        final block = board.grid[row][col];
                        return Expanded(
                          // We use a const constructor where possible
                          child: _BlockCell(
                            block: block,
                            row: row,
                            col: col,
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// This layer handles the Ghost Piece and rebuilds quickly during drag
class _GhostOverlayLayer extends StatelessWidget {
  const _GhostOverlayLayer();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (previous, current) {
        // Only rebuild if hover properties change
        if (previous is! GameInProgress || current is! GameInProgress) {
          return true;
        }
        return previous.hoverX != current.hoverX ||
            previous.hoverY != current.hoverY ||
            previous.hoverPiece != current.hoverPiece ||
            previous.hoverValid != current.hoverValid;
      },
      builder: (context, state) {
        if (state is! GameInProgress) return const SizedBox.shrink();

        // Show ghost piece if we have valid coordinates
        if (state.hoverPiece != null &&
            state.hoverX != null &&
            state.hoverY != null) {
          return GhostPiecePreview(
            piece: state.hoverPiece,
            gridX: state.hoverX!,
            gridY: state.hoverY!,
            isValid: state.hoverValid ?? false,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ... COPY PASTE THE REST OF YOUR EXISTING CLASSES BELOW ...
// (GridLinesPainter, _BlockCell, and _BlockCellState from your previous file)
// They were fine, just needed to be inside the Optimized Structure above.
class GridLinesPainter extends CustomPainter {
  final int boardSize;
  final Color lineColor;

  GridLinesPainter({
    required this.boardSize,
    this.lineColor = const Color.fromRGBO(255, 255, 255, 0.15),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    final cellWidth = size.width / boardSize;
    final cellHeight = size.height / boardSize;

    for (int i = 0; i <= boardSize; i++) {
      final x = i * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (int i = 0; i <= boardSize; i++) {
      final y = i * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GridLinesPainter oldDelegate) {
    return lineColor != oldDelegate.lineColor ||
        boardSize != oldDelegate.boardSize;
  }
}

class _BlockCell extends StatefulWidget {
  final BoardBlock block;
  final int row;
  final int col;

  const _BlockCell({
    required this.block,
    required this.row,
    required this.col,
  });

  @override
  State<_BlockCell> createState() => _BlockCellState();
}

class _BlockCellState extends State<_BlockCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isShowingGlow(BlockType blockType) {
    return blockType == BlockType.hoverBreakFilled ||
        blockType == BlockType.hoverBreakEmpty ||
        blockType == BlockType.hoverBreak;
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (_isShowingGlow(widget.block.type)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _pulseController.repeat(reverse: true);
        }
      });
    }
  }

  @override
  void didUpdateWidget(_BlockCell oldWidget) {
    super.didUpdateWidget(oldWidget);

    final isShowingGlow = _isShowingGlow(widget.block.type);
    final wasShowingGlow = _isShowingGlow(oldWidget.block.type);

    if (isShowingGlow && !wasShowingGlow) {
      _pulseController.repeat(reverse: true);
    }

    if (!isShowingGlow && wasShowingGlow) {
      _pulseController.stop();
      _pulseController.reset();
    }

    if ((widget.block.type == BlockType.filled &&
            oldWidget.block.type != BlockType.filled) ||
        (widget.block.type == BlockType.hoverBreakFilled &&
            oldWidget.block.type != BlockType.hoverBreakFilled)) {
      if (!isShowingGlow) {
        _pulseController.forward(from: 0.0).then((_) {
          if (mounted) _pulseController.reverse();
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color cellColor;
    bool isBreaking = false;
    bool isEmpty = false;

    switch (widget.block.type) {
      case BlockType.filled:
        cellColor = widget.block.color ?? Colors.blue;
        break;
      case BlockType.hover:
        cellColor = widget.block.color ?? Colors.blue;
        break;
      case BlockType.hoverBreakFilled:
        cellColor = widget.block.color ?? Colors.blue;
        isBreaking = true;
        break;
      case BlockType.hoverBreakEmpty:
        cellColor =
            widget.block.hoverBreakColor ?? widget.block.color ?? Colors.blue;
        isBreaking = true;
        break;
      case BlockType.hoverBreak:
        cellColor = widget.block.color ?? Colors.blue;
        isBreaking = true;
        break;
      case BlockType.empty:
        cellColor = const Color(0xFF1a1a2e);
        isEmpty = true;
    }

    final theme = context.watch<SettingsCubit>().state.currentTheme;

    if (isEmpty) {
      final isAlternate = (widget.row + widget.col) % 2 == 0;
      return Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.emptyBlockColor,
              isAlternate
                  ? theme.emptyBlockColor.withValues(alpha: 0.9)
                  : theme.emptyBlockColor.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: theme.blockColors.first.withValues(alpha: 0.08),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 1,
              offset: const Offset(0, 0.5),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final isGlowing = _isShowingGlow(widget.block.type);
        final scale = isGlowing ? _pulseAnimation.value : 1.0;
        final glowIntensity = isGlowing ? _pulseAnimation.value - 1.0 : 0.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: (widget.block.type == BlockType.filled ||
                      widget.block.type == BlockType.hoverBreakFilled)
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cellColor,
                        cellColor.withValues(alpha: 0.8),
                        cellColor.withValues(alpha: 0.6),
                      ],
                    )
                  : null,
              color: (widget.block.type != BlockType.filled &&
                      widget.block.type != BlockType.hoverBreakFilled)
                  ? cellColor.withValues(alpha: isBreaking ? 0.4 : 1.0)
                  : null,
              border: Border.all(
                color: (widget.block.type == BlockType.filled ||
                        widget.block.type == BlockType.hoverBreakFilled)
                    ? Colors.white.withValues(alpha: 0.3)
                    : isBreaking
                        ? Colors.white
                            .withValues(alpha: 0.9 + glowIntensity * 0.1)
                        : cellColor.withValues(alpha: 0.6),
                width: (widget.block.type == BlockType.filled ||
                        widget.block.type == BlockType.hoverBreakFilled)
                    ? 1
                    : (isBreaking ? 1.5 + glowIntensity * 1.0 : 1),
              ),
              boxShadow: [
                if (widget.block.type == BlockType.filled ||
                    widget.block.type == BlockType.hoverBreakFilled) ...[
                  BoxShadow(
                    color: cellColor.withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                if (isGlowing) ...[
                  BoxShadow(
                    color:
                        cellColor.withValues(alpha: 0.9 + glowIntensity * 0.1),
                    blurRadius: 12 + glowIntensity * 8,
                    spreadRadius: 3 + glowIntensity * 2,
                  ),
                  BoxShadow(
                    color: Colors.white
                        .withValues(alpha: 0.5 + glowIntensity * 0.5),
                    blurRadius: 6 + glowIntensity * 6,
                    spreadRadius: 1 + glowIntensity * 2,
                  ),
                ],
              ],
            ),
            child: (widget.block.type == BlockType.filled ||
                    widget.block.type == BlockType.hoverBreakFilled)
                ? Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.4],
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
