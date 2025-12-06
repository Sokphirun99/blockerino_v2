import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../providers/game_state_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/board_grid_widget.dart';
import '../widgets/hand_pieces_widget.dart';
import '../widgets/game_hud_widget.dart';
import '../widgets/draggable_piece_widget.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.purple.shade900.withValues(alpha: 0.2),
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
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const GameHudWidget(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Game Board with DragTarget - wrapped in Expanded to constrain size
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return const BoardDragTarget(
                            child: BoardGridWidget(),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Hand Pieces
                  const HandPiecesWidget(),
                  
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showGameOverDialog(BuildContext context, GameStateProvider gameState) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    if (settings.hapticsEnabled) {
      Vibration.vibrate(duration: 500);
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'GAME OVER',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFFFF6B6B),
                fontSize: 24,
              ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Final Score',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${gameState.score}',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 48,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to menu
            },
            child: const Text('MENU'),
          ),
          ElevatedButton(
            onPressed: () {
              gameState.resetGame();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ECDC4),
            ),
            child: const Text('PLAY AGAIN'),
          ),
        ],
      ),
    );
  }
}
