import 'dart:math';
import 'package:flutter/material.dart';

/// Widget that applies screen shake effect to its child
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
  final Random _random = Random();
  Offset _shakeOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(_updateShake);
  }

  @override
  void didUpdateWidget(ScreenShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldShake && !oldWidget.shouldShake) {
      _startShake();
    }
  }

  void _startShake() {
    _controller.forward(from: 0.0).then((_) {
      if (!mounted) return;
      setState(() {
        _shakeOffset = Offset.zero;
      });
      widget.onShakeComplete?.call();
    });
  }

  void _updateShake() {
    if (!mounted) return;
    if (_controller.isAnimating) {
      final progress = _controller.value;
      final intensity = widget.intensity * (1.0 - progress); // Decay over time
      
      setState(() {
        _shakeOffset = Offset(
          (_random.nextDouble() - 0.5) * intensity * 2,
          (_random.nextDouble() - 0.5) * intensity * 2,
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: _shakeOffset,
      child: widget.child,
    );
  }
}
