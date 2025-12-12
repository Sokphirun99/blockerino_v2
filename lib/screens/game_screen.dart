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
import '../models/power_up.dart';
import '../widgets/board_grid_widget.dart';
import '../widgets/hand_pieces_widget.dart';
import '../widgets/game_hud_widget.dart';
import '../widgets/draggable_piece_widget.dart';
import '../widgets/particle_effect_widget.dart';
import '../widgets/animated_background_widget.dart';
import '../widgets/screen_shake_widget.dart';
import '../widgets/shared_ui_components.dart';

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
  final List<ParticleData> _activeParticles = [];
  int _particleIdCounter = 0;
  bool _shouldShake = false;
  String? _achievementMessage;
  int _lastComboLevel = 0;
  late ConfettiController _confettiController;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
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
        
        // If no active game, start game with appropriate mode
        if (!gameCubit.hasActiveGame) {
          // Schedule game start after the current frame to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Use story level's game mode if provided, otherwise classic
            final mode = widget.storyLevel?.gameMode ?? GameMode.classic;
            gameCubit.startGame(mode, storyLevel: widget.storyLevel);
            
            // Track game start
            settingsCubit.analyticsService.logGameStart(mode.name);
            if (widget.storyLevel != null) {
              settingsCubit.analyticsService.logScreenView('game_story_level_${widget.storyLevel!.levelNumber}');
            } else {
              settingsCubit.analyticsService.logScreenView('game_${mode.name}');
            }
          });
        }
        
        // Set up line clear callback
        gameCubit.onLinesCleared = _onLinesCleared;
      } catch (e) {
        debugPrint('Error initializing game: $e');
      }
    }
  }

  void _onLinesCleared(List<ClearedBlockInfo> clearedBlocks, int lineCount) {
    final boardBox = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (boardBox == null) return;

    final gameCubit = context.read<GameCubit>();
    final gameState = gameCubit.state;
    if (gameState is! GameInProgress) return;
    final board = gameState.board;

    // Calculate block size
    final boardSize = boardBox.size;
    final blockSize = (boardSize.width - 8) / board.size; // Account for padding
    final boardPosition = boardBox.localToGlobal(Offset.zero);

    // Trigger screen shake for big clears (3+ lines)
    if (lineCount >= 3) {
      setState(() {
        _shouldShake = true;
      });
    }

    // Show achievement messages
    _checkAchievements(lineCount, gameState.combo);

    // Create particles for each cleared block
    setState(() {
      for (final blockInfo in clearedBlocks) {
        final particleX = boardPosition.dx + 4 + (blockInfo.col * blockSize) + (blockSize / 2);
        final particleY = boardPosition.dy + 4 + (blockInfo.row * blockSize) + (blockSize / 2);
        
        _activeParticles.add(ParticleData(
          id: _particleIdCounter++,
          position: Offset(particleX, particleY),
          color: blockInfo.color ?? Colors.white,
        ));
      }
    });
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
    setState(() {
      _activeParticles.removeWhere((p) => p.id == id);
    });
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
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Animated background
            const Positioned.fill(
              child: AnimatedBackgroundWidget(),
          ),
          
          // Main game content with screen shake
          ScreenShakeWidget(
            shouldShake: _shouldShake,
            intensity: 8.0,
            onShakeComplete: () {
              setState(() {
                _shouldShake = false;
              });
            },
            child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppConfig.gameBackgroundTop,
                  AppConfig.gameBackgroundMiddle,
                  AppConfig.gameBackgroundBottom,
                ],
              ),
            ),
            child: SafeArea(
              child: BlocBuilder<GameCubit, GameState>(
                builder: (context, state) {
                  if (state is GameOver) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showGameOverDialog(context, context.read<GameCubit>());
                    });
                  }
                  
                  return Column(
                    children: [
                      // Header with back button and score
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: AppConfig.textPrimary),
                              onPressed: () {
                                // Save game before going back
                                context.read<GameCubit>().saveGame();
                                Navigator.pop(context);
                              },
                            ),
                            const Flexible(
                              child: GameHudWidget(),
                            ),
                          ],
                        ),
                      ),
                      
                      // Game Board with DragTarget - wrapped in Expanded to constrain size
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: BoardDragTarget(
                              child: KeyedSubtree(
                                key: _boardKey,
                                child: const BoardGridWidget(),
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
                      
                      // Power-Up Bar
                      BlocBuilder<SettingsCubit, SettingsState>(
                        builder: (context, settingsState) {
                          return _buildPowerUpBar(context, context.read<SettingsCubit>());
                        },
                      ),
                      
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
          if (isStoryMode && levelCompleted && widget.storyLevel!.levelNumber < StoryLevel.allLevels.length)
            ElevatedButton(
              onPressed: () {
                final nextLevel = StoryLevel.allLevels.firstWhere(
                  (level) => level.levelNumber == widget.storyLevel!.levelNumber + 1,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFffd700),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('NEXT LEVEL', style: TextStyle(fontWeight: FontWeight.bold)),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  Widget _buildPowerUpButton(BuildContext context, PowerUpType type, SettingsCubit settingsCubit) {
    final count = settingsCubit.getPowerUpCount(type);
    final powerUp = PowerUp.allPowerUps.firstWhere((p) => p.type == type);
    
    return GestureDetector(
      onTap: count > 0 ? () async {
        final gameCubit = context.read<GameCubit>();
        await gameCubit.triggerPowerUp(type);
        
        // Show feedback
        if (mounted && count - 1 == 0) {
          SharedSnackBars.showPowerUpUsed(context, powerUp.name);
        }
      } : null,
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
                    color: count > 0 ? Colors.white : Colors.white.withValues(alpha: 0.3),
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
}
