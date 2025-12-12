import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/game/game_cubit.dart';
import '../cubits/game/game_state.dart';
import 'draggable_piece_widget.dart';

class HandPiecesWidget extends StatelessWidget {
  const HandPiecesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        if (state is! GameInProgress) return const SizedBox.shrink();
        final hand = state.hand;
        
        // Clean design like Block Blast - no container, just pieces on background
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: hand.map((piece) {
                return Expanded(
                  child: Center(
                    child: DraggablePieceWidget(piece: piece),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
