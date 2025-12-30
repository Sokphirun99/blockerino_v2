import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_size_text/auto_size_text.dart';
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
        tween: Tween<double>(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
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

  /// Get combo color based on combo level
  Color _getComboColor(int combo) {
    if (combo >= 10) return const Color(0xFFFF00FF); // Magenta
    if (combo >= 7) return const Color(0xFFFF1493); // Deep Pink
    if (combo >= 5) return const Color(0xFFFF4500); // Red-Orange
    if (combo >= 3) return const Color(0xFFFFA500); // Orange
    return const Color(0xFFFFD700); // Gold
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
        final hasCombo = gameState.combo > 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 12),
            ],

            // Main Score & Combo Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                  if (hasCombo)
                    BoxShadow(
                      color: _getComboColor(gameState.combo)
                          .withValues(alpha: 0.3),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // High Score Indicator (if new high score)
                  if (isNewHighScore) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Color(0xFFFFE66D),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'NEW BEST!',
                          style: TextStyle(
                            color: const Color(0xFFFFE66D),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Score Label
                  Text(
                    AppLocalizations.of(context)
                        .translate('score')
                        .toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Score Value - IMPROVED FOR VISIBILITY
                  ComboFireWidget(
                    combo: gameState.combo,
                    child: ComboGlowWidget(
                      comboLevel: gameState.combo,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // STRONG BLACK OUTLINE for visibility against fire
                          AutoSizeText(
                            '${gameState.score}',
                            style: TextStyle(
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 6
                                ..color = Colors.black,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                            maxLines: 1,
                            minFontSize: 24,
                            textAlign: TextAlign.center,
                          ),
                          // MAIN TEXT with enhanced shadows
                          AutoSizeText(
                            '${gameState.score}',
                            style: TextStyle(
                              color: hasCombo
                                  ? _getComboColor(gameState.combo)
                                  : Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                              shadows: [
                                // Multiple shadows for depth
                                const Shadow(
                                  color: Colors.black,
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                ),
                                const Shadow(
                                  color: Colors.black,
                                  offset: Offset(-1, -1),
                                  blurRadius: 2,
                                ),
                                if (hasCombo)
                                  Shadow(
                                    color: _getComboColor(gameState.combo),
                                    blurRadius: 12,
                                  ),
                              ],
                            ),
                            maxLines: 1,
                            minFontSize: 24,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Combo Display
                  if (hasCombo) ...[
                    const SizedBox(height: 8),
                    AnimatedBuilder(
                      animation: _comboAnimationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _comboScaleAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getComboColor(gameState.combo),
                                  _getComboColor(gameState.combo)
                                      .withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(
                                  alpha:
                                      0.4 + (_comboGlowAnimation.value * 0.4),
                                ),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _getComboColor(gameState.combo)
                                      .withValues(
                                    alpha:
                                        0.4 + (_comboGlowAnimation.value * 0.4),
                                  ),
                                  blurRadius:
                                      12 + (_comboGlowAnimation.value * 8),
                                  spreadRadius:
                                      2 + (_comboGlowAnimation.value * 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '🔥',
                                  style: TextStyle(
                                    fontSize:
                                        16 + (_comboScaleAnimation.value * 2),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'COMBO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'x${gameState.combo}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Combo Timer Progress
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: comboProgress,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getComboColor(gameState.combo),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$movesLeft ${AppLocalizations.of(context).translate('moves_left')}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
