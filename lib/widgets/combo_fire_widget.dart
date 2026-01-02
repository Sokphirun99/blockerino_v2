import 'package:flutter/material.dart';
import 'dart:math' as math;

class ComboFireWidget extends StatefulWidget {
  final int combo;
  final Widget child;

  const ComboFireWidget({
    super.key,
    required this.combo,
    required this.child,
  });

  @override
  State<ComboFireWidget> createState() => _ComboFireWidgetState();
}

class _ComboFireWidgetState extends State<ComboFireWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_FireParticle> _particles = [];
  final math.Random _random = math.Random();

  // Configuration based on intensity
  Color _baseColor = Colors.orange;
  Color _coreColor = Colors.yellow;
  double _intensity = 1.0;

  @override
  void initState() {
    super.initState();
    _updateConfig();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )
      ..addListener(_onAnimationTick)
      ..repeat();
  }

  void _onAnimationTick() {
    if (mounted && widget.combo > 1) {
      _tick();
      // Force rebuild to update the CustomPainter
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onAnimationTick);
    _controller.dispose();
    super.dispose();
  }

  void _updateConfig() {
    if (widget.combo < 5) {
      // Level 1: Standard Fire
      _baseColor = Colors.orange;
      _coreColor = Colors.yellow;
      _intensity = 1.0;
    } else if (widget.combo < 10) {
      // Level 2: Intense Red Fire
      _baseColor = Colors.red;
      _coreColor = Colors.orangeAccent;
      _intensity = 1.5;
    } else {
      // Level 3: Blue Plasma (God Mode)
      _baseColor = Colors.blue[900]!;
      _coreColor = Colors.cyanAccent;
      _intensity = 2.0;
    }
  }

  void _tick() {
    // Spawn new particles - reduced spawn rate
    final spawnCount = (_intensity).round();
    for (int i = 0; i < spawnCount; i++) {
      if (_particles.length < 40) {
        // Reduced max particles (100 -> 40)
        _particles.add(_FireParticle(
          x: (_random.nextDouble() - 0.5) * 50, // Slightly narrower
          y: 20,
          speed: (15 + _random.nextDouble() * 30) * _intensity,
          size: (3 + _random.nextDouble() * 4) * _intensity,
          angle: (_random.nextDouble() - 0.5) * 0.5,
          life: 0.6 + _random.nextDouble() * 0.3,
        ));
      }
    }

    // Update existing particles
    for (int i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.y -= p.speed * 0.025;
      p.x += math.sin(p.y * 0.05) * 0.4;
      p.life -= 0.03;
      p.size -= 0.08;

      if (p.life <= 0 || p.size <= 0) {
        _particles.removeAt(i);
      }
    }
  }

  @override
  void didUpdateWidget(ComboFireWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.combo != oldWidget.combo) {
      _updateConfig();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.combo <= 1) {
      return widget.child;
    }

    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // The Fire Painter (Behind)
          Positioned(
            top: -40,
            child: CustomPaint(
              painter: _FirePainter(
                particles: _particles,
                baseColor: _baseColor,
                coreColor: _coreColor,
              ),
              size: const Size(100, 100),
            ),
          ),
          // The Child (Combo Badge)
          widget.child,
        ],
      ),
    );
  }
}

class _FireParticle {
  double x;
  double y;
  double speed;
  double size;
  double angle;
  double life;

  _FireParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.angle,
    required this.life,
  });
}

class _FirePainter extends CustomPainter {
  final List<_FireParticle> particles;
  final Color baseColor;
  final Color coreColor;

  _FirePainter({
    required this.particles,
    required this.baseColor,
    required this.coreColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      if (p.life <= 0) continue;

      // Simplified color calculation
      final alpha = p.life.clamp(0.0, 1.0);
      paint.color = (p.life > 0.5 ? coreColor : baseColor).withValues(alpha: alpha);

      canvas.drawCircle(
        Offset(size.width / 2 + p.x, size.height / 2 + p.y),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FirePainter oldDelegate) {
    // Always repaint when animation ticks to show fire movement
    return true;
  }
}

/// A pulsing glow effect for high combos - optimized
class ComboGlowWidget extends StatefulWidget {
  final int comboLevel;
  final Widget child;

  const ComboGlowWidget({
    super.key,
    required this.comboLevel,
    required this.child,
  });

  @override
  State<ComboGlowWidget> createState() => _ComboGlowWidgetState();
}

class _ComboGlowWidgetState extends State<ComboGlowWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    // Slower animation for better performance
    _controller = AnimationController(
      duration: Duration(milliseconds: 1200 ~/ widget.comboLevel.clamp(1, 3)),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.comboLevel > 1) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ComboGlowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.comboLevel != oldWidget.comboLevel) {
      _controller.duration = Duration(
        milliseconds: 1200 ~/ widget.comboLevel.clamp(1, 3),
      );
      if (widget.comboLevel > 1) {
        if (!_controller.isAnimating) _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getGlowColor() {
    switch (widget.comboLevel) {
      case 2:
        return const Color(0xFFFFD700);
      case 3:
        return const Color(0xFFFFA500);
      case 4:
        return const Color(0xFFFF4500);
      case 5:
        return const Color(0xFFFF1493);
      default:
        return const Color(0xFF00FFFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.comboLevel <= 1) {
      return widget.child;
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: _getGlowColor().withValues(alpha: _glowAnimation.value * 0.5),
                  blurRadius: 12 + (_glowAnimation.value * 6),
                  spreadRadius: 1 + (_glowAnimation.value * 2),
                ),
              ],
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
