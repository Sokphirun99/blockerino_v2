enum GameMode {
  classic,
  chaos,
  story, // Story mode (uses classic config but separate save state)
}

class GameModeConfig {
  final int boardSize;
  final int handSize;
  final String name;

  const GameModeConfig({
    required this.boardSize,
    required this.handSize,
    required this.name,
  });

  static const GameModeConfig classic = GameModeConfig(
    boardSize: 8,
    handSize: 3,
    name: 'Classic',
  );

  static const GameModeConfig chaos = GameModeConfig(
    boardSize: 10,
    handSize: 5,
    name: 'Chaos',
  );

  static GameModeConfig fromMode(GameMode mode) {
    switch (mode) {
      case GameMode.classic:
        return classic;
      case GameMode.chaos:
        return chaos;
      case GameMode.story:
        return classic; // Story uses classic config (8x8, 3 pieces)
    }
  }
}

class HighScore {
  final int score;
  final DateTime date;
  final GameMode mode;

  HighScore({
    required this.score,
    required this.date,
    required this.mode,
  });

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'date': date.millisecondsSinceEpoch,
      'mode': mode.index,
    };
  }

  factory HighScore.fromJson(Map<String, dynamic> json) {
    return HighScore(
      score: json['score'] as int,
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      mode: GameMode.values[json['mode'] as int],
    );
  }
}
