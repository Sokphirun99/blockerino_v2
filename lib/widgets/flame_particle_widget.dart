import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'dart:math' as math;

/// Flame-based animation widgets for enhanced particle effects
///
/// These widgets use Flutter Flame for better performance with complex animations.
///
/// Usage examples:
///
/// 1. Particle effect for block clearing:
/// ```dart
/// FlameParticleWidget(
///   position: Offset(x, y),
///   color: Colors.blue,
///   blockSize: 40.0,
///   particleCount: 15,
///   onComplete: () => print('Animation done'),
/// )
/// ```
///
/// 2. Combo fire effect (alternative to ComboFireWidget):
/// ```dart
/// FlameComboFireWidget(
///   combo: 5,
///   child: Text('COMBO x5!'),
/// )
/// ```
class FlameParticleWidget extends StatefulWidget {
  final Offset position;
  final Color color;
  final VoidCallback onComplete;
  final double blockSize;
  final int particleCount;

  const FlameParticleWidget({
    super.key,
    required this.position,
    required this.color,
    required this.onComplete,
    required this.blockSize,
    this.particleCount = 12,
  });

  @override
  State<FlameParticleWidget> createState() => _FlameParticleWidgetState();
}

class _FlameParticleWidgetState extends State<FlameParticleWidget> {
  late FlameGame _game;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _game = _ParticleGame(
      position: widget.position,
      color: widget.color,
      blockSize: widget.blockSize,
      particleCount: widget.particleCount,
      onComplete: () {
        if (!_isDisposed && mounted) {
          widget.onComplete();
        }
      },
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _game.removeAll(_game.children);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameWidget<FlameGame>.controlled(
      gameFactory: () => _game,
    );
  }
}

/// Flame game instance for particle effects
class _ParticleGame extends FlameGame {
  final Offset position;
  final Color color;
  final double blockSize;
  final int particleCount;
  final VoidCallback onComplete;

  _ParticleGame({
    required this.position,
    required this.color,
    required this.blockSize,
    required this.particleCount,
    required this.onComplete,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _createParticles();
  }

  void _createParticles() {
    final random = math.Random();

    for (int i = 0; i < particleCount; i++) {
      final angle =
          (i / particleCount) * 2 * math.pi + random.nextDouble() * 0.5;
      final speed = 50 + random.nextDouble() * 100;
      final size = 3 + random.nextDouble() * 4;

      final particle = _ParticleComponent(
        startPosition: Vector2(position.dx, position.dy),
        angle: angle,
        speed: speed,
        size: size,
        color: color,
        onComplete: i == 0 ? onComplete : null, // Only call once
      );

      add(particle);
    }
  }
}

/// Individual particle component using Flame
class _ParticleComponent extends PositionComponent with HasGameRef {
  final Vector2 startPosition;
  final double angle;
  final double speed;
  final double particleSize;
  final Color color;
  final VoidCallback? onComplete;

  _ParticleComponent({
    required this.startPosition,
    required this.angle,
    required this.speed,
    required double size,
    required this.color,
    this.onComplete,
  }) : particleSize = size;

  @override
  Future<void> onLoad() async {
    position = startPosition;
    size.setValues(particleSize, particleSize);
    anchor = Anchor.center;

    // Create fade out and move effect
    final targetPosition = Vector2(
      startPosition.x + math.cos(angle) * speed,
      startPosition.y + math.sin(angle) * speed + 50, // Gravity
    );

    // Move and fade out animation
    add(
      MoveEffect.to(
        targetPosition,
        EffectController(duration: 0.6),
      ),
    );

    add(
      OpacityEffect.to(
        0.0,
        EffectController(duration: 0.6),
        onComplete: () {
          if (onComplete != null && parent != null) {
            onComplete!();
          }
          removeFromParent();
        },
      ),
    );

    // Scale down effect
    add(
      ScaleEffect.to(
        Vector2.zero(),
        EffectController(duration: 0.6),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    // Draw particle as a colored rectangle (like block pieces)
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(-size.x / 2, -size.y / 2, size.x, size.y),
      paint,
    );
  }
}

/// Flame-based combo fire effect widget
/// More efficient than CustomPaint for many particles
class FlameComboFireWidget extends StatefulWidget {
  final int combo;
  final Widget child;

  const FlameComboFireWidget({
    super.key,
    required this.combo,
    required this.child,
  });

  @override
  State<FlameComboFireWidget> createState() => _FlameComboFireWidgetState();
}

class _FlameComboFireWidgetState extends State<FlameComboFireWidget> {
  late FlameGame _game;

  @override
  void initState() {
    super.initState();
    _game = _ComboFireGame(combo: widget.combo);
  }

  @override
  void didUpdateWidget(FlameComboFireWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.combo != widget.combo) {
      _game.removeAll(_game.children);
      (_game as _ComboFireGame).updateCombo(widget.combo);
    }
  }

  @override
  void dispose() {
    _game.removeAll(_game.children);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.combo < 3) {
      return widget.child;
    }

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Flame particles behind text
        Positioned.fill(
          child: GameWidget<FlameGame>.controlled(
            gameFactory: () => _game,
          ),
        ),
        // Text on top
        widget.child,
      ],
    );
  }
}

/// Flame game for combo fire effect
class _ComboFireGame extends FlameGame {
  int combo;

  _ComboFireGame({required this.combo});

  void updateCombo(int newCombo) {
    combo = newCombo;
    _createFireParticles();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _createFireParticles();
  }

  void _createFireParticles() {
    final random = math.Random();
    final particleCount = (combo * 3).clamp(15, 40);

    for (int i = 0; i < particleCount; i++) {
      final fireParticle = _FireParticleComponent(
        startX: random.nextDouble(),
        startY: 1.0 + random.nextDouble() * 0.3,
        speed: 0.4 + random.nextDouble() * 0.5,
        size: 0.08 + random.nextDouble() * 0.12,
        phase: random.nextDouble(),
        horizontalDrift: (random.nextDouble() - 0.5) * 0.4,
        comboLevel: combo,
      );

      add(fireParticle);
    }
  }
}

/// Fire particle component for combo effect
class _FireParticleComponent extends PositionComponent with HasGameRef {
  final double startX;
  final double startY;
  final double speed;
  final double particleSize;
  final double phase;
  final double horizontalDrift;
  final int comboLevel;

  double _time = 0.0;

  _FireParticleComponent({
    required this.startX,
    required this.startY,
    required this.speed,
    required double size,
    required this.phase,
    required this.horizontalDrift,
    required this.comboLevel,
  }) : particleSize = size;

  @override
  Future<void> onLoad() async {
    size.setValues(1, 1); // Will be scaled in render
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Update position based on time
    final progress = (_time * 2.0 + phase) % 1.0;
    final gameSize = gameRef.size;

    // Vertical movement (bottom to top)
    final y = gameSize.y * (startY - (progress * speed * 1.2));

    // Horizontal drift
    final horizontalOffset =
        math.sin(progress * math.pi * 3) * horizontalDrift * gameSize.x;
    final x = gameSize.x * startX + horizontalOffset;

    position.setValues(x, y);

    // Remove if out of bounds
    if (y < -gameSize.y * 0.3 || y > gameSize.y * 1.3) {
      // Reset to bottom
      _time = 0.0;
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = (_time * 2.0 + phase) % 1.0;
    final gameSize = gameRef.size;

    // Calculate particle lifecycle
    double lifeProgress;
    if (progress < 0.2) {
      lifeProgress = progress / 0.2;
    } else if (progress < 0.8) {
      lifeProgress = 1.0;
    } else {
      lifeProgress = 1.0 - ((progress - 0.8) / 0.2);
    }

    // Fire color transition
    Color color;
    final baseOpacity = comboLevel >= 10
        ? 0.85
        : comboLevel >= 7
            ? 0.9
            : 0.95;

    if (progress < 0.4) {
      color = Color.lerp(
        const Color(0xFFFFD700).withOpacity(baseOpacity * lifeProgress),
        const Color(0xFFFF8C00).withOpacity(baseOpacity * lifeProgress),
        progress / 0.4,
      )!;
    } else if (progress < 0.7) {
      color = Color.lerp(
        const Color(0xFFFF8C00).withOpacity(baseOpacity * lifeProgress * 0.95),
        const Color(0xFFFF4500).withOpacity(baseOpacity * lifeProgress * 0.85),
        (progress - 0.4) / 0.3,
      )!;
    } else {
      color = Color.lerp(
        const Color(0xFFFF4500).withOpacity(baseOpacity * lifeProgress * 0.85),
        const Color(0xFFFF4500).withOpacity(baseOpacity * lifeProgress * 0.4),
        (progress - 0.7) / 0.3,
      )!;
    }

    final renderSize = gameSize.x * particleSize * (1.0 - progress * 0.15);

    // Draw particle with glow
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(Offset.zero, renderSize, paint);

    // Add glow effects
    if (lifeProgress > 0.3) {
      final glowPaint = Paint()
        ..color = color.withOpacity(color.opacity * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawCircle(Offset.zero, renderSize * 2.5, glowPaint);

      if (lifeProgress > 0.6) {
        final outerGlowPaint = Paint()
          ..color = color.withOpacity(color.opacity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
        canvas.drawCircle(Offset.zero, renderSize * 4.0, outerGlowPaint);
      }
    }
  }
}
