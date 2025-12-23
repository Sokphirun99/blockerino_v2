import 'package:flutter/material.dart';

/// A floating score popup that appears when lines are cleared
/// Floats upward and fades out for satisfying visual feedback
class FloatingScoreWidget extends StatefulWidget {
  final int score;
  final Offset position;
  final VoidCallback onComplete;
  final Color? color;
  final bool isCombo;
  final int comboLevel;

  const FloatingScoreWidget({
    super.key,
    required this.score,
    required this.position,
    required this.onComplete,
    this.color,
    this.isCombo = false,
    this.comboLevel = 0,
  });

  @override
  State<FloatingScoreWidget> createState() => _FloatingScoreWidgetState();
}

class _FloatingScoreWidgetState extends State<FloatingScoreWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: widget.isCombo ? 1200 : 800),
      vsync: this,
    );

    // Fade: 0 -> 1 -> 1 -> 0 (appear, stay, fade out)
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 35),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Slide upward
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: widget.isCombo ? -80.0 : -50.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Scale: pop in then shrink slightly
    // Use easeOut instead of elasticOut to prevent values outside 0-1 range
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.3), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    // Add status listener to handle completion safely
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onComplete();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getScoreColor() {
    if (widget.color != null) return widget.color!;

    if (widget.isCombo) {
      // Combo colors escalate: yellow -> orange -> red -> magenta -> cyan
      switch (widget.comboLevel) {
        case 1:
          return const Color(0xFFFFD700); // Gold
        case 2:
          return const Color(0xFFFF8C00); // Orange
        case 3:
          return const Color(0xFFFF4500); // Red-Orange
        case 4:
          return const Color(0xFFFF1493); // Deep Pink
        default:
          return const Color(0xFF00FFFF); // Cyan (max combo)
      }
    }

    // Normal score colors based on amount
    if (widget.score >= 100) return const Color(0xFFFFD700); // Gold
    if (widget.score >= 50) return const Color(0xFF52b788); // Green
    return Colors.white;
  }

  String _getScoreText() {
    if (widget.isCombo) {
      return 'COMBO x${widget.comboLevel}!\n+${widget.score}';
    }
    return '+${widget.score}';
  }

  @override
  Widget build(BuildContext context) {
    // Safety check: don't build if controller is disposed
    if (!_controller.isAnimating && _controller.value >= 1.0) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Safety: clamp controller value to prevent TweenSequence assertion errors
        final controllerValue = _controller.value.clamp(0.0, 1.0);

        // Only evaluate animations if controller value is valid
        if (controllerValue != _controller.value) {
          // Controller value was outside range, skip this frame
          return const SizedBox.shrink();
        }

        // Clamp animation values to prevent assertion errors
        final fadeValue = _fadeAnimation.value.clamp(0.0, 1.0);
        final scaleValue = _scaleAnimation.value
            .clamp(0.0, 2.0); // Allow scale to go above 1.0

        return Positioned(
          left: widget.position.dx - 40,
          top: widget.position.dy + _slideAnimation.value,
          child: Opacity(
            opacity: fadeValue,
            child: Transform.scale(
              scale: scaleValue,
              child: Container(
                width: 80,
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    // Glow effect for combos
                    if (widget.isCombo)
                      Text(
                        _getScoreText(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: widget.isCombo ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 4
                            ..color = _getScoreColor().withValues(alpha: 0.5),
                        ),
                      ),
                    // Main text
                    Text(
                      _getScoreText(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: widget.isCombo ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(),
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            offset: const Offset(1, 1),
                            blurRadius: 3,
                          ),
                          if (widget.isCombo)
                            Shadow(
                              color: _getScoreColor().withValues(alpha: 0.8),
                              blurRadius: 10,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Data class for tracking floating scores
class FloatingScore {
  final String id;
  final int score;
  final Offset position;
  final bool isCombo;
  final int comboLevel;
  final Color? color;

  FloatingScore({
    required this.id,
    required this.score,
    required this.position,
    this.isCombo = false,
    this.comboLevel = 0,
    this.color,
  });
}
