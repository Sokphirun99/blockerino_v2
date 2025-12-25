import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../models/power_up.dart';
import '../../models/game_theme.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/analytics_service.dart';
import '../../services/database_helper.dart';
import '../../services/sound_service.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  // Firebase services
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Firebase getters
  FirebaseAuthService get authService => _authService;
  FirestoreService get firestoreService => _firestoreService;
  AnalyticsService get analyticsService => _analyticsService;

  SettingsCubit() : super(SettingsState.initial());

  Future<void> initialize() async {
    await _loadSettings();
    await _initializeFirebase();
  }

  Future<void> _restoreFromFirestore(String uid) async {
    try {
      final profile = await _firestoreService.getUserProfile(uid);
      if (profile != null) {
        emit(state.copyWith(
          highScore: profile['totalScore'] ?? state.highScore,
          coins: profile['coins'] ?? state.coins,
        ));
      }
      // Optionally restore story progress here if needed
    } catch (e) {
      // Handle error (log, fallback, etc.)
    }
  }

  Future<void> _initializeFirebase() async {
    try {
      // Sign in anonymously if not signed in
      // CRITICAL FIX: Handle network errors gracefully - app should work offline
      if (_authService.currentUser == null) {
        // Add timeout to prevent hanging on slow/poor network connections
        await _authService.signInAnonymously().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('Firebase sign-in timeout - continuing offline');
            return null;
          },
        );
      }

      // Set user ID for analytics only if sign-in succeeded
      final uid = _authService.currentUser?.uid;
      if (uid != null) {
        try {
          await _analyticsService.setUserId(uid);
          // Restore cloud data before syncing (with timeout)
          await _restoreFromFirestore(uid).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint(
                  'Firestore restore timeout - continuing with local data');
            },
          );
          // Sync to Firestore (with timeout, don't block)
          _syncToFirestore().timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('Firestore sync timeout - will retry later');
            },
          ).catchError((e) {
            debugPrint('Firestore sync error (non-fatal): $e');
          });
        } catch (e) {
          // Non-fatal: Log error but continue - app works offline
          debugPrint('Firebase initialization error (non-fatal): $e');
        }
      } else {
        // No user signed in - app continues in offline mode
        debugPrint('No Firebase user - app running in offline mode');
      }

      // Listen to auth state changes (with error handling)
      _authService.authStateChanges.listen(
        (user) {
          if (user != null) {
            // Handle auth state changes asynchronously with error handling
            _restoreFromFirestore(user.uid).catchError((e) {
              debugPrint('Error restoring from Firestore (non-fatal): $e');
            });
            _syncToFirestore().catchError((e) {
              debugPrint('Error syncing to Firestore (non-fatal): $e');
            });
            _analyticsService.setUserId(user.uid).catchError((e) {
              debugPrint('Error setting analytics user ID (non-fatal): $e');
            });
          }
        },
        onError: (error) {
          // Handle stream errors gracefully
          debugPrint('Auth state stream error (non-fatal): $error');
        },
      );
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
      // Continue without Firebase features
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load simple settings from SharedPreferences
    final soundEnabled = prefs.getBool('soundEnabled') ?? true;
    final hapticsEnabled = prefs.getBool('hapticsEnabled') ?? true;
    final animationsEnabled = prefs.getBool('animationsEnabled') ?? true;
    final highScore = prefs.getInt('highScore') ?? 0;
    final coins = prefs.getInt('coins') ?? 0;
    final completedChallengeIds =
        prefs.getStringList('completedChallenges') ?? [];
    final currentStoryLevel = prefs.getInt('currentStoryLevel') ?? 1;

    // Load language preference
    final languageCode = prefs.getString(AppConfig.languagePrefsKey);
    final currentLocale = languageCode != null
        ? Locale(languageCode, '')
        : AppConfig.defaultLocale;

    // Load theme preferences
    final selectedThemeId = prefs.getString('selectedThemeId') ?? 'classic';
    final unlockedThemeIds = prefs.getStringList('unlockedThemeIds') ??
        ['classic', 'high_contrast']; // Classic + Accessibility free

    // Migrate data from SharedPreferences to SQLite if needed
    await _migrateToSQLite(prefs);

    // Load power-ups and story progress from SQLite
    final powerUpInventory = await _dbHelper.getAllInventory();
    final storyLevelStars = await _dbHelper.getAllLevelStars();

    emit(SettingsState(
      soundEnabled: soundEnabled,
      hapticsEnabled: hapticsEnabled,
      animationsEnabled: animationsEnabled,
      highScore: highScore,
      coins: coins,
      powerUpInventory: powerUpInventory,
      completedChallengeIds: completedChallengeIds,
      storyLevelStars: storyLevelStars,
      currentStoryLevel: currentStoryLevel,
      currentLocale: currentLocale,
      selectedThemeId: selectedThemeId,
      unlockedThemeIds: unlockedThemeIds,
    ));
  }

  Future<void> _migrateToSQLite(SharedPreferences prefs) async {
    final migrated = prefs.getBool('sqliteMigrated') ?? false;
    if (migrated) return;

    // Migrate power-ups
    final powerUpKeys = [
      'powerup_shuffle',
      'powerup_wildPiece',
      'powerup_lineClear',
      'powerup_bomb',
      'powerup_colorBomb',
    ];

    for (final key in powerUpKeys) {
      final count = prefs.getInt(key) ?? 0;
      if (count > 0) {
        final typeName = key.replaceFirst('powerup_', '');
        try {
          final type = PowerUpType.values.firstWhere(
            (t) => t.name == typeName,
          );
          await _dbHelper.addPowerUp(type, count);
          await prefs.remove(key);
        } catch (e) {
          debugPrint('Error migrating power-up $key: $e');
        }
      }
    }

    // Migrate story progress
    final storyKeys =
        prefs.getKeys().where((k) => k.startsWith('story_level_'));
    for (final key in storyKeys) {
      final levelNumber = int.tryParse(key.replaceFirst('story_level_', ''));
      final stars = prefs.getInt(key) ?? 0;
      if (levelNumber != null && stars > 0) {
        await _dbHelper.updateLevelProgress(
          levelNumber: levelNumber,
          stars: stars,
          score: 0,
        );
        await prefs.remove(key);
      }
    }

    await prefs.setBool('sqliteMigrated', true);
  }

  Future<void> _syncToFirestore() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    try {
      // Sync high score and coins
      await _firestoreService.updateUserProfile(uid, {
        'totalScore': state.highScore,
        'coins': state.coins,
      });

      // Sync story progress
      for (final entry in state.storyLevelStars.entries) {
        await _firestoreService.saveStoryProgress(
          uid: uid,
          levelNumber: entry.key,
          stars: entry.value,
          score: 0,
        );
      }
    } catch (e) {
      debugPrint('Error syncing to Firestore: $e');
    }
  }

  // Coin management
  Future<void> addCoins(int amount) async {
    final newCoins = state.coins + amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', newCoins);

    // Sync to Firestore
    final uid = _authService.currentUser?.uid;
    if (uid != null) {
      await _firestoreService.addCoins(uid, amount);
    }

    emit(state.copyWith(coins: newCoins));
  }

  Future<void> spendCoins(int amount) async {
    if (state.coins >= amount) {
      // CRITICAL FIX: Use optimistic update to prevent double-spend exploit
      // Update UI state immediately, then sync to database in background
      // This prevents rapid taps from passing the coin check multiple times
      final oldCoins = state.coins;
      final newCoins = state.coins - amount;

      // 1. Optimistic Update: Update UI immediately
      emit(state.copyWith(coins: newCoins));

      // 2. Perform Background Work (database sync)
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('coins', newCoins);

        // Sync to Firestore
        final uid = _authService.currentUser?.uid;
        if (uid != null) {
          await _firestoreService.spendCoins(uid, amount);
        }
      } catch (e) {
        // Rollback on error to maintain data consistency
        debugPrint('Error spending coins, rolling back: $e');
        emit(state.copyWith(coins: oldCoins));
        rethrow; // Re-throw to allow caller to handle the error
      }
    }
  }

  // Power-up management (using SQLite)
  Future<void> addPowerUp(PowerUpType type, int count) async {
    await _dbHelper.addPowerUp(type, count);
    final newInventory = await _dbHelper.getAllInventory();
    emit(state.copyWith(powerUpInventory: newInventory));
  }

  Future<bool> usePowerUp(PowerUpType type) async {
    final success = await _dbHelper.usePowerUp(type);

    if (success) {
      final newInventory = await _dbHelper.getAllInventory();

      // Track power-up usage
      await _analyticsService.logPowerUpUsed(type.name);

      emit(state.copyWith(powerUpInventory: newInventory));
      return true;
    }
    return false;
  }

  Future<bool> buyPowerUp(PowerUpType type) async {
    final powerUp = PowerUp.fromType(type);
    if (powerUp == null) return false;

    if (state.coins >= powerUp.cost) {
      // FIX: Use spendCoins to ensure server sync
      // This properly sends the negative amount to Firestore
      await spendCoins(powerUp.cost);

      // Add to inventory (SQLite + State)
      await addPowerUp(type, 1);

      return true;
    }
    return false;
  }

  int getPowerUpCount(PowerUpType type) {
    return state.powerUpInventory[type] ?? 0;
  }

  // Challenge management
  Future<void> completeChallenge(String challengeId, int coinReward) async {
    if (!state.completedChallengeIds.contains(challengeId)) {
      final newCompletedChallenges =
          List<String>.from(state.completedChallengeIds)..add(challengeId);
      await addCoins(coinReward);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('completedChallenges', newCompletedChallenges);
      emit(state.copyWith(completedChallengeIds: newCompletedChallenges));
    }
  }

  bool isChallengeCompleted(String challengeId) {
    return state.completedChallengeIds.contains(challengeId);
  }

  // Story mode management (using SQLite)
  Future<void> completeStoryLevel(
      int levelNumber, int stars, int coinReward) async {
    final currentStars = await _dbHelper.getLevelStars(levelNumber);

    if (stars > currentStars) {
      // Update in SQLite
      await _dbHelper.updateLevelProgress(
        levelNumber: levelNumber,
        stars: stars,
        score: 0,
      );

      // Refresh local cache
      final newStoryLevelStars = await _dbHelper.getAllLevelStars();

      await addCoins(coinReward);

      // Unlock next level
      int newCurrentStoryLevel = state.currentStoryLevel;
      if (levelNumber >= state.currentStoryLevel) {
        newCurrentStoryLevel = levelNumber + 1;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('currentStoryLevel', newCurrentStoryLevel);
      }

      // Sync to Firestore
      final uid = _authService.currentUser?.uid;
      if (uid != null) {
        await _firestoreService.saveStoryProgress(
          uid: uid,
          levelNumber: levelNumber,
          stars: stars,
          score: 0,
        );
      }

      // Log to Analytics
      await _analyticsService.logLevelComplete(
        levelNumber: levelNumber,
        stars: stars,
        score: 0,
      );

      emit(state.copyWith(
        storyLevelStars: newStoryLevelStars,
        currentStoryLevel: newCurrentStoryLevel,
      ));
    }
  }

  int getStarsForLevel(int levelNumber) {
    return state.storyLevelStars[levelNumber] ?? 0;
  }

  bool isStoryLevelUnlocked(int levelNumber) {
    return levelNumber <= state.currentStoryLevel;
  }

  // Settings toggles
  Future<void> setSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', value);

    // FIX: Apply change immediately to SoundService singleton
    // SoundService() uses factory pattern to return the singleton instance
    SoundService().setSoundEnabled(value);

    emit(state.copyWith(soundEnabled: value));
  }

  Future<void> setHapticsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hapticsEnabled', value);

    // FIX: Apply change immediately to SoundService singleton
    // SoundService() uses factory pattern to return the singleton instance
    SoundService().setHapticsEnabled(value);

    emit(state.copyWith(hapticsEnabled: value));
  }

  Future<void> setAnimationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('animationsEnabled', value);
    emit(state.copyWith(animationsEnabled: value));
  }

  Future<void> toggleSound() async {
    await setSoundEnabled(!state.soundEnabled);
  }

  Future<void> toggleHaptics() async {
    await setHapticsEnabled(!state.hapticsEnabled);
  }

  Future<void> toggleAnimations() async {
    await setAnimationsEnabled(!state.animationsEnabled);
  }

  Future<void> clearAllData() async {
    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Clear SQLite database
    await _dbHelper.clearAllData();

    // Reset to initial state
    emit(SettingsState.initial());
  }

  Future<void> updateHighScore(int newScore) async {
    if (newScore > state.highScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('highScore', newScore);

      // Sync to Firestore
      final uid = _authService.currentUser?.uid;
      if (uid != null) {
        await _firestoreService.updateUserProfile(uid, {
          'totalScore': newScore,
        });
      }

      emit(state.copyWith(highScore: newScore));
    }
  }

  Future<void> resetHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', 0);
    emit(state.copyWith(highScore: 0));
  }

  /// Change app language
  Future<void> changeLanguage(Locale locale) async {
    if (!AppConfig.supportedLocales.contains(locale)) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.languagePrefsKey, locale.languageCode);

    emit(state.copyWith(currentLocale: locale));
  }

  // ============================================================================
  // THEME MANAGEMENT
  // ============================================================================

  /// Select a theme (must be unlocked)
  Future<bool> selectTheme(String themeId) async {
    if (!state.unlockedThemeIds.contains(themeId)) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedThemeId', themeId);

    emit(state.copyWith(selectedThemeId: themeId));
    return true;
  }

  /// Purchase and unlock a theme
  Future<bool> purchaseTheme(String themeId) async {
    // Already unlocked
    if (state.unlockedThemeIds.contains(themeId)) {
      return true;
    }

    final theme = GameTheme.getThemeById(themeId);

    // Check if player has enough coins
    if (state.coins < theme.cost) {
      return false;
    }

    // CRITICAL FIX: Use optimistic update to prevent double-spend exploit
    // Update UI state immediately, then sync to database in background
    final oldCoins = state.coins;
    final oldUnlockedThemeIds =
        List<String>.from(state.unlockedThemeIds); // Save original for rollback
    final newCoins = state.coins - theme.cost;
    final newUnlockedThemes = List<String>.from(state.unlockedThemeIds)
      ..add(themeId);

    // 1. Optimistic Update: Update UI immediately
    emit(state.copyWith(
      coins: newCoins,
      unlockedThemeIds: newUnlockedThemes,
    ));

    // 2. Perform Background Work (database sync)
    try {
      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('coins', newCoins);
      await prefs.setStringList('unlockedThemeIds', newUnlockedThemes);

      // Sync coins to Firestore
      final uid = _authService.currentUser?.uid;
      if (uid != null) {
        await _firestoreService.spendCoins(uid, theme.cost);
      }

      // Track purchase
      await _analyticsService.logPurchase(
        itemName: 'theme_${theme.name}',
        coinCost: theme.cost,
      );
    } catch (e) {
      // CRITICAL FIX: Rollback to original state (before optimistic update)
      // Must use oldUnlockedThemeIds, not state.unlockedThemeIds, because state
      // has already been updated by the optimistic emit above
      debugPrint('Error purchasing theme, rolling back: $e');
      emit(state.copyWith(
        coins: oldCoins,
        unlockedThemeIds: oldUnlockedThemeIds,
      ));
      return false;
    }

    return true;
  }

  /// Check if a theme is unlocked
  bool isThemeUnlocked(String themeId) {
    return state.unlockedThemeIds.contains(themeId);
  }

  /// Get the current theme
  GameTheme get currentTheme => state.currentTheme;
}
