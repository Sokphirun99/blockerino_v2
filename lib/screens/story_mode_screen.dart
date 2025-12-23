import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/story_level.dart';
import '../models/game_mode.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';
import 'game_screen.dart';
import '../widgets/common_card_widget.dart';
import '../widgets/shared_ui_components.dart';

class StoryModeScreen extends StatefulWidget {
  const StoryModeScreen({super.key});

  @override
  State<StoryModeScreen> createState() => _StoryModeScreenState();
}

class _StoryModeScreenState extends State<StoryModeScreen> {
  bool _analyticsLogged = false;
  AudioPlayer? _bgmPlayer;
  bool _bgmStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_analyticsLogged) {
      _analyticsLogged = true;
      final settings = context.read<SettingsCubit>();
      settings.analyticsService.logScreenView('story_mode');
    }
    _startBackgroundMusicIfNeeded();
  }

  Future<void> _startBackgroundMusicIfNeeded() async {
    if (_bgmStarted) return;
    _bgmStarted = true;
    try {
      _bgmPlayer ??= AudioPlayer();
      await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer!.play(AssetSource('audio/story_loop.mp3'), volume: 0.5);
    } catch (_) {}
  }

  @override
  void dispose() {
    _bgmPlayer?.stop();
    _bgmPlayer?.dispose();
    _bgmPlayer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Story Mode',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1a1a2e),
      ),
      body: GameGradientBackground(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            final settings = context.read<SettingsCubit>();
            return Column(
              children: [
                _buildProgressHeader(state),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: StoryLevel.allLevels.length,
                    itemBuilder: (context, index) {
                      final level = StoryLevel.allLevels[index];
                      final isUnlocked = index == 0 ||
                          (state.storyLevelStars[level.levelNumber] ?? 0) > 0 ||
                          level.levelNumber <= state.currentStoryLevel;
                      final stars =
                          state.storyLevelStars[level.levelNumber] ?? 0;

                      return _buildLevelCard(
                          context, level, isUnlocked, stars, settings);
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

  Widget _buildProgressHeader(SettingsState state) {
    final totalStars =
        state.storyLevelStars.values.fold(0, (sum, stars) => sum + stars);
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
              value: maxStars > 0 ? totalStars / maxStars : 0.0,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFffd700)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context, StoryLevel level,
      bool isUnlocked, int stars, SettingsCubit settings) {
    return GradientCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 20,
      gradientColors: isUnlocked
          ? [
              const Color(0xFF2d2d44).withValues(alpha: 0.8),
              const Color(0xFF1a1a2e).withValues(alpha: 0.9)
            ]
          : [
              const Color(0xFF1a1a1a).withValues(alpha: 0.5),
              const Color(0xFF0a0a0a).withValues(alpha: 0.7)
            ],
      borderColor: isUnlocked
          ? _getDifficultyColor(level.difficulty)
          : Colors.white.withValues(alpha: 0.1),
      borderWidth: 2,
      boxShadow: isUnlocked
          ? [
              BoxShadow(
                color: _getDifficultyColor(level.difficulty).withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ]
          : null,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
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
                const SizedBox(height: 8),
                Text(
                  level.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  level.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isUnlocked
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.2),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isUnlocked) ...[
                  const SizedBox(height: 8),
                  Text(
                    level.story,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  _buildLevelInfo(level),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      RewardDisplay(coins: level.coinReward),
                      const Spacer(),
                      Builder(
                        builder: (context) {
                          final responsive = ResponsiveUtil(context);
                          return ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      GameScreen(storyLevel: level),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _getDifficultyColor(level.difficulty),
                              foregroundColor: Colors.white,
                              padding: responsive.horizontalPadding(mobile: 16),
                              minimumSize: Size(
                                responsive.isMobile
                                    ? 60
                                    : responsive.isTablet
                                        ? 80
                                        : 100,
                                responsive.isMobile
                                    ? 30
                                    : responsive.isTablet
                                        ? 36
                                        : 42,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              'PLAY',
                              style: TextStyle(
                                fontSize: responsive.fontSize(12, 14, 16),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
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
