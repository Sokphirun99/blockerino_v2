import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/game/game_cubit.dart';
import '../cubits/game/game_state.dart';
import '../models/piece.dart';
import 'draggable_piece_widget.dart';

class HandPiecesWidget extends StatelessWidget {
  const HandPiecesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        if (state is! GameInProgress) return const SizedBox.shrink();
        final hand = state.hand;
        final board = state.board;
        
        // Check if each piece can be placed anywhere
        bool canPlacePiece(Piece piece) {
          for (int row = 0; row < board.size; row++) {
            for (int col = 0; col < board.size; col++) {
              if (board.canPlacePiece(piece, col, row)) {
                return true;
              }
            }
          }
          return false;
        }
        
        // Clean design like Block Blast - no container, just pieces on background
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: hand.map((piece) {
                final canPlace = canPlacePiece(piece);
                return Expanded(
                  child: Center(
                    child: Opacity(
                      opacity: canPlace ? 1.0 : 0.5, // Grey out if can't be placed
                      child: DraggablePieceWidget(piece: piece),
                    ),
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
