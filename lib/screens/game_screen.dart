import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';
import 'package:confetti/confetti.dart';
import '../config/app_config.dart';
import '../cubits/game/game_cubit.dart';
import '../cubits/game/game_state.dart';
import '../cubits/settings/settings_cubit.dart';
import '../models/board.dart';
import '../models/game_mode.dart';
import '../models/game_theme.dart';
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
import '../widgets/loading_screen_widget.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/screen_flash.dart';
import '../widgets/combo_counter.dart';
import '../widgets/floating_score.dart';
import '../widgets/perfect_clear_celebration.dart';
import '../services/admob_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
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

  // BUG FIX #4 & #5: Track timers for proper cleanup
  final List<Timer> _particleTimers = [];
  Timer? _achievementTimer;

  // Screen flash effects
  final List<Widget> _flashEffects = [];
  int _flashIdCounter = 0;

  // Floating score popups
  final List<Widget> _scorePopups = [];
  int _scorePopupIdCounter = 0;

  // Perfect clear celebrations
  final List<Widget> _celebrations = [];
  int _celebrationIdCounter = 0;

  // AdMob service
  final AdMobService _adService = AdMobService();

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    // CRITICAL FIX: Listen to app lifecycle to auto-save game when app goes to background
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // CRITICAL FIX: Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Fix memory leak: Release the callback reference
    // GameCubit lives longer than GameScreen, so we must clear the callback
    // to prevent holding a strong reference to this widget state
    // FIX: Use stored reference instead of context.read() to avoid "deactivated widget" error
    _gameCubit?.onLinesCleared = null;

    // CRITICAL FIX: Auto-save game before disposing (when navigating away)
    if (_gameCubit != null) {
      final currentState = _gameCubit!.state;
      if (currentState is GameInProgress) {
        _gameCubit!.saveGame();
      }
    }

    _confettiController.dispose();

    // BUG FIX #4: Cancel all particle timers to prevent memory leaks
    for (final timer in _particleTimers) {
      timer.cancel();
    }

    // Dispose AdMob ads
    _adService.dispose();
    _particleTimers.clear();

    // BUG FIX #5: Cancel achievement timer
    _achievementTimer?.cancel();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // CRITICAL FIX: Auto-save game when app goes to background or is paused
    // This ensures the game is saved even if the user force-closes the app
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      final gameCubit = _gameCubit ?? context.read<GameCubit>();
      final currentState = gameCubit.state;
      if (currentState is GameInProgress) {
        gameCubit.saveGame();
        debugPrint('Auto-saved game on app lifecycle change: $state');
      }
    }
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

        // BUG FIX #1: Initialize _lastScore from current game state
        final currentState = gameCubit.state;
        if (currentState is GameInProgress) {
          _lastScore = currentState.score;
        }

        // BUG FIX #2: Reset combo level tracking for new games
        _lastComboLevel = 0;

        // BUG FIX #3: Reset game over dialog flag for new games
        _gameOverDialogShown = false;

        // Only handle story mode logic here - regular modes are handled by main menu
        if (widget.storyLevel != null) {
          // Story mode: Determine target mode from story level
          final targetMode = widget.storyLevel!.gameMode;

          // CRITICAL FIX: Also check if story level changed, not just game mode
          // This prevents the bug where Classic mode game continues when opening a Story level
          // that also uses Classic mode (e.g., Story Level 1 uses Classic mode)
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

    // Trigger screen flash for big clears
    if (lineCount >= 5) {
      _triggerFlash(const Color(0xFFFFD700)); // Gold for 5+ lines
    } else if (lineCount >= 3) {
      _triggerFlash(Colors.white); // White for 3-4 lines
    }

    // Show achievement messages
    _checkAchievements(lineCount, gameState.combo);

    // Calculate score earned for floating popup
    final scoreEarned = gameState.score - _lastScore;
    _lastScore = gameState.score;

    // Show floating score popup if points were earned
    if (scoreEarned > 0) {
      final size = MediaQuery.of(currentContext).size;
      final position = Offset(size.width / 2 - 50, size.height / 3);
      _showScorePopup(scoreEarned, position);
    }

    // Check for perfect clear (board completely empty after clearing)
    bool isBoardEmpty = true;
    for (int row = 0; row < board.size && isBoardEmpty; row++) {
      for (int col = 0; col < board.size && isBoardEmpty; col++) {
        if (board.grid[row][col].type == BlockType.filled) {
          isBoardEmpty = false;
        }
      }
    }

    if (isBoardEmpty && lineCount > 0) {
      // Calculate perfect clear bonus (same formula as game_cubit)
      final perfectClearBonus = 1000 + (gameState.combo * 100);
      _showPerfectClearCelebration(perfectClearBonus);
      _confettiController.play(); // Also play confetti!
      _triggerFlash(const Color(0xFFFFD700)); // Gold flash
    }

    // Create particles for each cleared block with ripple delay
    for (final blockInfo in clearedBlocks) {
      // Use delay for ripple effect
      final particleId = _particleIdCounter++;

      // BUG FIX #4: Use Timer instead of Future.delayed for proper cancellation
      final delayTimer = Timer(Duration(milliseconds: blockInfo.delayMs), () {
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
        // BUG FIX #4: Track timer for proper cleanup
        // CRITICAL: Check mounted before creating timer to prevent memory leak
        if (mounted) {
          final removeTimer = Timer(const Duration(milliseconds: 1000), () {
            if (mounted) {
              setState(() {
                _activeParticles.removeWhere((p) => p.id == particleId);
              });
            }
          });
          _particleTimers.add(removeTimer);
        }
      });
      _particleTimers.add(delayTimer);
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
    // BUG FIX: Reset lastComboLevel when combo resets to 0
    // This allows combo milestone messages to show again after combo breaks
    if (combo == 0) {
      _lastComboLevel = 0;
      return; // No combo achievements to check
    }

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

        // BUG FIX #5: Cancel previous timer and track new one
        _achievementTimer?.cancel();
        _achievementTimer = Timer(const Duration(seconds: 2), () {
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

  void _triggerFlash(Color color) {
    final flashId = _flashIdCounter++;
    setState(() {
      _flashEffects.add(
        Positioned.fill(
          key: ValueKey('flash-$flashId'),
          child: ScreenFlash(
            color: color,
            onComplete: () => _removeFlash(flashId),
          ),
        ),
      );
    });
  }

  void _removeFlash(int id) {
    if (!mounted) return;
    setState(() {
      _flashEffects.removeWhere(
          (w) => (w.key as ValueKey).value == 'flash-$id');
    });
  }

  void _showScorePopup(int points, Offset position) {
    final popupId = _scorePopupIdCounter++;
    setState(() {
      _scorePopups.add(
        FloatingScore(
          key: ValueKey('score-$popupId'),
          points: points,
          position: position,
          onComplete: () => _removeScorePopup(popupId),
        ),
      );
    });
  }

  void _removeScorePopup(int id) {
    if (!mounted) return;
    setState(() {
      _scorePopups.removeWhere(
          (w) => (w.key as ValueKey).value == 'score-$id');
    });
  }

  void _showPerfectClearCelebration(int bonus) {
    final id = _celebrationIdCounter++;
    setState(() {
      _celebrations.add(
        Positioned.fill(
          key: ValueKey('celebration-$id'),
          child: Center(
            child: PerfectClearCelebration(
              bonus: bonus,
              onComplete: () => _removeCelebration(id),
            ),
          ),
        ),
      );
    });
  }

  void _removeCelebration(int id) {
    if (!mounted) return;
    setState(() {
      _celebrations.removeWhere(
          (w) => (w.key as ValueKey).value == 'celebration-$id');
    });
  }

  // BUG FIX #7: Extract expensive calculation to separate method
  double _calculateSpeedMultiplier(GameState gameState) {
    if (gameState is! GameInProgress) return 1.0;

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
    return comboSpeed > fullnessSpeed ? comboSpeed : fullnessSpeed;
  }

  @override
  Widget build(BuildContext context) {
    final gameCubit = context.read<GameCubit>();
    // HIGH PRIORITY FIX: Extract theme at top level to reduce unnecessary rebuilds
    // Select on selectedThemeId (String) for proper equality comparison
    // This only rebuilds when theme ID changes, not on every GameCubit state change
    final selectedThemeId = context.select<SettingsCubit, String>(
      (cubit) => cubit.state.selectedThemeId,
    );
    final theme = GameTheme.getThemeById(selectedThemeId);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          gameCubit.saveGame();
          gameCubit.pauseTimer();
        }
      },
      child: Scaffold(
        body: BlocListener<GameCubit, GameState>(
          listener: (context, state) {
            // CRITICAL FIX: Reset combo tracking when game restarts
            // Check if this is a new game by checking combo == 0 (more reliable than state transitions)
            // This ensures achievement messages show on replay (e.g., "PLAY AGAIN")
            if (state is GameInProgress && state.combo == 0) {
              _lastComboLevel = 0;
            }
          },
          child: BlocBuilder<GameCubit, GameState>(
          builder: (context, gameState) {
            final speedMultiplier = _calculateSpeedMultiplier(gameState);

            return FloatingScoreOverlay(
              key: _scoreOverlayKey,
              child: Stack(
                children: [
                    // Animated background
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
                      child: Container(
                          decoration: BoxDecoration(
                            gradient: theme.getBackgroundGradient(),
                          ),
                          child: SafeArea(
                          child: Builder(
                            builder: (context) {
                              // Show loading screen
                              if (gameState is GameInitial ||
                                  gameState is GameLoading) {
                                return const LoadingScreenWidget(
                                  message: 'Loading game...',
                                );
                              }

                              // Game over dialog - RELEASE MODE FIX
                              if (gameState is GameOver &&
                                    !_gameOverDialogShown) {
                                  _gameOverDialogShown = true;
                                // CRITICAL FIX: Use WidgetsBinding for better release mode compatibility
                                // Multiple safety checks and longer delay for release builds
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                  if (mounted && context.mounted) {
                                    // Longer delay for release mode to ensure widget tree is fully stable
                                    // This prevents gray screen issues in production builds
                                    Future.delayed(
                                        const Duration(milliseconds: 300), () {
                                      if (mounted && context.mounted) {
                                        // Double-check state is still GameOver before showing dialog
                                        final currentState = gameCubit.state;
                                        if (currentState is GameOver) {
                                      _showGameOverDialog(
                                              context, gameCubit);
                                        } else {
                                          // Reset flag if state changed
                                          _gameOverDialogShown = false;
                                        }
                                      }
                                    });
                                    }
                                  });
                              } else if (gameState is! GameOver) {
                                  _gameOverDialogShown = false;
                                }

                              // CRITICAL FIX: Use Opacity to hide UI during game over (works in release mode)
                              return Opacity(
                                opacity: gameState is GameOver ? 0.0 : 1.0,
                                child: Column(
                                  children: [
                                    // Header with back button, score, mode
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 8.0,
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Back button
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.arrow_back,
                                                color: AppConfig.textPrimary,
                                              ),
                                              onPressed: () {
                                                gameCubit.saveGame();
                                                gameCubit.pauseTimer();
                                                Navigator.pop(context);
                                              },
                                            ),
                                          ),

                                          // Score and combo
                                          const Center(
                                            child: GameHudWidget(),
                                          ),

                                          // Game mode badge
                                          if (gameState is GameInProgress)
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: _buildModeBadge(gameState),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Board - Hide during game over to prevent grid lines showing through
                                    if (gameState is! GameOver)
                                    Expanded(
                                      flex: 3,
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12.0,
                                            ),
                                          child: BoardDragTarget(
                                              gridKey: _gridKey,
                                            child: KeyedSubtree(
                                              key: _boardKey,
                                              child: BoardGridWidget(
                                                  gridKey: _gridKey),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Show spacer during game over to maintain layout
                                    if (gameState is GameOver)
                                      const Expanded(
                                        flex: 3,
                                        child: SizedBox(),
                                      ),

                                    // Hand pieces - Hide during game over
                                    if (gameState is! GameOver)
                                    const Expanded(
                                      flex: 1,
                                      child: HandPiecesWidget(),
                                    ),

                                    // Banner ad at the bottom
                                    if (gameState is! GameOver)
                                      SizedBox(
                                        height: AdSize.banner.height.toDouble(),
                                        child: BannerAdWidget(
                                          adService: _adService,
                                          adSize: AdSize.banner,
                                        ),
                                      ),

                                    const SizedBox(height: 8),
                                  ],
                                ), // ← Closes Column
                              ); // ← Closes Opacity
                              },
                            ),
                          ),
                    ),
                  ),

                    // Achievement notification - CENTERED
                  if (_achievementMessage != null)
                      Positioned.fill(
                      child: Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 300),
                          builder: (context, value, child) {
                            return Transform.scale(
                                scale: 0.8 + (value * 0.2),
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                              constraints: const BoxConstraints(
                                minWidth: 200,
                                maxWidth: double.infinity,
                              ),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 32),
                            padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
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
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                            child: Text(
                              _achievementMessage!,
                              style: const TextStyle(
                                color: AppConfig.textPrimary,
                                    fontSize: 20,
                                fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
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

                  // Combo counter display
                  Positioned(
                    top: 100,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ComboCounter(
                        combo: gameState is GameInProgress ? gameState.combo : 0,
                        isActive: gameState is GameInProgress && gameState.combo >= 2,
                      ),
                    ),
                  ),

                  // Floating score popups
                  ..._scorePopups,

                  // Screen flash effects (perfect clear, chaos events, etc.)
                  ..._flashEffects,

                  // Perfect clear celebrations (on top of everything)
                  ..._celebrations,
                ],
              ),
            );
          },
          ),
        ),
      ),
    );
  }

  // Extract mode badge to helper method
  Widget _buildModeBadge(GameInProgress gameState) {
    final config = GameModeConfig.fromMode(gameState.gameMode);
    final isChaos = gameState.gameMode == GameMode.chaos;
    final modeColor =
        isChaos ? const Color(0xFFFF6B6B) : const Color(0xFF4ECDC4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: modeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
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
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showGameOverDialog(BuildContext context, GameCubit gameCubit) {
    debugPrint('🎮 _showGameOverDialog called'); // Debug log

    // CRITICAL FIX: Verify context is still valid (release mode safety)
    if (!context.mounted) {
      debugPrint('⚠️ Context not mounted, cannot show dialog');
      return;
    }

    final settingsCubit = context.read<SettingsCubit>();
    final state = gameCubit.state;
    if (state is! GameOver) {
      debugPrint('⚠️ State is not GameOver, returning early');
      return;
    }
    debugPrint('✅ GameOver state confirmed, showing dialog');

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

    // CRITICAL FIX: Use rootNavigator for release mode compatibility
    // RELEASE MODE FIX: Ensure dialog appears immediately with proper barrier
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor:
          Colors.black.withOpacity(0.85), // Visible barrier in release mode
      useRootNavigator: true, // RELEASE MODE FIX: Ensure dialog appears on top
      builder: (dialogContext) {
        debugPrint('🎮 Building Game Over Dialog'); // Debug log
        return AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            // ✅ Direct child, no Flexible
          TextButton(
            onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
            child: const Text('MENU'),
          ),
          if (isStoryMode &&
              levelCompleted &&
              widget.storyLevel!.levelNumber < StoryLevel.allLevels.length)
              // ✅ Direct child, no Flexible
            ElevatedButton(
              onPressed: () {
                final nextLevel = StoryLevel.allLevels.firstWhere(
                  (level) =>
                      level.levelNumber == widget.storyLevel!.levelNumber + 1,
                );
                gameCubit.resetGame();
                  Navigator.pop(dialogContext);
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GameScreen(storyLevel: nextLevel),
                    ),
                  );
                }
              },
              child: const Text('NEXT LEVEL'),
            )
          else
              // ✅ Direct child, no Flexible
            ElevatedButton(
              onPressed: () {
                gameCubit.resetGame();
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ECDC4),
                foregroundColor: Colors.black,
                padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('PLAY AGAIN'),
            ),
        ],
        );
      },
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
