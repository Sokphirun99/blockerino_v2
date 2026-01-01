/// Model for tracking daily login streaks
class DailyStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime lastPlayedDate;
  final List<DateTime> playedDates; // Last 7 days

  const DailyStreak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    DateTime? lastPlayedDate,
    List<DateTime>? playedDates,
  })  : lastPlayedDate = lastPlayedDate ?? const _DefaultDateTime(),
        playedDates = playedDates ?? const [];

  /// Check if streak is active (played yesterday or today)
  bool get isActive {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastPlayed = DateTime(
      lastPlayedDate.year,
      lastPlayedDate.month,
      lastPlayedDate.day,
    );

    return lastPlayed == today || lastPlayed == yesterday;
  }

  /// Get reward multiplier based on streak length
  double get rewardMultiplier {
    if (currentStreak >= 30) return 3.0;
    if (currentStreak >= 14) return 2.5;
    if (currentStreak >= 7) return 2.0;
    if (currentStreak >= 3) return 1.5;
    return 1.0;
  }

  /// Get icon based on streak length
  String get icon {
    if (currentStreak >= 30) return '🏆';
    if (currentStreak >= 14) return '💎';
    if (currentStreak >= 7) return '🔥';
    if (currentStreak >= 3) return '⭐';
    return '🎯';
  }

  /// Update streak for today's play
  DailyStreak updateForToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastPlayed = DateTime(
      lastPlayedDate.year,
      lastPlayedDate.month,
      lastPlayedDate.day,
    );

    // Already played today - no change
    if (lastPlayed == today) {
      return this;
    }

    int newStreak;
    int newLongest = longestStreak;

    // Played yesterday - continue streak
    if (lastPlayed == yesterday) {
      newStreak = currentStreak + 1;
      if (newStreak > newLongest) {
        newLongest = newStreak;
      }
    } else {
      // Streak broken - reset to 1
      newStreak = 1;
      if (newStreak > newLongest) {
        newLongest = newStreak;
      }
    }

    // Update played dates (keep last 7)
    final newPlayedDates = List<DateTime>.from(playedDates);
    newPlayedDates.add(today);

    // Remove dates older than 7 days
    final sevenDaysAgo = today.subtract(const Duration(days: 7));
    newPlayedDates.removeWhere((date) => date.isBefore(sevenDaysAgo));

    return DailyStreak(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastPlayedDate: today,
      playedDates: newPlayedDates,
    );
  }

  /// Check if a specific date was played
  bool wasPlayedOn(DateTime date) {
    final checkDate = DateTime(date.year, date.month, date.day);
    return playedDates.any((d) =>
        d.year == checkDate.year &&
        d.month == checkDate.month &&
        d.day == checkDate.day);
  }

  /// Convert to JSON for SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastPlayedDate': lastPlayedDate.millisecondsSinceEpoch,
      'playedDates': playedDates
          .map((d) => d.millisecondsSinceEpoch)
          .toList(),
    };
  }

  /// Create from JSON
  factory DailyStreak.fromJson(Map<String, dynamic> json) {
    return DailyStreak(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastPlayedDate: json['lastPlayedDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastPlayedDate'] as int)
          : DateTime.now(),
      playedDates: (json['playedDates'] as List<dynamic>?)
              ?.map((e) => DateTime.fromMillisecondsSinceEpoch(e as int))
              .toList() ??
          [],
    );
  }

  /// Create a copy with updated fields
  DailyStreak copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastPlayedDate,
    List<DateTime>? playedDates,
  }) {
    return DailyStreak(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      playedDates: playedDates ?? this.playedDates,
    );
  }

  @override
  String toString() {
    return 'DailyStreak(current: $currentStreak, longest: $longestStreak, '
        'lastPlayed: $lastPlayedDate, isActive: $isActive)';
  }
}

/// Helper class for default DateTime in const constructor
class _DefaultDateTime implements DateTime {
  const _DefaultDateTime();

  DateTime get _now => DateTime.now();

  @override
  int get year => _now.year;
  @override
  int get month => _now.month;
  @override
  int get day => _now.day;
  @override
  int get hour => _now.hour;
  @override
  int get minute => _now.minute;
  @override
  int get second => _now.second;
  @override
  int get millisecond => _now.millisecond;
  @override
  int get microsecond => _now.microsecond;
  @override
  int get weekday => _now.weekday;
  @override
  bool get isUtc => _now.isUtc;
  @override
  int get millisecondsSinceEpoch => _now.millisecondsSinceEpoch;
  @override
  int get microsecondsSinceEpoch => _now.microsecondsSinceEpoch;
  @override
  String get timeZoneName => _now.timeZoneName;
  @override
  Duration get timeZoneOffset => _now.timeZoneOffset;

  @override
  DateTime add(Duration duration) => _now.add(duration);
  @override
  DateTime subtract(Duration duration) => _now.subtract(duration);
  @override
  Duration difference(DateTime other) => _now.difference(other);
  @override
  bool isAfter(DateTime other) => _now.isAfter(other);
  @override
  bool isBefore(DateTime other) => _now.isBefore(other);
  @override
  bool isAtSameMomentAs(DateTime other) => _now.isAtSameMomentAs(other);
  @override
  int compareTo(DateTime other) => _now.compareTo(other);
  @override
  DateTime toLocal() => _now.toLocal();
  @override
  DateTime toUtc() => _now.toUtc();
  @override
  String toIso8601String() => _now.toIso8601String();
  @override
  String toString() => _now.toString();
}
