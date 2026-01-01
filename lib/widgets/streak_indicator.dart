import 'package:flutter/material.dart';
import '../models/daily_streak.dart';

/// Widget to display daily streak with animation
class StreakIndicator extends StatefulWidget {
  final DailyStreak streak;
  final bool compact;

  const StreakIndicator({
    super.key,
    required this.streak,
    this.compact = false,
  });

  @override
  State<StreakIndicator> createState() => _StreakIndicatorState();
}

class _StreakIndicatorState extends State<StreakIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Setup pulse animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Start repeating animation
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompact();
    }
    return _buildNormal();
  }

  Widget _buildCompact() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9500), Color(0xFFFF6B00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9500).withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              '${widget.streak.icon} ${widget.streak.currentStreak} 🔥',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNormal() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9500), Color(0xFFFF6B00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9500).withValues(alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Streak icon
                Text(
                  widget.streak.icon,
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),

                // Streak info
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.streak.currentStreak} DAY STREAK',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '×${widget.streak.rewardMultiplier.toStringAsFixed(1)} coin bonus',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Fire emoji
                const Text(
                  '🔥',
                  style: TextStyle(fontSize: 24),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
