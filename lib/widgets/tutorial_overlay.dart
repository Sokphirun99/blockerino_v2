import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_localizations.dart';

/// Tutorial overlay system for first-time users.
/// Shows 5 steps to guide new players through game mechanics.
class TutorialOverlay extends StatefulWidget {
  final int initialStep;
  final VoidCallback onComplete;
  final VoidCallback? onPiecePlaced;
  final VoidCallback? onLineCleared;

  const TutorialOverlay({
    super.key,
    this.initialStep = 0,
    required this.onComplete,
    this.onPiecePlaced,
    this.onLineCleared,
  });

  /// Check if tutorial has been completed
  static Future<bool> isTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tutorial_completed') ?? false;
  }

  /// Mark tutorial as completed
  static Future<void> markTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', true);
  }

  /// Reset tutorial (for testing or settings)
  static Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_completed', false);
  }

  @override
  State<TutorialOverlay> createState() => TutorialOverlayState();
}

class TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late int _currentStep;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  /// Get current step (for external access)
  int get currentStep => _currentStep;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 4) {
      _animationController.reverse().then((_) {
        setState(() {
          _currentStep++;
        });
        _animationController.forward();
      });
    } else {
      _completeTutorial();
    }
  }

  void _skipTutorial() {
    _completeTutorial();
  }

  void _completeTutorial() async {
    await TutorialOverlay.markTutorialCompleted();
    widget.onComplete();
  }

  /// Called externally when a piece is placed (for Step 1)
  void onPiecePlaced() {
    if (_currentStep == 1) {
      _nextStep();
    }
  }

  /// Called externally when a line is cleared (for Step 2)
  void onLineCleared() {
    if (_currentStep == 2) {
      _nextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    // Steps 1 and 2 are interactive - allow taps to pass through to game
    final isInteractiveStep = _currentStep == 1 || _currentStep == 2;

    return IgnorePointer(
      // Allow all pointer events to pass through during interactive steps
      ignoring: isInteractiveStep,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Dark overlay background
              Container(
                color: Colors.black.withValues(alpha: isInteractiveStep ? 0.0 : 0.7),
              ),

              // Skip button (top-right) - always interactive
              if (!isInteractiveStep)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  right: 16,
                  child: _buildSkipButton(localizations),
                ),

              // Tutorial content - positioned at top for interactive steps
              if (isInteractiveStep)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 16,
                  right: 16,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildCompactStepContent(localizations),
                  ),
                )
              else
                Center(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildStepContent(localizations),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton(AppLocalizations localizations) {
    return TextButton(
      onPressed: _skipTutorial,
      style: TextButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        localizations.translate('skip_tutorial'),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStepContent(AppLocalizations localizations) {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep(localizations);
      case 1:
        return _buildDragPieceStep(localizations);
      case 2:
        return _buildClearLinesStep(localizations);
      case 3:
        return _buildComboSystemStep(localizations);
      case 4:
        return _buildGameOverStep(localizations);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Compact tutorial hint for interactive steps (shown at top, doesn't block game)
  Widget _buildCompactStepContent(AppLocalizations localizations) {
    String hint;
    IconData icon;
    Color color;
    
    if (_currentStep == 1) {
      hint = localizations.translate('tutorial_drag_hint');
      icon = Icons.touch_app;
      color = Colors.blue;
    } else if (_currentStep == 2) {
      hint = localizations.translate('tutorial_clear_hint');
      icon = Icons.auto_awesome;
      color = Colors.green;
    } else {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              hint,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _skipTutorial,
            child: Text(
              localizations.translate('skip_tutorial'),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// STEP 0 - Welcome
  Widget _buildWelcomeStep(AppLocalizations localizations) {
    return _TutorialCard(
      icon: Icons.sports_esports,
      iconColor: Colors.amber,
      title: localizations.translate('tutorial_welcome_title'),
      description: localizations.translate('tutorial_welcome_desc'),
      buttonText: localizations.translate('tutorial_lets_go'),
      onButtonPressed: _nextStep,
      stepIndicator: _buildStepIndicator(),
    );
  }

  /// STEP 1 - Drag Piece
  Widget _buildDragPieceStep(AppLocalizations localizations) {
    return _TutorialCard(
      icon: Icons.touch_app,
      iconColor: Colors.blue,
      title: localizations.translate('tutorial_drag_title'),
      description: localizations.translate('tutorial_drag_desc'),
      buttonText: null, // Auto-advance
      hint: localizations.translate('tutorial_drag_hint'),
      stepIndicator: _buildStepIndicator(),
    );
  }

  /// STEP 2 - Clear Lines
  Widget _buildClearLinesStep(AppLocalizations localizations) {
    return _TutorialCard(
      icon: Icons.auto_awesome,
      iconColor: Colors.green,
      title: localizations.translate('tutorial_clear_title'),
      description: localizations.translate('tutorial_clear_desc'),
      buttonText: null, // Auto-advance
      hint: localizations.translate('tutorial_clear_hint'),
      stepIndicator: _buildStepIndicator(),
      showClearExample: true,
    );
  }

  /// STEP 3 - Combo System
  Widget _buildComboSystemStep(AppLocalizations localizations) {
    return _TutorialCard(
      icon: Icons.local_fire_department,
      iconColor: Colors.orange,
      title: localizations.translate('tutorial_combo_title'),
      description: localizations.translate('tutorial_combo_desc'),
      buttonText: localizations.translate('tutorial_got_it'),
      onButtonPressed: _nextStep,
      stepIndicator: _buildStepIndicator(),
      showComboExample: true,
    );
  }

  /// STEP 4 - Game Over
  Widget _buildGameOverStep(AppLocalizations localizations) {
    return _TutorialCard(
      icon: Icons.flag,
      iconColor: Colors.red,
      title: localizations.translate('tutorial_gameover_title'),
      description: localizations.translate('tutorial_gameover_desc'),
      buttonText: localizations.translate('tutorial_start_playing'),
      onButtonPressed: _completeTutorial,
      stepIndicator: _buildStepIndicator(),
      showPieceTrayExample: true,
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;
        return Container(
          width: isActive ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.amber
                : isCompleted
                    ? Colors.amber.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// Tutorial card widget for displaying step content
class _TutorialCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final String? hint;
  final Widget stepIndicator;
  final bool showClearExample;
  final bool showComboExample;
  final bool showPieceTrayExample;

  const _TutorialCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    this.buttonText,
    this.onButtonPressed,
    this.hint,
    required this.stepIndicator,
    this.showClearExample = false,
    this.showComboExample = false,
    this.showPieceTrayExample = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Flexible(
            flex: 0,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),

          // Description
          Flexible(
            flex: 0,
            child: Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Example visualizations
          if (showClearExample) ...[
            const SizedBox(height: 20),
            _buildClearLinesExample(),
          ],
          if (showComboExample) ...[
            const SizedBox(height: 20),
            _buildComboExample(),
          ],
          if (showPieceTrayExample) ...[
            const SizedBox(height: 20),
            _buildPieceTrayExample(),
          ],

          // Hint text
          if (hint != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hint!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Step indicator
          stepIndicator,

          // Button
          if (buttonText != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  buttonText!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Visual example of clearing lines
  Widget _buildClearLinesExample() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Before: Full row
          Flexible(
            child: Column(
              children: [
                _buildMiniGrid(highlightRow: true),
                const SizedBox(height: 4),
                Text(
                  'Before',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, color: Colors.green, size: 20),
          // After: Cleared
          Flexible(
            child: Column(
              children: [
                _buildMiniGrid(cleared: true),
                const SizedBox(height: 4),
                Text(
                  'After',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniGrid({bool highlightRow = false, bool cleared = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: List.generate(4, (row) {
          final isHighlightedRow = row == 2 && highlightRow;
          final isClearedRow = row == 2 && cleared;
          return Row(
            children: List.generate(5, (col) {
              Color cellColor;
              if (isClearedRow) {
                cellColor = Colors.green.withValues(alpha: 0.3);
              } else if (isHighlightedRow) {
                cellColor = Colors.blue;
              } else if (row == 1 && col < 3) {
                cellColor = Colors.orange;
              } else if (row == 3 && col > 1) {
                cellColor = Colors.purple;
              } else {
                cellColor = Colors.grey[200]!;
              }
              return Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: isClearedRow
                    ? const Icon(Icons.check, size: 8, color: Colors.green)
                    : null,
              );
            }),
          );
        }),
      ),
    );
  }

  /// Visual example of combo system
  Widget _buildComboExample() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.2),
            Colors.red.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(child: _buildComboLevel('x1', Colors.grey, '10')),
          const Icon(Icons.arrow_forward, color: Colors.orange, size: 14),
          Flexible(child: _buildComboLevel('x2', Colors.orange, '20')),
          const Icon(Icons.arrow_forward, color: Colors.red, size: 14),
          Flexible(child: _buildComboLevel('x3', Colors.red, '30')),
        ],
      ),
    );
  }

  Widget _buildComboLevel(String level, Color color, String points) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            level,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          points,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  /// Visual example of piece tray
  Widget _buildPieceTrayExample() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Flexible(child: _buildMiniPiece(Colors.blue, [[1, 1], [1, 0]])),
              Flexible(child: _buildMiniPiece(Colors.red, [[1], [1], [1]])),
              Flexible(child: _buildMiniPiece(Colors.green, [[1, 1]])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber, color: Colors.red[400], size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'No space = Game Over!',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPiece(Color color, List<List<int>> shape) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: shape.map((row) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: row.map((cell) {
              return Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: cell == 1 ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

/// Pulsing highlight circle for interactive elements
class _PulsingHighlight extends StatefulWidget {
  final double size;
  final Color color;

  const _PulsingHighlight({
    required this.size,
    required this.color,
  });

  @override
  State<_PulsingHighlight> createState() => _PulsingHighlightState();
}

class _PulsingHighlightState extends State<_PulsingHighlight>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.color.withValues(alpha: 0.8),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
      ),
    );
  }
}
