import 'dart:math';
import 'package:flutter/material.dart';

/// Animated background with floating particles for atmosphere
/// Optimized for performance with minimal repaints
class AnimatedBackgroundWidget extends StatefulWidget {
  final double speedMultiplier;

  const AnimatedBackgroundWidget({
    super.key,
    this.speedMultiplier = 1.0,
  });

  @override
  State<AnimatedBackgroundWidget> createState() => _AnimatedBackgroundWidgetState();
}

class _AnimatedBackgroundWidgetState extends State<AnimatedBackgroundWidget>
    with TickerProviderStateMixin {
  final List<_ParticleController> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Generate 10 particles
    for (int i = 0; i < 10; i++) {
      final controller = _ParticleController(
        xPercent: _random.nextDouble(),
        size: _random.nextDouble() * 4 + 3,
        opacity: _random.nextDouble() * 0.25 + 0.1,
        durationSeconds: 18 + _random.nextInt(12),
        initialProgress: _random.nextDouble(), // Start at random position
        vsync: this,
        speedMultiplier: widget.speedMultiplier,
      );
      _particles.add(controller);
    }
  }

  @override
  void didUpdateWidget(AnimatedBackgroundWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speedMultiplier != widget.speedMultiplier) {
      for (final particle in _particles) {
        particle.updateSpeed(widget.speedMultiplier);
      }
    }
  }

  @override
  void dispose() {
    for (final particle in _particles) {
      particle.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: _particles.map((particle) {
          return _FloatingParticle(controller: particle);
        }).toList(),
      ),
    );
  }
}

class _ParticleController {
  final double xPercent;
  final double size;
  final double opacity;
  final int durationSeconds;
  late final AnimationController animationController;

  _ParticleController({
    required this.xPercent,
    required this.size,
    required this.opacity,
    required this.durationSeconds,
    required double initialProgress,
    required TickerProvider vsync,
    required double speedMultiplier,
  }) {
    final durationMs = (durationSeconds * 1000 / speedMultiplier).round();
    animationController = AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: durationMs),
    );
    // Start from random position and repeat
    animationController.value = initialProgress;
    animationController.repeat();
  }

  void updateSpeed(double speedMultiplier) {
    final durationMs = (durationSeconds * 1000 / speedMultiplier).round();
    animationController.duration = Duration(milliseconds: durationMs);
  }

  void dispose() {
    animationController.dispose();
  }
}

class _FloatingParticle extends StatelessWidget {
  final _ParticleController controller;

  const _FloatingParticle({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.animationController,
      builder: (context, child) {
        // Y goes from bottom (1.0) to top (0.0)
        final yPercent = 1.0 - controller.animationController.value;

        return Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: Align(
            alignment: FractionalOffset(controller.xPercent, yPercent),
            child: child,
          ),
        );
      },
      child: Container(
        width: controller.size * 2,
        height: controller.size * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.purple.withValues(alpha: controller.opacity),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: controller.opacity * 0.5),
              blurRadius: controller.size * 2,
              spreadRadius: controller.size * 0.5,
            ),
          ],
        ),
      ),
    );
  }
}
