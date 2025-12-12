import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/game/game_cubit.dart';
import '../cubits/game/game_state.dart';
import '../models/board.dart';
import '../models/piece.dart';
import '../config/app_config.dart';

class BoardGridWidget extends StatelessWidget {
  const BoardGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        if (state is! GameInProgress) {
          return const Center(
            child: Text(
              'Loading board...',
              style: TextStyle(color: Colors.white),
            ),
          );
        }
        final board = state.board;

        // Use shared AppConfig for consistent sizing
        final boardSize = AppConfig.getSize(context);

        return Container(
          width: boardSize,
          height: boardSize,
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e), // Dark blue-purple background
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.purple.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.2),
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
            child: CustomPaint(
              painter: GridLinesPainter(boardSize: board.size),
              child: Column(
                children: List.generate(board.size, (row) {
                  return Expanded(
                    child: Row(
                      children: List.generate(board.size, (col) {
                        final block = board.grid[row][col];
                        return Expanded(
                          child: DragTarget<Piece>(
                            onWillAcceptWithDetails: (details) {
                              final piece = details.data;
                              // Adjust coordinates to center the piece on the finger
                              // col is X (horizontal), row is Y (vertical)
                              final adjustX = (piece.width / 2).floor();
                              final adjustY = (piece.height / 2).floor();
                              final targetCol = col - adjustX;
                              final targetRow = row - adjustY;
                              
                              context.read<GameCubit>().showHoverPreview(piece, targetCol, targetRow);
                              return true;
                            },
                            onLeave: (_) {
                              context.read<GameCubit>().clearHoverBlocks();
                            },
                            onAcceptWithDetails: (details) {
                              final piece = details.data;
                              // Adjust coordinates to center the piece on the finger
                              // col is X (horizontal), row is Y (vertical)
                              final adjustX = (piece.width / 2).floor();
                              final adjustY = (piece.height / 2).floor();
                              final targetCol = col - adjustX;
                              final targetRow = row - adjustY;
                              
                              context.read<GameCubit>().placePiece(piece, targetCol, targetRow);
                            },
                            builder: (context, candidateData, rejectedData) {
                              return _BlockCell(block: block);
                            },
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for grid lines (like original)
class GridLinesPainter extends CustomPainter {
  final int boardSize;

  GridLinesPainter({required this.boardSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    final cellWidth = size.width / boardSize;
    final cellHeight = size.height / boardSize;

    // Draw vertical lines
    for (int i = 0; i <= boardSize; i++) {
      final x = i * cellWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (int i = 0; i <= boardSize; i++) {
      final y = i * cellHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BlockCell extends StatefulWidget {
  final BoardBlock block;

  const _BlockCell({
    required this.block,
  });

  @override
  State<_BlockCell> createState() => _BlockCellState();
}

class _BlockCellState extends State<_BlockCell> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
    
    // Start animation if block is already in glow state
    final isShowingGlow = widget.block.type == BlockType.hoverBreakFilled ||
                          widget.block.type == BlockType.hoverBreakEmpty ||
                          widget.block.type == BlockType.hoverBreak;
    if (isShowingGlow) {
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
    
    final isShowingGlow = widget.block.type == BlockType.hoverBreakFilled ||
                          widget.block.type == BlockType.hoverBreakEmpty ||
                          widget.block.type == BlockType.hoverBreak;
    
    final wasShowingGlow = oldWidget.block.type == BlockType.hoverBreakFilled ||
                           oldWidget.block.type == BlockType.hoverBreakEmpty ||
                           oldWidget.block.type == BlockType.hoverBreak;
    
    // Start continuous pulsing when entering glow state
    if (isShowingGlow && !wasShowingGlow) {
      _pulseController.repeat(reverse: true);
    }
    
    // Stop pulsing when leaving glow state
    if (!isShowingGlow && wasShowingGlow) {
      _pulseController.stop();
      _pulseController.reset();
    }
    
    // Trigger single pulse animation when block becomes filled
    if ((widget.block.type == BlockType.filled && oldWidget.block.type != BlockType.filled) ||
        (widget.block.type == BlockType.hoverBreakFilled && oldWidget.block.type != BlockType.hoverBreakFilled)) {
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
    bool showGlow = false;
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
        cellColor = widget.block.color ?? Colors.blue; // Use actual block color
        showGlow = true;
        isBreaking = true;
        break;
      case BlockType.hoverBreakEmpty:
        cellColor = widget.block.hoverBreakColor ?? widget.block.color ?? Colors.blue;
        isBreaking = true;
        break;
      case BlockType.hoverBreak:
        cellColor = widget.block.color ?? Colors.blue; // Use actual block color
        isBreaking = true;
        break;
      case BlockType.empty:
        cellColor = const Color(0xFF1a1a2e);
        isEmpty = true;
    }

    if (isEmpty) {
      return Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: const Color(0xFF0f0f1e),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    // Wrap with AnimatedBuilder for pulsing effect on matching blocks
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = showGlow ? _pulseAnimation.value : 1.0;
        final glowIntensity = showGlow ? _pulseAnimation.value - 1.0 : 0.0; // 0.0 to 0.15
        
        return Transform.scale(
          scale: scale,
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: (widget.block.type == BlockType.filled || widget.block.type == BlockType.hoverBreakFilled)
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _lightenColor(cellColor, 0.25),
                        cellColor,
                        _darkenColor(cellColor, 0.2),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    )
                  : widget.block.type == BlockType.hover
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _lightenColor(cellColor, 0.25).withValues(alpha: 0.6),
                            cellColor.withValues(alpha: 0.5),
                            _darkenColor(cellColor, 0.2).withValues(alpha: 0.4),
                          ],
                        )
                      : null,
              color: (widget.block.type != BlockType.filled && 
                      widget.block.type != BlockType.hover &&
                      widget.block.type != BlockType.hoverBreakFilled)
                  ? cellColor.withValues(alpha: isBreaking ? 0.4 : 1.0)
                  : null,
              border: Border.all(
                color: (widget.block.type == BlockType.filled || widget.block.type == BlockType.hoverBreakFilled)
                    ? _lightenColor(cellColor, 0.4).withValues(alpha: 0.8)
                    : isBreaking
                        ? Colors.white.withValues(alpha: 0.9 + glowIntensity * 0.1)
                        : cellColor.withValues(alpha: 0.6),
                width: (widget.block.type == BlockType.filled || widget.block.type == BlockType.hoverBreakFilled) 
                    ? 1.5 + (showGlow ? glowIntensity * 1.0 : 0)
                    : (isBreaking ? 1.5 + glowIntensity * 1.0 : 1),
              ),
              boxShadow: [
                if (widget.block.type == BlockType.filled || widget.block.type == BlockType.hoverBreakFilled) ...[
                  BoxShadow(
                    color: _darkenColor(cellColor, 0.3).withValues(alpha: 0.6),
                    offset: const Offset(0, 2),
                    blurRadius: 3,
                  ),
                  BoxShadow(
                    color: _lightenColor(cellColor, 0.3).withValues(alpha: 0.3),
                    offset: const Offset(0, -1),
                    blurRadius: 2,
                  ),
                ],
                if (showGlow) ...[
                  BoxShadow(
                    color: cellColor.withValues(alpha: 0.9 + glowIntensity * 0.1),
                    blurRadius: 12 + glowIntensity * 8,
                    spreadRadius: 3 + glowIntensity * 2,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.5 + glowIntensity * 0.5),
                    blurRadius: 6 + glowIntensity * 6,
                    spreadRadius: 1 + glowIntensity * 2,
                  ),
                ],
              ],
            ),
            child: (widget.block.type == BlockType.filled || widget.block.type == BlockType.hoverBreakFilled)
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
