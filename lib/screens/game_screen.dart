import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../config/app_config.dart';
import '../providers/game_state_provider.dart';
import '../providers/settings_provider.dart';
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

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize synchronously - no async callbacks
    if (!_initialized) {
      _initialized = true;
      try {
        final gameState = Provider.of<GameStateProvider>(context, listen: false);
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        
        // If board is null, start game with appropriate mode
        if (gameState.board == null) {
          // Schedule game start after the current frame to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Use story level's game mode if provided, otherwise classic
            final mode = widget.storyLevel?.gameMode ?? GameMode.classic;
            gameState.startGame(mode);
            
            // Track game start
            settings.analyticsService.logGameStart(mode.name);
            if (widget.storyLevel != null) {
              settings.analyticsService.logScreenView('game_story_level_${widget.storyLevel!.levelNumber}');
            } else {
              settings.analyticsService.logScreenView('game_${mode.name}');
            }
          });
        }
        
        // Set up line clear callback
        gameState.onLinesCleared = _onLinesCleared;
      } catch (e) {
        debugPrint('Error initializing game: $e');
      }
    }
  }

  void _onLinesCleared(List<ClearedBlockInfo> clearedBlocks, int lineCount) {
    final boardBox = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (boardBox == null) return;

    final gameState = Provider.of<GameStateProvider>(context, listen: false);
    final board = gameState.board;
    if (board == null) return;

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
    return Scaffold(
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
              child: Consumer<GameStateProvider>(
                builder: (context, gameState, child) {
                  if (gameState.gameOver) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _showGameOverDialog(context, gameState);
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
                              icon: Icon(Icons.arrow_back, color: AppConfig.textPrimary),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const GameHudWidget(),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Game Board with DragTarget - wrapped in Expanded to constrain size
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: BoardDragTarget(
                              child: KeyedSubtree(
                                key: _boardKey,
                                child: const BoardGridWidget(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Hand Pieces
                      const HandPiecesWidget(),
                      
                      const SizedBox(height: 12),
                      
                      // Power-Up Bar
                      Consumer<SettingsProvider>(
                        builder: (context, settings, _) {
                          return _buildPowerUpBar(context, settings);
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
                      boxShadow: [
                        BoxShadow(
                          color: AppConfig.achievementGlow,
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Text(
                      _achievementMessage!,
                      style: TextStyle(
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
        ],
      ),
    );
  }

  void _showGameOverDialog(BuildContext context, GameStateProvider gameState) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final isHighScore = gameState.score >= settings.highScore;
    
    // Track game end analytics
    final mode = widget.storyLevel?.gameMode ?? gameState.gameMode;
    settings.analyticsService.logGameEnd(
      gameMode: mode.name,
      score: gameState.score,
      linesCleared: 0, // We don't track total lines cleared yet
      duration: 0, // We don't track duration yet, could add timer
    );
    
    // Check if this is a story level and if objectives are met
    final isStoryMode = widget.storyLevel != null;
    int starsEarned = 0;
    bool levelCompleted = false;
    
    if (isStoryMode) {
      final level = widget.storyLevel!;
      final score = gameState.score;
      
      // Check if level objectives are met
      levelCompleted = score >= level.targetScore;
      
      // Calculate stars earned
      if (score >= level.starThreshold3) {
        starsEarned = 3;
      } else if (score >= level.starThreshold2) {
        starsEarned = 2;
      } else if (score >= level.starThreshold1) {
        starsEarned = 1;
      }
      
      // Update progress if level completed
      if (levelCompleted) {
        settings.completeStoryLevel(level.levelNumber, starsEarned, level.coinReward);
      }
    }
    
    if (settings.hapticsEnabled) {
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
              '${gameState.score}',
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
                    'Best: ${settings.highScore}',
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
                gameState.resetGame();
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
                gameState.resetGame();
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

  Widget _buildPowerUpBar(BuildContext context, SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPowerUpButton(context, PowerUpType.shuffle, settings),
          _buildPowerUpButton(context, PowerUpType.wildPiece, settings),
          _buildPowerUpButton(context, PowerUpType.lineClear, settings),
          _buildPowerUpButton(context, PowerUpType.colorBomb, settings),
        ],
      ),
    );
  }

  Widget _buildPowerUpButton(BuildContext context, PowerUpType type, SettingsProvider settings) {
    final count = settings.getPowerUpCount(type);
    final powerUp = PowerUp.allPowerUps.firstWhere((p) => p.type == type);
    
    return GestureDetector(
      onTap: count > 0 ? () async {
        final gameState = Provider.of<GameStateProvider>(context, listen: false);
        await gameState.triggerPowerUp(type);
        
        // Show feedback
        if (mounted && count - 1 == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${powerUp.name} used! Buy more in the Store.'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.orange,
            ),
          );
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
