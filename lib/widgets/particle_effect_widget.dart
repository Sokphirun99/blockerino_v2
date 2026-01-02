import 'package:flutter/material.dart';
import 'dart:math' as math;

class ParticleEffectWidget extends StatefulWidget {
  final Offset position;
  final Color color;
  final VoidCallback onComplete;
  final double blockSize;

  const ParticleEffectWidget({
    super.key,
    required this.position,
    required this.color,
    required this.onComplete,
    required this.blockSize,
  });

  @override
  State<ParticleEffectWidget> createState() => _ParticleEffectWidgetState();
}

class _ParticleEffectWidgetState extends State<ParticleEffectWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500), // Slightly shorter
      vsync: this,
    );

    // Reduced particle count (8-12 -> 5-7) for better performance
    final particleCount = 5 + _random.nextInt(3);
    _particles = List.generate(particleCount, (index) {
      final angle = (index / particleCount) * 2 * math.pi + _random.nextDouble() * 0.5;
      final speed = 40 + _random.nextDouble() * 60; // Reduced speed range
      final size = 3 + _random.nextDouble() * 3;
      return Particle(
        angle: angle,
        speed: speed,
        size: size,
        rotationSpeed: _random.nextDouble() * 2 - 1,
      );
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
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

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: ParticlePainter(
              particles: _particles,
              progress: _controller.value,
              baseColor: widget.color,
              centerX: widget.position.dx,
              centerY: widget.position.dy,
            ),
          );
        },
      ),
    );
  }
}

class Particle {
  final double angle;
  final double speed;
  final double size;
  final double rotationSpeed;

  Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.rotationSpeed,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final Color baseColor;
  final double centerX;
  final double centerY;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.baseColor,
    required this.centerX,
    required this.centerY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final easedProgress = Curves.easeOut.transform(progress);

    for (final particle in particles) {
      final distance = particle.speed * easedProgress;

      final x = centerX + math.cos(particle.angle) * distance;
      final y = centerY + math.sin(particle.angle) * distance + (40 * progress * progress);

      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final currentSize = particle.size * (1.0 - progress * 0.5);

      paint.color = baseColor.withValues(alpha: opacity);

      // Simplified: draw circles instead of rotated squares
      canvas.drawCircle(Offset(x, y), currentSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Overlay to manage multiple particle effects
class ParticleOverlay extends StatefulWidget {
  final Widget child;

  const ParticleOverlay({super.key, required this.child});

  static ParticleOverlayState? of(BuildContext context) {
    return context.findAncestorStateOfType<ParticleOverlayState>();
  }

  @override
  State<ParticleOverlay> createState() => ParticleOverlayState();
}

class ParticleOverlayState extends State<ParticleOverlay> {
  final List<ParticleData> _activeParticles = [];
  int _particleIdCounter = 0;
  static const int _maxActiveParticles = 20; // Limit concurrent particles

  void addParticles(List<ParticleSpawnInfo> spawns) {
    if (!mounted) return;

    // Limit total active particles
    final availableSlots = _maxActiveParticles - _activeParticles.length;
    if (availableSlots <= 0) return;

    final spawnsToAdd = spawns.take(availableSlots);

    setState(() {
      for (final spawn in spawnsToAdd) {
        _activeParticles.add(ParticleData(
          id: _particleIdCounter++,
          position: spawn.position,
          color: spawn.color,
        ));
      }
    });
  }

  void _removeParticle(int id) {
    if (!mounted) return;
    setState(() {
      _activeParticles.removeWhere((p) => p.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ..._activeParticles.map((particle) => Positioned.fill(
          child: ParticleEffectWidget(
            key: ValueKey(particle.id),
            position: particle.position,
            color: particle.color,
            blockSize: 20,
            onComplete: () => _removeParticle(particle.id),
          ),
        )),
      ],
    );
  }
}

class ParticleData {
  final int id;
  final Offset position;
  final Color color;

  ParticleData({
    required this.id,
    required this.position,
    required this.color,
  });
}

class ParticleSpawnInfo {
  final Offset position;
  final Color color;

  ParticleSpawnInfo({
    required this.position,
    required this.color,
  });
}
