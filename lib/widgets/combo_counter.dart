import 'package:flutter/material.dart';

/// Animated combo counter widget that displays combo streaks
/// Shows pulse animation and color changes based on combo level
class ComboCounter extends StatefulWidget {
  final int combo;
  final bool isActive;

  const ComboCounter({
    super.key,
    required this.combo,
    required this.isActive,
  });

  @override
  State<ComboCounter> createState() => _ComboCounterState();
}

class _ComboCounterState extends State<ComboCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Setup pulse animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Create pulse animation (scale 1.0 ↔ 1.15)
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Start repeating animation if active
    if (widget.isActive && widget.combo >= 2) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ComboCounter oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If combo increased, restart animation from beginning
    if (widget.combo > oldWidget.combo) {
      _controller.forward(from: 0);
      if (widget.isActive && widget.combo >= 2) {
        _controller.repeat(reverse: true);
      }
    }

    // Handle active state changes
    if (widget.isActive && widget.combo >= 2 && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive || widget.combo < 2) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hide if combo < 2 or not active
    if (widget.combo < 2 || !widget.isActive) {
      return const SizedBox.shrink();
    }

    // Choose colors based on combo level
    final List<Color> gradientColors;
    if (widget.combo >= 10) {
      gradientColors = [Colors.purple, Colors.pink];
    } else if (widget.combo >= 5) {
      gradientColors = [Colors.orange, Colors.red];
    } else {
      gradientColors = [Colors.blue, Colors.cyan];
    }

    // Choose emoji and size based on combo level
    final String emoji;
    final double emojiSize;
    if (widget.combo >= 10) {
      emoji = '💥';
      emojiSize = 32;
    } else if (widget.combo >= 5) {
      emoji = '🔥';
      emojiSize = 28;
    } else {
      emoji = '⚡';
      emojiSize = 24;
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first
                      .withValues(alpha: 0.3 + (_pulseAnimation.value - 1.0) * 2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: TextStyle(fontSize: emojiSize),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COMBO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '×${widget.combo}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
