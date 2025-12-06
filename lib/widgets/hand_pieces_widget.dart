import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_state_provider.dart';
import 'draggable_piece_widget.dart';

class HandPiecesWidget extends StatelessWidget {
  const HandPiecesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameStateProvider>(
      builder: (context, gameState, child) {
        final hand = gameState.hand;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          constraints: const BoxConstraints(
            minHeight: 120,
            maxHeight: 200,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: hand.map((piece) {
              return Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  constraints: const BoxConstraints(
                    maxWidth: 140,
                    maxHeight: 180,
                  ),
                  child: DraggablePieceWidget(piece: piece),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
