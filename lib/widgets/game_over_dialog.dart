import 'package:flutter/material.dart';

/// Enhanced game over dialog with animations and detailed stats
class GameOverDialog extends StatefulWidget {
  final int finalScore;
  final int highScore;
  final int linesCleared;
  final int maxCombo;
  final bool isNewHighScore;
  final VoidCallback onReplay;
  final VoidCallback onMainMenu;
  final int? coinsEarned;
  final double? streakMultiplier;

  const GameOverDialog({
    super.key,
    required this.finalScore,
    required this.highScore,
    required this.linesCleared,
    required this.maxCombo,
    required this.isNewHighScore,
    required this.onReplay,
    required this.onMainMenu,
    this.coinsEarned,
    this.streakMultiplier,
  });

  @override
  State<GameOverDialog> createState() => _GameOverDialogState();
}

class _GameOverDialogState extends State<GameOverDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Slide up animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Scale animation for new high score celebration
    _scaleAnimation = Tween<double>(
      begin: widget.isNewHighScore ? 0.8 : 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    // Start animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNewHighScore = widget.isNewHighScore;
    
    // Choose colors based on high score status
    final List<Color> gradientColors = isNewHighScore
        ? [const Color(0xFFFFD700), const Color(0xFFFFA500)] // Gold
        : [const Color(0xFF2d2d44), const Color(0xFF1a1a2e)]; // Dark blue
    
    final Color borderColor = isNewHighScore
        ? const Color(0xFFFFD700)
        : Colors.white;
    
    final Color shadowColor = isNewHighScore
        ? const Color(0xFFFFD700).withValues(alpha: 0.5)
        : const Color(0xFF4ECDC4).withValues(alpha: 0.3);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SlideTransition(
            position: _slideAnimation,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: borderColor,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      isNewHighScore ? '🎉 NEW HIGH SCORE!' : 'GAME OVER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // Score display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'FINAL SCORE',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.finalScore}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: isNewHighScore 
                                      ? Colors.orange.withValues(alpha: 0.8)
                                      : Colors.cyan.withValues(alpha: 0.8),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Stats row
                    Row(
                      children: [
                        // Lines cleared
                        Expanded(
                          child: _buildStatCard(
                            '📊',
                            '${widget.linesCleared}',
                            'LINES',
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Max combo
                        Expanded(
                          child: _buildStatCard(
                            '🔥',
                            '×${widget.maxCombo}',
                            'MAX COMBO',
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // High score
                        Expanded(
                          child: _buildStatCard(
                            '🏆',
                            '${widget.highScore}',
                            'HIGH SCORE',
                          ),
                        ),
                      ],
                    ),

                    // Coins earned (if provided)
                    if (widget.coinsEarned != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🪙', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              '+${widget.coinsEarned} coins',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (widget.streakMultiplier != null && widget.streakMultiplier! > 1.0) ...[
                              const SizedBox(width: 8),
                              Text(
                                '(×${widget.streakMultiplier!.toStringAsFixed(1)} streak)',
                                style: TextStyle(
                                  color: Colors.orange.shade300,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        // Home button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onMainMenu,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.8),
                                width: 2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'HOME',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Play again button (2x width)
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: widget.onReplay,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isNewHighScore 
                                  ? Colors.white 
                                  : const Color(0xFF4ECDC4),
                              foregroundColor: isNewHighScore 
                                  ? const Color(0xFFFFD700) 
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              'PLAY AGAIN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build a stat card with icon, value, and label
  Widget _buildStatCard(String icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}