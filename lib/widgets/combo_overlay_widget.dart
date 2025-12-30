import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/game/game_cubit.dart';
import '../cubits/game/game_state.dart';

/// Combo overlay that appears in the center of the board
/// Shows "COMBO x2", "COMBO x3", etc. with animated effects
class ComboOverlayWidget extends StatefulWidget {
  const ComboOverlayWidget({super.key});

  @override
  State<ComboOverlayWidget> createState() => _ComboOverlayWidgetState();
}

class _ComboOverlayWidgetState extends State<ComboOverlayWidget>
    with SingleTickerProviderStateMixin {
  // Animation constants
  static const Duration _animationDuration = Duration(milliseconds: 600);
  static const double _initialScale = 1.2;
  static const double _scaleTransitionPoint = 0.4;
  static const double _pulseMin = 0.98;
  static const double _pulseMax = 1.02;
  static const double _opacityTransitionPoint = 0.3;
  static const double _opacityMultiplier = 3.33;
  static const double _glowMin = 0.6;
  static const double _glowMax = 1.0;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  int _lastCombo = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );

    // Scale animation - starts big, bounces to normal
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: _initialScale)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: _initialScale, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 65,
      ),
    ]).animate(_controller);

    // Glow intensity animation
    _glowAnimation = Tween<double>(begin: _glowMin, end: _glowMax).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Get combo color based on combo level
  Color _getComboColor(int combo) {
    if (combo >= 15) return const Color(0xFFFF00FF); // Magenta
    if (combo >= 10) return const Color(0xFFFF1493); // Deep Pink
    if (combo >= 7) return const Color(0xFFFF4500); // Red-Orange
    if (combo >= 5) return const Color(0xFFFFA500); // Orange
    if (combo >= 3) return const Color(0xFFFFD700); // Gold
    return const Color(0xFFFFFF00); // Yellow
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (previous, current) {
        // Only rebuild when combo changes
        if (previous is GameInProgress && current is GameInProgress) {
          return previous.combo != current.combo;
        }
        return true;
      },
      builder: (context, gameState) {
        if (gameState is! GameInProgress) {
          return const SizedBox.shrink();
        }

        final combo = gameState.combo;

        // Handle combo state changes
        _handleComboChange(combo);

        // Only show if combo > 1
        if (combo <= 1) {
          return const SizedBox.shrink();
        }

        final comboColor = _getComboColor(combo);

        return Center(
          child: IgnorePointer(
            // Don't intercept touches
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final currentScale = _calculateCurrentScale();
                final glowIntensity =
                    _glowAnimation.value.clamp(_glowMin, _glowMax);

                return Transform.scale(
                  scale: currentScale.clamp(0.8, 1.2),
                  child: Opacity(
                    opacity: _calculateOpacity(),
                    child:
                        _buildComboContainer(comboColor, glowIntensity, combo),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Handle combo state changes and update animation accordingly
  void _handleComboChange(int combo) {
    if (combo <= 1) {
      // Combo reset - stop animation and hide
      if (_controller.isAnimating) {
        _controller.stop();
        _controller.reset();
      }
      _lastCombo = combo;
      return;
    }

    if (combo > _lastCombo) {
      // Combo increased - trigger animation
      _controller.forward(from: 0.0).then((_) {
        if (mounted && combo > 1) {
          _controller.repeat(reverse: true);
        }
      });
      _lastCombo = combo;
    } else if (combo < _lastCombo) {
      if (combo <= 1) {
        // Combo decreased to 0 or 1 (reset) - stop and hide
        _controller.stop();
        _controller.reset();
      }
      _lastCombo = combo;
    }
  }

  /// Calculate current scale based on animation progress
  double _calculateCurrentScale() {
    if (_controller.value < _scaleTransitionPoint) {
      return _scaleAnimation.value;
    }
    // Subtle pulse between min and max
    return _pulseMin +
        ((_controller.value - _scaleTransitionPoint) /
                (1.0 - _scaleTransitionPoint)) *
            (_pulseMax - _pulseMin);
  }

  /// Calculate opacity based on animation progress
  double _calculateOpacity() {
    if (_controller.value < _opacityTransitionPoint) {
      return _controller.value * _opacityMultiplier;
    }
    return 1.0;
  }

  /// Build the combo container with all styling
  Widget _buildComboContainer(
      Color comboColor, double glowIntensity, int combo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            comboColor,
            comboColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5 + (glowIntensity * 0.5)),
          width: 2.5,
        ),
        boxShadow: _buildBoxShadows(comboColor, glowIntensity),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🔥',
            style: TextStyle(fontSize: 28 + (glowIntensity * 4)),
          ),
          const SizedBox(width: 12),
          _buildComboText(combo),
        ],
      ),
    );
  }

  /// Build box shadows for the combo container
  List<BoxShadow> _buildBoxShadows(Color comboColor, double glowIntensity) {
    return [
      // Main glow shadow
      BoxShadow(
        color: comboColor.withValues(alpha: 0.4 + (glowIntensity * 0.4)),
        blurRadius: 20 + (glowIntensity * 20),
        spreadRadius: 4 + (glowIntensity * 4),
      ),
      // White glow shadow
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.3 + (glowIntensity * 0.3)),
        blurRadius: 15 + (glowIntensity * 15),
        spreadRadius: 2 + (glowIntensity * 2),
      ),
      // Outer shadow for depth
      const BoxShadow(
        color: Colors.black54,
        blurRadius: 30,
        offset: Offset(0, 8),
      ),
    ];
  }

  /// Build the combo text and multiplier badge
  Widget _buildComboText(int combo) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMBO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Text(
            'x$combo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
