import 'dart:math';
import 'package:flutter/material.dart';

/// Widget that applies screen shake effect to its child
/// Optimized to avoid unnecessary rebuilds
class ScreenShakeWidget extends StatefulWidget {
  final Widget child;
  final bool shouldShake;
  final VoidCallback? onShakeComplete;
  final double intensity;

  const ScreenShakeWidget({
    super.key,
    required this.child,
    required this.shouldShake,
    this.onShakeComplete,
    this.intensity = 10.0,
  });

  @override
  State<ScreenShakeWidget> createState() => _ScreenShakeWidgetState();
}

class _ScreenShakeWidgetState extends State<ScreenShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;
  final Random _random = Random();

  // Pre-generate shake offsets for smoother animation
  final List<Offset> _shakeOffsets = [];
  static const int _shakeFrames = 12; // Reduced frame count

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    // Pre-generate shake offsets
    _generateShakeOffsets();
  }

  void _generateShakeOffsets() {
    _shakeOffsets.clear();
    for (int i = 0; i < _shakeFrames; i++) {
      _shakeOffsets.add(Offset(
        (_random.nextDouble() - 0.5) * 2,
        (_random.nextDouble() - 0.5) * 2,
      ));
    }
  }

  @override
  void didUpdateWidget(ScreenShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldShake && !oldWidget.shouldShake) {
      _startShake();
    }
  }

  void _startShake() {
    _generateShakeOffsets(); // New random offsets each shake
    _controller.forward(from: 0.0).then((_) {
      widget.onShakeComplete?.call();
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
      animation: _shakeAnimation,
      builder: (context, child) {
        if (!_controller.isAnimating) {
          return child!;
        }

        final progress = _shakeAnimation.value;
        final intensity = widget.intensity * (1.0 - progress);
        final frameIndex = (progress * (_shakeFrames - 1)).floor().clamp(0, _shakeFrames - 1);
        final offset = _shakeOffsets[frameIndex] * intensity;

        return Transform.translate(
          offset: offset,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
