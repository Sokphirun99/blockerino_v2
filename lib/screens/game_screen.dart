import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';
import 'package:confetti/confetti.dart';
import '../config/app_config.dart';
import '../cubits/game/game_cubit.dart';
import '../cubits/game/game_state.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';
import '../models/board.dart';
import '../models/game_mode.dart';
import '../models/story_level.dart';
// DISABLED: Power-up bar hidden
// import '../models/power_up.dart';
import '../widgets/board_grid_widget.dart';
import '../widgets/hand_pieces_widget.dart';
import '../widgets/game_hud_widget.dart';
import '../widgets/draggable_piece_widget.dart';
import '../widgets/particle_effect_widget.dart';
import '../widgets/animated_background_widget.dart';
import '../widgets/screen_shake_widget.dart';
// DISABLED: Power-up bar hidden
// import '../widgets/shared_ui_components.dart';
import '../widgets/floating_score_overlay.dart';

// Safe vibration helper for web compatibility
void _safeVibrate({int duration = 50, int amplitude = 128}) {
  if (kIsWeb) return; // Vibration not supported on web
  try {
    Vibration.vibrate(duration: duration, amplitude: amplitude);
  } catch (e) {
    // Silently ignore vibration errors
  }
}

class GameScreen extends StatefulWidget {
  final StoryLevel? storyLevel;

  const GameScreen({super.key, this.storyLevel});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GlobalKey _boardKey = GlobalKey();
  final GlobalKey _gridKey =
      GlobalKey(); // Key for inner grid widget (accurate coordinates)
  final GlobalKey<FloatingScoreOverlayState> _scoreOverlayKey = GlobalKey();
  final List<ParticleData> _activeParticles = [];
  int _particleIdCounter = 0;
  bool _shouldShake = false;
  String? _achievementMessage;
  int _lastComboLevel = 0;
  int _lastScore = 0; // Track score for floating score popups
  late ConfettiController _confettiController;
  bool _gameOverDialogShown = false; // Prevent showing dialog multiple times

  bool _initialized = false;
  // FIX: Store reference to cubit early to avoid context access in dispose()
  GameCubit? _gameCubit;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    // Fix memory leak: Release the callback reference
    // GameCubit lives longer than GameScreen, so we must clear the callback
    // to prevent holding a strong reference to this widget state
    // FIX: Use stored reference instead of context.read() to avoid "deactivated widget" error
    _gameCubit?.onLinesCleared = null;

    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize synchronously - no async callbacks
    if (!_initialized) {
      _initialized = true;
      try {
        final gameCubit = context.read<GameCubit>();
        final settingsCubit = context.read<SettingsCubit>();

        // FIX: Store cubit reference for safe access in dispose()
        _gameCubit = gameCubit;

        // Only handle story mode logic here - regular modes are handled by main menu
        if (widget.storyLevel != null) {
          // Story mode: Determine target mode from story level
          final targetMode = widget.storyLevel!.gameMode;

          // CRITICAL FIX: Also check if story level changed, not just game mode
          // This prevents the bug where Classic mode game continues when opening a Story level
          // that also uses Classic mode (e.g., Story Level 1 uses Classic mode)
          final currentState = gameCubit.state;
          final currentLevelNumber = (currentState is GameInProgress)
              ? currentState.storyLevel?.levelNumber
              : null;
          final targetLevelNumber = widget.storyLevel?.levelNumber;

          // Check if we need to start a new game (no game active OR mode mismatch OR level mismatch)
          if (!gameCubit.hasActiveGame ||
              gameCubit.currentGameMode != targetMode ||
              currentLevelNumber != targetLevelNumber) {
            // Schedule game start after the current frame to avoid setState during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              gameCubit.startGame(targetMode, storyLevel: widget.storyLevel);

              // Track game start
              settingsCubit.analyticsService.logGameStart(targetMode.name);
              settingsCubit.analyticsService.logScreenView(
                  'game_story_level_${widget.storyLevel!.levelNumber}');
            });
          }
        }

        // Set up line clear callback (for both story mode and regular modes)
        gameCubit.onLinesCleared = _onLinesCleared;
      } catch (e) {
        debugPrint('Error initializing game: $e');
      }
    }
  }

  void _onLinesCleared(List<ClearedBlockInfo> clearedBlocks, int lineCount) {
    if (!mounted) return; // Safety check

    final boardBox = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (boardBox == null) return;

    // Capture context and cubit before any async operations
    final currentContext = context;
    if (!mounted) return; // Double-check after context access

    final gameCubit = currentContext.read<GameCubit>();
    final gameState = gameCubit.state;
    if (gameState is! GameInProgress) return;
    final board = gameState.board;

    // Calculate block size
    final boardSize = boardBox.size;
    final blockSize = (boardSize.width - 8) / board.size; // Account for padding
    final boardPosition = boardBox.localToGlobal(Offset.zero);

    // Trigger screen shake for big clears (3+ lines)
    if (lineCount >= 3) {
      if (mounted) {
        setState(() {
          _shouldShake = true;
        });
      }
    }

    // Show achievement messages
    _checkAchievements(lineCount, gameState.combo);

    // Calculate score earned for floating popup
    final scoreEarned = gameState.score - _lastScore;
    _lastScore = gameState.score;

    // Create particles for each cleared block with ripple delay
    for (final blockInfo in clearedBlocks) {
      // Use delay for ripple effect
      final particleId = _particleIdCounter++;
      Future.delayed(Duration(milliseconds: blockInfo.delayMs), () {
        if (!mounted) return;

        final particleX = boardPosition.dx +
            4 +
            (blockInfo.col * blockSize) +
            (blockSize / 2);
        final particleY = boardPosition.dy +
            4 +
            (blockInfo.row * blockSize) +
            (blockSize / 2);

        if (mounted) {
          setState(() {
            _activeParticles.add(ParticleData(
              id: particleId,
              position: Offset(particleX, particleY),
              color: blockInfo.color ?? Colors.white,
            ));
          });
        }

        // Auto-remove particle after animation duration (prevents memory leak)
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              _activeParticles.removeWhere((p) => p.id == particleId);
            });
          }
        });
      });
    }

    // Add floating score popup at the center of cleared area
    if (clearedBlocks.isNotEmpty && scoreEarned > 0) {
      final centerBlock = clearedBlocks[clearedBlocks.length ~/ 2];
      final scoreX = boardPosition.dx +
          4 +
          (centerBlock.col * blockSize) +
          (blockSize / 2);
      final scoreY = boardPosition.dy +
          4 +
          (centerBlock.row * blockSize) +
          (blockSize / 2);

      // Show score in the overlay system
      _scoreOverlayKey.currentState?.showScore(
        Offset(scoreX, scoreY),
        scoreEarned,
      );
    }
  }

  void _checkAchievements(int lineCount, int combo) {
    String? message;

    // Check for special line clears
    if (lineCount >= 4) {
      message = '🔥 QUAD CLEAR! 🔥';
    } else if (lineCount == 3) {
      message = '⚡ TRIPLE CLEAR! ⚡';
    }

    // Check for combo milestones
    if (combo >= 20 && _lastComboLevel < 20) {
      message = '🌟 MEGA COMBO x$combo! 🌟';
    } else if (combo >= 10 && _lastComboLevel < 10) {
      message = '✨ SUPER COMBO x$combo! ✨';
    } else if (combo >= 5 && _lastComboLevel < 5) {
      message = '💫 COMBO x$combo! 💫';
    }

    _lastComboLevel = combo;

    if (message != null) {
      if (mounted) {
        setState(() {
          _achievementMessage = message;
        });

        // Hide message after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _achievementMessage = null;
            });
          }
        });
      }
    }
  }

  void _removeParticle(int id) {
    if (mounted) {
      setState(() {
        _activeParticles.removeWhere((p) => p.id == id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameCubit = context.read<GameCubit>();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Save game when back button is pressed
          gameCubit.saveGame();
          // Stop the timer when leaving to prevent it from running in background
          gameCubit.pauseTimer();
        }
      },
      child: Scaffold(
        body: BlocBuilder<GameCubit, GameState>(
          builder: (context, gameState) {
            // Calculate background speed multiplier based on game state
            double speedMultiplier = 1.0;
            if (gameState is GameInProgress) {
              // Speed up with combo (max 2.5x at combo 5+)
              final comboSpeed = 1.0 + (gameState.combo.clamp(0, 5) * 0.3);

              // Speed up when board is getting full (calculate filled percentage)
              int filledBlocks = 0;
              for (int row = 0; row < gameState.board.size; row++) {
                for (int col = 0; col < gameState.board.size; col++) {
                  if (gameState.board.grid[row][col].type == BlockType.filled) {
                    filledBlocks++;
                  }
                }
              }
              final boardFullness =
                  filledBlocks / (gameState.board.size * gameState.board.size);
              final fullnessSpeed =
                  1.0 + (boardFullness * 1.5); // Max 2.5x when 100% full

              // Use the higher of the two multipliers
              speedMultiplier =
                  comboSpeed > fullnessSpeed ? comboSpeed : fullnessSpeed;
            }

            return FloatingScoreOverlay(
              key: _scoreOverlayKey,
              child: Stack(
                children: [
                  // Animated background with dynamic speed
                  Positioned.fill(
                    child: AnimatedBackgroundWidget(
                      speedMultiplier: speedMultiplier,
                    ),
                  ),

                  // Main game content with screen shake
                  ScreenShakeWidget(
                    shouldShake: _shouldShake,
                    intensity: 8.0,
                    onShakeComplete: () {
                      if (mounted) {
                        setState(() {
                          _shouldShake = false;
                        });
                      }
                    },
                    child: BlocBuilder<SettingsCubit, SettingsState>(
                      builder: (context, settings) {
                        final theme = settings.currentTheme;
                        return Container(
                          decoration: BoxDecoration(
                            gradient: theme.getBackgroundGradient(),
                          ),
                          child: SafeArea(
                            child: BlocBuilder<GameCubit, GameState>(
                              builder: (context, state) {
                                if (state is GameOver &&
                                    !_gameOverDialogShown) {
                                  _gameOverDialogShown = true;
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (mounted) {
                                      _showGameOverDialog(
                                          context, context.read<GameCubit>());
                                    }
                                  });
                                } else if (state is! GameOver) {
                                  // Reset flag when game is not over
                                  _gameOverDialogShown = false;
                                }

                                return Column(
                                  children: [
                                    // Header with back button, centered score/combo, and game mode name
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0, vertical: 8.0),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Back button on the left
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: IconButton(
                                              icon: const Icon(Icons.arrow_back,
                                                  color: AppConfig.textPrimary),
                                              onPressed: () {
                                                final gameCubit =
                                                    context.read<GameCubit>();
                                                // Save game before going back
                                                gameCubit.saveGame();
                                                // Stop the timer when leaving to prevent it from running in background
                                                gameCubit.pauseTimer();
                                                Navigator.pop(context);
                                              },
                                            ),
                                          ),
                                          // Score and combo centered in the middle
                                          const Center(
                                            child: GameHudWidget(),
                                          ),
                                          // Game mode name on the right
                                          Builder(
                                            builder: (context) {
                                              if (state is! GameInProgress) {
                                                return const SizedBox.shrink();
                                              }
                                              final gameState = state;
                                              final config =
                                                  GameModeConfig.fromMode(
                                                      gameState.gameMode);
                                              final isChaos =
                                                  gameState.gameMode ==
                                                      GameMode.chaos;
                                              final modeColor = isChaos
                                                  ? const Color(0xFFFF6B6B)
                                                  : const Color(0xFF4ECDC4);

                                              return Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: modeColor.withValues(
                                                        alpha: 0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                      color: modeColor,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    config.name,
                                                    style: TextStyle(
                                                      color: modeColor,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Game Board with DragTarget - wrapped in Expanded to constrain size
                                    Expanded(
                                      flex: 3,
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12.0),
                                          child: BoardDragTarget(
                                            gridKey:
                                                _gridKey, // Pass grid key for accurate coordinates
                                            child: KeyedSubtree(
                                              key: _boardKey,
                                              child: BoardGridWidget(
                                                  gridKey: _gridKey),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Hand Pieces - more space like Block Blast
                                    const Expanded(
                                      flex: 1,
                                      child: HandPiecesWidget(),
                                    ),

                                    // DISABLED: Power-Up Bar
                                    /*
                                    BlocBuilder<SettingsCubit, SettingsState>(
                                      builder: (context, settingsState) {
                                        return _buildPowerUpBar(context,
                                            context.read<SettingsCubit>());
                                      },
                                    ),

                                    const SizedBox(height: 8),
                                    */
                                    const SizedBox(height: 8),
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Achievement notification
                  if (_achievementMessage != null)
                    Positioned(
                      top: 120,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppConfig.achievementGradientStart,
                                  AppConfig.achievementGradientEnd,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppConfig.achievementBorder,
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppConfig.achievementGlow,
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Text(
                              _achievementMessage!,
                              style: const TextStyle(
                                color: AppConfig.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Particle effects overlay
                  ..._activeParticles.map((particle) => Positioned.fill(
                        child: IgnorePointer(
                          child: ParticleEffectWidget(
                            key: ValueKey(particle.id),
                            position: particle.position,
                            color: particle.color,
                            blockSize: 20,
                            onComplete: () => _removeParticle(particle.id),
                          ),
                        ),
                      )),

                  // Floating score popups are handled by FloatingScoreOverlay
                  // (removed duplicate FloatingScoreWidget system)

                  // Confetti overlay for celebrations
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirection: 3.14 / 2, // Downward
                      emissionFrequency: 0.05,
                      numberOfParticles: 20,
                      gravity: 0.1,
                      shouldLoop: false,
                      colors: const [
                        Color(0xFF9d4edd),
                        Color(0xFF7b2cbf),
                        Color(0xFFFFE66D),
                        Color(0xFFFFD700),
                        Color(0xFF52b788),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showGameOverDialog(BuildContext context, GameCubit gameCubit) {
    final settingsCubit = context.read<SettingsCubit>();
    final state = gameCubit.state;
    if (state is! GameOver) return;

    final isHighScore = state.finalScore >= settingsCubit.state.highScore;

    // Get story mode data from state if available
    final isStoryMode = state.storyLevel != null;
    final starsEarned = state.starsEarned;
    final levelCompleted = state.levelCompleted;

    // Trigger confetti for high score or level complete
    if (isHighScore || (isStoryMode && levelCompleted)) {
      _confettiController.play();
    }

    // Track game end analytics
    final mode = widget.storyLevel?.gameMode ?? state.gameMode;
    settingsCubit.analyticsService.logGameEnd(
      gameMode: mode.name,
      score: state.finalScore,
      linesCleared: 0, // We don't track total lines cleared yet
      duration: 0, // We don't track duration yet, could add timer
    );

    // Update progress if story level completed
    if (isStoryMode && levelCompleted) {
      settingsCubit.completeStoryLevel(
        state.storyLevel!.levelNumber,
        starsEarned,
        state.storyLevel!.coinReward,
      );
    }

    if (settingsCubit.state.hapticsEnabled) {
      _safeVibrate(duration: 500);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppConfig.dialogBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isStoryMode && levelCompleted
                ? AppConfig.accentColor
                : isHighScore
                    ? AppConfig.achievementBorder
                    : AppConfig.achievementGradientStart,
            width: 2,
          ),
        ),
        title: Column(
          children: [
            if (isStoryMode && levelCompleted) ...[
              const Icon(
                Icons.emoji_events,
                color: AppConfig.accentColor,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'LEVEL COMPLETE!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppConfig.accentColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Icon(
                    index < starsEarned ? Icons.star : Icons.star_border,
                    color: AppConfig.accentColor,
                    size: 32,
                  );
                }),
              ),
              const SizedBox(height: 4),
            ] else if (isHighScore) ...[
              const Icon(
                Icons.emoji_events,
                color: AppConfig.achievementBorder,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'NEW HIGH SCORE!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppConfig.achievementBorder,
                      fontSize: 14,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
            ],
            if (!isStoryMode || !levelCompleted)
              Text(
                'GAME OVER',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppConfig.gameOverColor,
                      fontSize: 28,
                    ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Final Score',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConfig.textSecondary,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${state.finalScore}',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 56,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFE66D), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Best: ${settingsCubit.state.highScore}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Return to menu
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
            child: const Text('MENU'),
          ),
          if (isStoryMode &&
              levelCompleted &&
              widget.storyLevel!.levelNumber < StoryLevel.allLevels.length)
            ElevatedButton(
              onPressed: () {
                final nextLevel = StoryLevel.allLevels.firstWhere(
                  (level) =>
                      level.levelNumber == widget.storyLevel!.levelNumber + 1,
                );
                gameCubit.resetGame();
                Navigator.pop(dialogContext); // Close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(storyLevel: nextLevel),
                  ),
                );
              },
              child: const Text('NEXT LEVEL'),
            )
          else
            ElevatedButton(
              onPressed: () {
                gameCubit.resetGame();
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ECDC4),
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('PLAY AGAIN'),
            ),
        ],
      ),
    );
  }

  // ========== Power-Up UI Methods ==========
  // DISABLED: Power-up bar hidden
  /*
  Widget _buildPowerUpBar(BuildContext context, SettingsCubit settingsCubit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPowerUpButton(context, PowerUpType.shuffle, settingsCubit),
          _buildPowerUpButton(context, PowerUpType.wildPiece, settingsCubit),
          _buildPowerUpButton(context, PowerUpType.lineClear, settingsCubit),
          _buildPowerUpButton(context, PowerUpType.colorBomb, settingsCubit),
        ],
      ),
    );
  }

  Widget _buildPowerUpButton(
      BuildContext context, PowerUpType type, SettingsCubit settingsCubit) {
    final count = settingsCubit.getPowerUpCount(type);
    final powerUp = PowerUp.allPowerUps.firstWhere((p) => p.type == type);

    return GestureDetector(
      onTap: count > 0
          ? () async {
              // Capture context and cubit before async operations
              final currentContext = context;
              final gameCubit = currentContext.read<GameCubit>();
              final powerUpName = powerUp.name; // Capture name before async
              await gameCubit.triggerPowerUp(type);

              // Show feedback - check mounted before using context
              if (mounted && count - 1 == 0) {
                // Only use context if widget is still mounted
                if (currentContext.mounted) {
                  SharedSnackBars.showPowerUpUsed(currentContext, powerUpName);
                }
              }
            }
          : null,
      child: Opacity(
        opacity: count > 0 ? 1.0 : 0.3,
        child: Container(
          width: 60,
          height: 70,
          decoration: BoxDecoration(
            gradient: count > 0
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple.withValues(alpha: 0.3),
                      Colors.blue.withValues(alpha: 0.2),
                    ],
                  )
                : null,
            color: count > 0 ? null : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: count > 0
                  ? Colors.purpleAccent.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                powerUp.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: count > 0
                      ? const Color(0xFFffd700).withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: count > 0
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  */
}
