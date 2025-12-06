import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import '../models/game_mode.dart';

class GameHudWidget extends StatelessWidget {
  const GameHudWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameStateProvider>(
      builder: (context, gameState, child) {
        final config = GameModeConfig.fromMode(gameState.gameMode);
        final movesLeft = config.handSize - gameState.movesUntilComboReset;
        final comboProgress = gameState.combo > 0 ? movesLeft / config.handSize : 0.0;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'SCORE',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
            ),
            Text(
              '${gameState.score}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (gameState.combo > 1) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE66D).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFFFE66D)),
                ),
                child: Text(
                  'COMBO x${gameState.combo}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFFFE66D),
                        fontSize: 10,
                      ),
                ),
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
                      flex: (comboProgress * 100).round(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE66D),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: ((1 - comboProgress) * 100).round(),
                      child: const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$movesLeft moves left',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white60,
                      fontSize: 8,
                    ),
              ),
            ],
          ],
        );
      },
    );
  }
}
