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
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Create 8-12 particles per block
    final particleCount = 8 + _random.nextInt(5);
    _particles = List.generate(particleCount, (index) {
      final angle = (index / particleCount) * 2 * math.pi + _random.nextDouble() * 0.5;
      final speed = 50 + _random.nextDouble() * 100;
      final size = 3 + _random.nextDouble() * 4;
      return Particle(
        angle: angle,
        speed: speed,
        size: size,
        rotationSpeed: _random.nextDouble() * 4 - 2,
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
    return AnimatedBuilder(
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
    for (final particle in particles) {
      // Calculate position with easing
      final easedProgress = Curves.easeOut.transform(progress);
      final distance = particle.speed * easedProgress;
      
      final x = centerX + math.cos(particle.angle) * distance;
      final y = centerY + math.sin(particle.angle) * distance + (50 * progress * progress); // Gravity
      
      // Fade out and shrink
      final opacity = 1.0 - progress;
      final currentSize = particle.size * (1.0 - progress * 0.5);
      
      final paint = Paint()
        ..color = baseColor.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Draw particle as small square (like block pieces)
      final rotation = particle.rotationSpeed * progress * math.pi;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: currentSize, height: currentSize),
        paint,
      );
      canvas.restore();
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

  void addParticles(List<ParticleSpawnInfo> spawns) {
    if (!mounted) return;
    setState(() {
      for (final spawn in spawns) {
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
