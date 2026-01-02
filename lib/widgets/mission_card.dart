import 'package:flutter/material.dart';
import '../models/daily_mission.dart';
import 'shared_ui_components.dart';

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
    final responsive = ResponsiveUtil(context);
    
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

    return InkWell(
      onTap: () => _showMissionDetails(context, mission, responsive),
      borderRadius: BorderRadius.circular(responsive.value(16, tablet: 20)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.only(bottom: responsive.value(8, tablet: 12)),
        padding: EdgeInsets.all(responsive.value(16, tablet: 24)),
        decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(responsive.value(16, tablet: 20)),
        border: Border.all(
          color: borderColor,
          width: responsive.value(2, tablet: 3),
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
                width: responsive.value(40, tablet: 56),
                height: responsive.value(40, tablet: 56),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(responsive.value(10, tablet: 14)),
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: TextStyle(fontSize: responsive.fontSize(20, 28, 32)),
                  ),
                ),
              ),
              SizedBox(width: responsive.value(10, tablet: 16)),

              // Title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mission.title,
                      style: TextStyle(
                        color: mission.isCompleted || mission.canClaim
                            ? Colors.white
                            : Colors.white,
                        fontSize: responsive.fontSize(14, 18, 20),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: responsive.value(2, tablet: 4)),
                    Text(
                      mission.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: responsive.fontSize(11, 14, 16),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Coin reward
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.value(10, tablet: 16), 
                  vertical: responsive.value(4, tablet: 8),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(responsive.value(16, tablet: 20)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🪙', style: TextStyle(fontSize: responsive.fontSize(14, 18, 22))),
                    SizedBox(width: responsive.value(4, tablet: 6)),
                    Text(
                      '${mission.coinReward}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsive.fontSize(12, 16, 18),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: responsive.value(10, tablet: 16)),

          // Progress section (if not completed)
          if (!mission.isCompleted) ...[
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(responsive.value(4, tablet: 6)),
              child: LinearProgressIndicator(
                value: mission.progressPercentage,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  mission.canClaim
                      ? Colors.white
                      : const Color(0xFF4ade80),
                ),
                minHeight: responsive.value(8, tablet: 12),
              ),
            ),

            SizedBox(height: responsive.value(8, tablet: 12)),

            // Progress text and claim button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Progress text - Flexible to prevent overflow
                Flexible(
                  child: Text(
                    '${mission.progress}/${mission.target}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: responsive.fontSize(14, 16, 18),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                SizedBox(width: responsive.value(8, tablet: 12)),

                // Claim button (if canClaim) - wrapped to prevent card tap
                if (mission.canClaim)
                  GestureDetector(
                    onTap: () {}, // Prevents tap from bubbling to card
                    child: ElevatedButton(
                      onPressed: () => onClaim(mission),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFFD700),
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.value(16, tablet: 20),
                          vertical: responsive.value(8, tablet: 12),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'CLAIM',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: responsive.fontSize(12, 14, 16),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ] else ...[
            // Completed state
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('✅', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'COMPLETED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  /// Show mission details dialog
  void _showMissionDetails(BuildContext context, DailyMission mission, ResponsiveUtil responsive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.value(20, tablet: 24)),
        ),
        title: Row(
          children: [
            Text(
              _getMissionIcon(mission.type),
              style: TextStyle(fontSize: responsive.fontSize(24, 30, 36)),
            ),
            SizedBox(width: responsive.value(12, tablet: 16)),
            Expanded(
              child: Text(
                mission.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: responsive.fontSize(18, 22, 26),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Text(
              mission.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: responsive.fontSize(14, 18, 20),
                height: 1.5,
              ),
            ),
            SizedBox(height: responsive.value(16, tablet: 24)),
            
            // Progress
            Container(
              padding: EdgeInsets.all(responsive.value(12, tablet: 16)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(responsive.value(12, tablet: 16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: responsive.fontSize(12, 16, 18),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: responsive.value(8, tablet: 12)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${mission.progress} / ${mission.target}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: responsive.fontSize(16, 20, 24),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${(mission.progressPercentage * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: const Color(0xFFFFD700),
                          fontSize: responsive.fontSize(16, 20, 24),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.value(8, tablet: 12)),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(responsive.value(4, tablet: 6)),
                    child: LinearProgressIndicator(
                      value: mission.progressPercentage,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                      minHeight: responsive.value(8, tablet: 12),
                    ),
                  ),
                ],
              ),
            ),
            
            // Reward
            SizedBox(height: responsive.value(16, tablet: 24)),
            Container(
              padding: EdgeInsets.all(responsive.value(12, tablet: 16)),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(responsive.value(12, tablet: 16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🪙', style: TextStyle(fontSize: responsive.fontSize(20, 26, 32))),
                  SizedBox(width: responsive.value(8, tablet: 12)),
                  Flexible(
                    child: Text(
                      'Reward: ${mission.coinReward} Coins',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: responsive.fontSize(16, 20, 24),
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CLOSE',
              style: TextStyle(
                color: const Color(0xFFFFD700),
                fontSize: responsive.fontSize(14, 18, 20),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
