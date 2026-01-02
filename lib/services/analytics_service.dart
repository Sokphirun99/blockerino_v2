import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

void _log(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Game Events
  Future<void> logGameStart(String gameMode) async {
    try {
      await _analytics.logEvent(
        name: AppConfig.eventGameStart,
        parameters: {
          'game_mode': gameMode,
        },
      );
    } catch (e) {
      _log('Error logging game start: $e');
    }
  }

  Future<void> logGameEnd({
    required String gameMode,
    required int score,
    required int linesCleared,
    required int duration,
  }) async {
    try {
      await _analytics.logEvent(
        name: AppConfig.eventGameEnd,
        parameters: {
          'game_mode': gameMode,
          'score': score,
          'lines_cleared': linesCleared,
          'duration_seconds': duration,
        },
      );
    } catch (e) {
      _log('Error logging game end: $e');
    }
  }

  Future<void> logLevelComplete({
    required int levelNumber,
    required int stars,
    required int score,
  }) async {
    try {
      await _analytics.logEvent(
        name: AppConfig.eventLevelComplete,
        parameters: {
          'level_number': levelNumber,
          'stars': stars,
          'score': score,
        },
      );
    } catch (e) {
      _log('Error logging level complete: $e');
    }
  }

  Future<void> logPowerUpUsed(String powerUpType) async {
    try {
      await _analytics.logEvent(
        name: AppConfig.eventPowerUpUsed,
        parameters: {
          'power_up_type': powerUpType,
        },
      );
    } catch (e) {
      _log('Error logging power up used: $e');
    }
  }

  Future<void> logPurchase({
    required String itemName,
    required int coinCost,
  }) async {
    try {
      await _analytics.logEvent(
        name: AppConfig.eventStorePurchase,
        parameters: {
          'item_name': itemName,
          'coin_cost': coinCost,
          'currency': 'coins',
        },
      );
    } catch (e) {
      _log('Error logging purchase: $e');
    }
  }

  Future<void> logDailyChallengeStart() async {
    try {
      await _analytics.logEvent(name: 'daily_challenge_start');
    } catch (e) {
      _log('Error logging daily challenge start: $e');
    }
  }

  Future<void> logDailyChallengeComplete(int score) async {
    try {
      await _analytics.logEvent(
        name: 'daily_challenge_complete',
        parameters: {
          'score': score,
        },
      );
    } catch (e) {
      _log('Error logging daily challenge complete: $e');
    }
  }

  Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      _log('Error logging screen view: $e');
    }
  }

  Future<void> logSignIn(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
    } catch (e) {
      _log('Error logging sign in: $e');
    }
  }

  Future<void> logTutorialBegin() async {
    try {
      await _analytics.logTutorialBegin();
    } catch (e) {
      _log('Error logging tutorial begin: $e');
    }
  }

  Future<void> logTutorialComplete() async {
    try {
      await _analytics.logTutorialComplete();
    } catch (e) {
      _log('Error logging tutorial complete: $e');
    }
  }

  // Set user properties
  Future<void> setUserProperty(String name, String value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      _log('Error setting user property: $e');
    }
  }

  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      _log('Error setting user ID: $e');
    }
  }
}
