import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Overlay widget that manages floating score animations
/// Wraps content and displays animated score popups
class FloatingScoreOverlay extends StatefulWidget {
  final Widget child;

  const FloatingScoreOverlay({
    super.key,
    required this.child,
  });

  @override
  State<FloatingScoreOverlay> createState() => FloatingScoreOverlayState();
}

class FloatingScoreOverlayState extends State<FloatingScoreOverlay> {
  final List<_ScoreEntry> _entries = [];

  /// Show a floating score at the specified position
  void showScore(Offset position, int points) {
    if (!mounted) return;
    setState(() {
      _entries.add(_ScoreEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        position: position,
        points: points,
      ));
    });
  }

  void _removeEntry(String id) {
    if (!mounted) return;
    setState(() {
      _entries.removeWhere((element) => element.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ..._entries.map((entry) => Positioned(
              left: entry.position.dx - 50, // Center horizontally (approx)
              top: entry.position.dy,
              child: _AnimatedScore(
                key: ValueKey(entry.id),
                points: entry.points,
                onComplete: () => _removeEntry(entry.id),
              ),
            )),
      ],
    );
  }
}

/// Internal data class for score entries
class _ScoreEntry {
  final String id;
  final Offset position;
  final int points;

  _ScoreEntry({
    required this.id,
    required this.position,
    required this.points,
  });
}

/// Animated score widget that floats up and fades out
class _AnimatedScore extends StatelessWidget {
  final int points;
  final VoidCallback onComplete;

  const _AnimatedScore({
    super.key,
    required this.points,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Text(
        '+$points',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    )
        .animate(onComplete: (controller) => onComplete())
        .moveY(begin: 0, end: -50, duration: 800.ms, curve: Curves.easeOut)
        .fadeOut(begin: 1.0, duration: 800.ms, curve: Curves.easeIn);
  }
}
