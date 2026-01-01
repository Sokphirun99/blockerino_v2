import 'package:flutter/material.dart';
import '../models/daily_mission.dart';

/// Widget to display a daily mission card with progress and claim button
class MissionCard extends StatelessWidget {
  final DailyMission mission;
  final Function(DailyMission) onClaim;

  const MissionCard({
    super.key,
    required this.mission,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    // Choose colors based on mission state
    final List<Color> gradientColors;
    final Color borderColor;
    final Color shadowColor;

    if (mission.isCompleted) {
      // Completed - green
      gradientColors = [const Color(0xFF4ade80), const Color(0xFF22c55e)];
      borderColor = const Color(0xFF4ade80);
      shadowColor = const Color(0xFF22c55e).withValues(alpha: 0.3);
    } else if (mission.canClaim) {
      // Can claim - gold
      gradientColors = [const Color(0xFFFFD700), const Color(0xFFFFA500)];
      borderColor = const Color(0xFFFFD700);
      shadowColor = const Color(0xFFFFD700).withValues(alpha: 0.4);
    } else {
      // In progress - dark
      gradientColors = [const Color(0xFF2d2d44), const Color(0xFF1a1a2e)];
      borderColor = const Color(0xFF3d3d54);
      shadowColor = Colors.black.withValues(alpha: 0.3);
    }

    // Get mission icon based on type
    final String icon = _getMissionIcon(mission.type);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: icon + title/desc + coin reward
          Row(
            children: [
              // Mission icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      style: TextStyle(
                        color: mission.isCompleted || mission.canClaim
                            ? Colors.white
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mission.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Coin reward
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      '${mission.coinReward}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress section (if not completed)
          if (!mission.isCompleted) ...[
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: mission.progressPercentage,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  mission.canClaim
                      ? Colors.white
                      : const Color(0xFF4ade80),
                ),
                minHeight: 8,
              ),
            ),

            const SizedBox(height: 8),

            // Progress text and claim button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Progress text
                Text(
                  '${mission.progress}/${mission.target}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                // Claim button (if canClaim)
                if (mission.canClaim)
                  ElevatedButton(
                    onPressed: () => onClaim(mission),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFFFD700),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'CLAIM REWARD',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ] else ...[
            // Completed state
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('✅', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Text(
                      'COMPLETED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Get icon for mission type
  String _getMissionIcon(MissionType type) {
    switch (type) {
      case MissionType.clearLines:
        return '🎯';
      case MissionType.earnScore:
        return '💯';
      case MissionType.perfectClears:
        return '✨';
      case MissionType.longCombo:
        return '🔥';
      case MissionType.playGames:
        return '🎮';
      case MissionType.useChaosMode:
        return '🌪️';
    }
  }
}
