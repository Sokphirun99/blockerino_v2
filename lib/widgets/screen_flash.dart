import 'package:flutter/material.dart';

/// A full-screen flash effect widget for visual feedback
/// Used for perfect clears, chaos events, and other special moments
class ScreenFlash extends StatefulWidget {
  final Color color;
  final VoidCallback onComplete;

  const ScreenFlash({
    super.key,
    required this.color,
    required this.onComplete,
  });

  @override
  State<ScreenFlash> createState() => _ScreenFlashState();
}

class _ScreenFlashState extends State<ScreenFlash>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Create opacity animation with TweenSequence
    // Flash in quickly (0 → 0.7), then fade out slowly (0.7 → 0)
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.7)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.7, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 80,
      ),
    ]).animate(_controller);

    // Start animation and call onComplete when done
    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return IgnorePointer(
          child: Container(
            color: widget.color.withValues(alpha: _opacityAnimation.value),
          ),
        );
      },
    );
  }
}
