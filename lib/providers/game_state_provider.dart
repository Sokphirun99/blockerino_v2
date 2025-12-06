import 'package:flutter/material.dart';
import '../models/board.dart';
import '../models/piece.dart';
import '../models/game_mode.dart';
import 'settings_provider.dart';

class GameStateProvider extends ChangeNotifier {
  Board? _board;
  List<Piece> _hand = [];
  int _score = 0;
  int _combo = 0;
  int _lastBrokenLine = 0;
  GameMode _gameMode = GameMode.classic;
  bool _gameOver = false;
  final SettingsProvider? _settingsProvider;

  Board? get board => _board;
  List<Piece> get hand => _hand;
  int get score => _score;
  int get combo => _combo;
  bool get gameOver => _gameOver;
  GameMode get gameMode => _gameMode;
  int get movesUntilComboReset => _lastBrokenLine;

  GameStateProvider({SettingsProvider? settingsProvider})
      : _settingsProvider = settingsProvider;

  void startGame(GameMode mode) {
    _gameMode = mode;
    final config = GameModeConfig.fromMode(mode);
    _board = Board(size: config.boardSize);
    _hand = _generateRandomHand(config.handSize);
    _score = 0;
    _combo = 0;
    _lastBrokenLine = 0;
    _gameOver = false;
    notifyListeners();
  }

  List<Piece> _generateRandomHand(int count) {
    return PieceLibrary.createRandomHand(count);
  }

  void clearHoverBlocks() {
    _board?.clearHoverBlocks();
    notifyListeners();
  }

  void showHoverPreview(Piece piece, int x, int y) {
    if (_board == null) return;
    
    _board!.clearHoverBlocks();
    
    if (_board!.canPlacePiece(piece, x, y)) {
      _board!.updateHoveredBreaks(piece, x, y);
      notifyListeners();
    }
  }

  bool placePiece(Piece piece, int x, int y) {
    if (_board == null) return false;
    if (!_board!.canPlacePiece(piece, x, y)) return false;

    // Clear hover blocks and place the piece
    _board!.clearHoverBlocks();
    _board!.placePiece(piece, x, y, type: BlockType.filled);

    // Calculate score from placing blocks
    final pieceBlockCount = piece.getBlockCount();
    _score += pieceBlockCount;

    // Break lines and calculate combo
    final linesBroken = _board!.breakLines();
    if (linesBroken > 0) {
      _lastBrokenLine = 0;
      _combo += linesBroken;
      // Score calculation matching blockerino-master:
      // linesBroken * boardSize * (combo / 2) * pieceBlockCount
      final config = GameModeConfig.fromMode(_gameMode);
      _score += (linesBroken * config.boardSize * (_combo / 2) * pieceBlockCount).round();
    } else {
      _lastBrokenLine++;
      final config = GameModeConfig.fromMode(_gameMode);
      if (_lastBrokenLine >= config.handSize) {
        _combo = 0;
      }
    }

    // Remove the piece from hand
    _hand.removeWhere((p) => p.id == piece.id);

    // Refill hand if empty
    if (_hand.isEmpty) {
      final config = GameModeConfig.fromMode(_gameMode);
      _hand = _generateRandomHand(config.handSize);
    }

    // Check for game over
    if (!_board!.hasAnyValidMove(_hand)) {
      _gameOver = true;
      // Update high score
      _settingsProvider?.updateHighScore(_score);
    }

    notifyListeners();
    return true;
  }

  void resetGame() {
    startGame(_gameMode);
  }
}
