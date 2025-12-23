import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:gap/gap.dart';
import '../cubits/game/game_cubit.dart';
import '../cubits/game/game_state.dart';
import '../cubits/settings/settings_cubit.dart';
import '../models/game_mode.dart';
import '../services/app_localizations.dart';
import 'combo_fire_widget.dart';

class GameHudWidget extends StatefulWidget {
  const GameHudWidget({super.key});

  @override
  State<GameHudWidget> createState() => _GameHudWidgetState();
}

class _GameHudWidgetState extends State<GameHudWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _comboAnimationController;
  late Animation<double> _comboScaleAnimation;
  late Animation<double> _comboGlowAnimation;
  int _lastCombo = 0;

  @override
  void initState() {
    super.initState();
    _comboAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _comboScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.4, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_comboAnimationController);

    _comboGlowAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _comboAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _comboAnimationController.dispose();
    super.dispose();
  }

  void _triggerComboAnimation(int newCombo) {
    if (newCombo > _lastCombo) {
      _comboAnimationController.forward(from: 0.0);
    }
    _lastCombo = newCombo;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  /// Get score text color based on combo level
  Color _getComboScoreColor(int combo) {
    switch (combo) {
      case 2:
        return const Color(0xFFFFD700); // Gold
      case 3:
        return const Color(0xFFFFA500); // Orange
      case 4:
        return const Color(0xFFFF4500); // Red-Orange
      case 5:
        return const Color(0xFFFF1493); // Deep Pink
      default:
        return const Color(0xFF00FFFF); // Cyan (max combo)
    }
  }

  bool _areObjectivesMet(GameInProgress gameState) {
    if (gameState.storyLevel == null) return false;
    final level = gameState.storyLevel!;

    final scoreComplete = gameState.score >= level.targetScore;
    final linesComplete = level.targetLines == null ||
        gameState.linesCleared >= level.targetLines!;

    return scoreComplete && linesComplete;
  }

  Widget _buildObjective(String text, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (completed)
            const Icon(Icons.check_circle, color: Color(0xFF52b788), size: 12)
          else
            Icon(Icons.circle_outlined,
                color: Colors.white.withValues(alpha: 0.5), size: 12),
          const SizedBox(width: 4),
          Flexible(
            child: AutoSizeText(
              text,
              style: TextStyle(
                color: completed ? const Color(0xFF52b788) : Colors.white,
                fontSize: 10,
                fontWeight: completed ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              minFontSize: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, gameState) {
        if (gameState is! GameInProgress) return const SizedBox.shrink();

        // Trigger animation when combo changes
        if (gameState.combo != _lastCombo) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _triggerComboAnimation(gameState.combo);
          });
        }

        final settings = context.watch<SettingsCubit>().state;
        final config = GameModeConfig.fromMode(gameState.gameMode);
        final movesLeft = config.handSize - gameState.lastBrokenLine;
        final comboProgress =
            gameState.combo > 0 ? movesLeft / config.handSize : 0.0;
        final isNewHighScore = gameState.score > settings.highScore;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Story mode: Show time limit and objectives
            if (gameState.storyLevel != null) ...[
              // Time limit (if applicable)
              if (gameState.timeRemaining >= 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gameState.timeRemaining <= 10
                          ? [const Color(0xFFFF6B6B), const Color(0xFFFF4757)]
                          : [const Color(0xFF9d4edd), const Color(0xFF7b2cbf)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (gameState.timeRemaining <= 10
                                ? const Color(0xFFFF6B6B)
                                : const Color(0xFF9d4edd))
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(gameState.timeRemaining),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // Objectives display
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).translate('objectives'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (gameState.storyLevel!.targetScore > 0)
                      _buildObjective(
                        '🎯 ${AppLocalizations.of(context).translate('score_label')} ${gameState.score}/${gameState.storyLevel!.targetScore}',
                        gameState.score >= gameState.storyLevel!.targetScore,
                      ),
                    if (gameState.storyLevel!.targetLines != null)
                      _buildObjective(
                        '📊 ${AppLocalizations.of(context).translate('lines_label')} ${gameState.linesCleared}/${gameState.storyLevel!.targetLines}',
                        gameState.linesCleared >=
                            gameState.storyLevel!.targetLines!,
                      ),
                    // Show COMPLETE button when objectives are met
                    if (_areObjectivesMet(gameState)) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<GameCubit>().completeStoryLevel();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF52b788),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context).translate('complete'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            // High score indicator
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  color:
                      isNewHighScore ? const Color(0xFFFFE66D) : Colors.white38,
                  size: 12,
                ),
                const Gap(4),
                Flexible(
                  child: AutoSizeText(
                    '${isNewHighScore ? gameState.score : settings.highScore}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isNewHighScore
                              ? const Color(0xFFFFE66D)
                              : Colors.white38,
                          fontSize: 10,
                        ),
                    maxLines: 1,
                    minFontSize: 8,
                  ),
                ),
              ],
            ),
            const Gap(2),
            Text(
              AppLocalizations.of(context).translate('score').toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
            ),
            // Score with combo fire effect
            ComboFireWidget(
              combo: gameState.combo,
              child: ComboGlowWidget(
                comboLevel: gameState.combo,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: AutoSizeText(
                    '${gameState.score}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: gameState.combo > 1
                              ? _getComboScoreColor(gameState.combo)
                              : Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    minFontSize: 18,
                  ),
                ),
              ),
            ),
            if (gameState.combo > 1) ...[
              const Gap(4),
              AnimatedBuilder(
                animation: _comboAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _comboScaleAnimation.value,
                    child: ComboFireWidget(
                      combo: gameState.combo,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFFD700),
                              Color(0xFFFFE66D),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: 0.3 + (_comboGlowAnimation.value * 0.7),
                            ),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFE66D).withValues(
                                alpha: 0.3 + (_comboGlowAnimation.value * 0.5),
                              ),
                              blurRadius: 8 + (_comboGlowAnimation.value * 12),
                              spreadRadius: 2 + (_comboGlowAnimation.value * 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '🔥',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context).translate('combo'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'x${gameState.combo}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              // Combo timer progress bar
              Container(
                width: 80,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: (comboProgress * 100).round().clamp(0, 100),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE66D),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: ((1 - comboProgress) * 100).round().clamp(0, 100),
                      child: const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 80,
                child: Text(
                  '$movesLeft ${AppLocalizations.of(context).translate('moves_left')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white60,
                        fontSize: 8,
                      ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
