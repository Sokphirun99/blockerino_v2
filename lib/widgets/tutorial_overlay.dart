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
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late int _currentStep;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

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

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Dark overlay background
            GestureDetector(
              onTap: () {}, // Prevent taps from passing through
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),

            // Skip button (top-right)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: _buildSkipButton(localizations),
            ),

            // Tutorial content
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildStepContent(localizations),
              ),
            ),

            // Highlight elements for interactive steps
            if (_currentStep == 1) _buildPieceHighlight(),
            if (_currentStep == 1) _buildArrowToBoad(),
          ],
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

  /// Highlight circle around first piece in tray
  Widget _buildPieceHighlight() {
    return Positioned(
      bottom: 100,
      left: MediaQuery.of(context).size.width * 0.15,
      child: const _PulsingHighlight(
        size: 80,
        color: Colors.amber,
      ),
    );
  }

  /// Arrow pointing from piece to board
  Widget _buildArrowToBoad() {
    return Positioned(
      bottom: 180,
      left: MediaQuery.of(context).size.width * 0.25,
      child: Transform.rotate(
        angle: -0.5, // Point upward-right
        child: const Icon(
          Icons.arrow_upward,
          color: Colors.amber,
          size: 60,
        ),
      ),
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
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(24),
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 40,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  buttonText!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Before: Full row
          Column(
            children: [
              _buildMiniGrid(highlightRow: true),
              const SizedBox(height: 4),
              Text(
                'Before',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(width: 16),
          const Icon(Icons.arrow_forward, color: Colors.green),
          const SizedBox(width: 16),
          // After: Cleared
          Column(
            children: [
              _buildMiniGrid(cleared: true),
              const SizedBox(height: 4),
              Text(
                'After',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
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
      padding: const EdgeInsets.all(16),
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
          _buildComboLevel('x1', Colors.grey, '10 pts'),
          const Icon(Icons.arrow_forward, color: Colors.orange),
          _buildComboLevel('x2', Colors.orange, '20 pts'),
          const Icon(Icons.arrow_forward, color: Colors.red),
          _buildComboLevel('x3', Colors.red, '30 pts'),
        ],
      ),
    );
  }

  Widget _buildComboLevel(String level, Color color, String points) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            level,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          points,
          style: TextStyle(
            fontSize: 11,
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMiniPiece(Colors.blue, [[1, 1], [1, 0]]),
              const SizedBox(width: 16),
              _buildMiniPiece(Colors.red, [[1], [1], [1]]),
              const SizedBox(width: 16),
              _buildMiniPiece(Colors.green, [[1, 1]]),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber, color: Colors.red[400], size: 16),
              const SizedBox(width: 4),
              Text(
                'No space for pieces = Game Over!',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[600],
                  fontWeight: FontWeight.w500,
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
