import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/story_level.dart';
import '../models/game_mode.dart';
import '../providers/settings_provider.dart';
import 'game_screen.dart';

class StoryModeScreen extends StatelessWidget {
  const StoryModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Story Mode', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1a1a2e),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF0f0f1e)],
          ),
        ),
        child: Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return Column(
              children: [
                _buildProgressHeader(settings),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: StoryLevel.allLevels.length,
                    itemBuilder: (context, index) {
                      final level = StoryLevel.allLevels[index];
                      final isUnlocked = settings.isStoryLevelUnlocked(level.levelNumber);
                      final stars = settings.getStarsForLevel(level.levelNumber);
                      
                      return _buildLevelCard(context, level, isUnlocked, stars, settings);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressHeader(SettingsProvider settings) {
    final totalStars = settings.totalStarsEarned;
    final maxStars = StoryLevel.allLevels.length * 3;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9d4edd), Color(0xFF7b2cbf)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9d4edd).withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Your Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Color(0xFFffd700), size: 32),
              const SizedBox(width: 8),
              Text(
                '$totalStars / $maxStars',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: totalStars / maxStars,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFffd700)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context, StoryLevel level, bool isUnlocked, int stars, SettingsProvider settings) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isUnlocked
              ? [const Color(0xFF2d2d44).withValues(alpha: 0.8), const Color(0xFF1a1a2e).withValues(alpha: 0.9)]
              : [const Color(0xFF1a1a1a).withValues(alpha: 0.5), const Color(0xFF0a0a0a).withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked ? _getDifficultyColor(level.difficulty) : Colors.white.withValues(alpha: 0.1),
          width: 2,
        ),
        boxShadow: [
          if (isUnlocked)
            BoxShadow(
              color: _getDifficultyColor(level.difficulty).withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(level.difficulty),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Level ${level.levelNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildDifficultyBadge(level.difficulty),
                    const Spacer(),
                    if (isUnlocked) _buildStarDisplay(stars),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  level.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? Colors.white : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  level.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isUnlocked ? Colors.white.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                if (isUnlocked) ...[
                  const SizedBox(height: 12),
                  Text(
                    level.story,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLevelInfo(level),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 4),
                      Text(
                        '+${level.coinReward}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFffd700),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GameScreen(storyLevel: level),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getDifficultyColor(level.difficulty),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'PLAY',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (!isUnlocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Icon(Icons.lock, size: 48, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(LevelDifficulty difficulty) {
    String text;
    Color color;
    
    switch (difficulty) {
      case LevelDifficulty.easy:
        text = 'Easy';
        color = const Color(0xFF52b788);
        break;
      case LevelDifficulty.medium:
        text = 'Medium';
        color = const Color(0xFFffa500);
        break;
      case LevelDifficulty.hard:
        text = 'Hard';
        color = const Color(0xFFff6b35);
        break;
      case LevelDifficulty.expert:
        text = 'Expert';
        color = const Color(0xFFff006e);
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color _getDifficultyColor(LevelDifficulty difficulty) {
    switch (difficulty) {
      case LevelDifficulty.easy:
        return const Color(0xFF52b788);
      case LevelDifficulty.medium:
        return const Color(0xFFffa500);
      case LevelDifficulty.hard:
        return const Color(0xFFff6b35);
      case LevelDifficulty.expert:
        return const Color(0xFFff006e);
    }
  }

  Widget _buildStarDisplay(int stars) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Icon(
          index < stars ? Icons.star : Icons.star_border,
          color: const Color(0xFFffd700),
          size: 24,
        );
      }),
    );
  }

  Widget _buildLevelInfo(StoryLevel level) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildInfoChip(Icons.emoji_events, 'Target: ${level.targetScore}'),
        if (level.targetLines != null)
          _buildInfoChip(Icons.view_column, '${level.targetLines} lines'),
        if (level.timeLimit != null)
          _buildInfoChip(Icons.timer, '${level.timeLimit}s'),
        _buildInfoChip(
          Icons.sports_esports,
          level.gameMode == GameMode.classic ? 'Classic' : 'Chaos',
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF9d4edd).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF9d4edd)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
