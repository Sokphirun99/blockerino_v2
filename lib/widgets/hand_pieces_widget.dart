import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/game/game_cubit.dart';
import '../cubits/game/game_state.dart';
import '../models/piece.dart';
import 'draggable_piece_widget.dart';

// #region agent log - File logging helper
void _writeLogToFile(
    String location, String message, Map<String, dynamic> data) {
  try {
    const logPath =
        '/Users/phirun/Projects_Personal/BlockerinoV2/blockerino_v2/.cursor/debug.log';
    final logFile = File(logPath);
    final logDir = logFile.parent;

    // Ensure directory exists
    if (!logDir.existsSync()) {
      logDir.createSync(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final logEntry = {
      'id': 'log_${timestamp}_${data.hashCode}',
      'timestamp': timestamp,
      'location': location,
      'message': message,
      'data': data,
      'sessionId': 'debug-session',
      'runId': 'run1',
      'hypothesisId': 'A',
    };
    final jsonLine = jsonEncode(logEntry);
    final existingContent =
        logFile.existsSync() ? logFile.readAsStringSync() : '';
    logFile.writeAsStringSync(
        '${existingContent.isNotEmpty ? "$existingContent\n" : ""}$jsonLine',
        mode: FileMode.write);
  } catch (e) {
    // Log error to console if file write fails
    debugPrint('[DEBUG:FILE_LOG_ERROR] Failed to write log: $e');
  }
}
// #endregion

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
          // #region agent log - Track piece placement validation
          int validPositions = 0;
          int totalChecks = 0;
          // #endregion

          for (int row = 0; row < board.size; row++) {
            for (int col = 0; col < board.size; col++) {
              totalChecks++;
              if (board.canPlacePiece(piece, col, row)) {
                validPositions++;
                // #region agent log - Found valid position, early exit
                debugPrint(
                    '[DEBUG:HAND] canPlacePiece: piece=${piece.id} CAN be placed at col=$col, row=$row');
                _writeLogToFile(
                    'hand_pieces_widget.dart:32', 'canPlacePiece - VALID', {
                  'pieceId': piece.id,
                  'col': col,
                  'row': row,
                  'totalChecks': totalChecks,
                });
                // #endregion
                return true;
              }
            }
          }

          // #region agent log - Piece cannot be placed anywhere
          debugPrint(
              '[DEBUG:HAND] canPlacePiece: piece=${piece.id} CANNOT be placed (checked $totalChecks positions, found $validPositions valid)');
          _writeLogToFile(
              'hand_pieces_widget.dart:41', 'canPlacePiece - INVALID', {
            'pieceId': piece.id,
            'totalChecks': totalChecks,
            'validPositions': validPositions,
            'boardSize': board.size,
          });
          // #endregion
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
                // #region agent log - Track piece rendering state
                debugPrint(
                    '[DEBUG:HAND] Rendering piece: id=${piece.id}, canPlace=$canPlace, opacity=${canPlace ? 1.0 : 0.5}, shape=${piece.shape.length}x${piece.shape.isNotEmpty ? piece.shape[0].length : 0}');
                _writeLogToFile(
                    'hand_pieces_widget.dart:58', 'Rendering piece', {
                  'pieceId': piece.id,
                  'canPlace': canPlace,
                  'opacity': canPlace ? 1.0 : 0.5,
                  'shapeHeight': piece.shape.length,
                  'shapeWidth':
                      piece.shape.isNotEmpty ? piece.shape[0].length : 0,
                });
                // #endregion
                return Expanded(
                  child: Center(
                    child: Opacity(
                      opacity:
                          canPlace ? 1.0 : 0.5, // Grey out if can't be placed
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
