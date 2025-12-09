import 'package:flutter/material.dart';

/// Central configuration for the entire app
/// Place all configurable values here for easy maintenance
class AppConfig {
  // ============================================================================
  // FIREBASE CONFIGURATION
  // ============================================================================
  
  /// Whether Firebase is successfully initialized
  /// This flag is set during app startup in main.dart
  static bool firebaseInitialized = false;
  
  /// Enable/disable Firebase features globally
  static const bool enableFirebaseAnalytics = true;
  static const bool enableFirebaseCrashlytics = true;
  
  // ============================================================================
  // LOCALIZATION CONFIGURATION
  // ============================================================================
  
  /// Supported languages
  static const List<Locale> supportedLocales = [
    Locale('en', ''), // English
    Locale('zh', ''), // Chinese (Simplified)
    Locale('km', ''), // Khmer (Cambodia)
  ];
  
  /// Default language
  static const Locale defaultLocale = Locale('en', '');
  
  /// Language names for display
  static const Map<String, String> languageNames = {
    'en': 'English',
    'zh': '中文',
    'km': 'ខ្មែរ',
  };
  
  /// Language SharedPreferences key
  static const String languagePrefsKey = 'selected_language';
  
  // ============================================================================
  // LAYOUT & UI CONFIGURATION
  // ============================================================================
  
  /// Board size configuration
  static const double boardWidthMultiplier = 0.9;
  static const double boardHeightMultiplier = 0.55;
  static const double boardContainerPadding = 4.0;
  static const double boardBorderWidth = 2.0;
  
  /// Main menu layout
  static const double mainMenuVerticalPadding = 20.0;
  static const double mainMenuHorizontalPadding = 16.0;
  
  /// Profile section
  static const double profileAvatarRadius = 24.0;
  static const double profileContainerPadding = 12.0;
  static const double profileCardRadius = 12.0;
  
  /// Button sizes
  static const double menuButtonHeight = 56.0;
  static const double menuButtonWidth = 320.0;
  static const double menuButtonBorderRadius = 12.0;
  static const double menuButtonSpacing = 12.0;
  
  /// Text sizes for main menu
  static const double titleFontSize = 32.0;
  static const double subtitleFontSize = 12.0;
  static const double buttonTextFontSize = 16.0;
  static const double profileNameFontSize = 14.0;
  static const double profileEmailFontSize = 10.0;
  
  /// Coin & Score display
  static const double coinDisplayFontSize = 20.0;
  static const double scoreDisplayFontSize = 24.0;
  
  /// Common spacing values
  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing10 = 10.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  
  /// Common padding values
  static const EdgeInsets paddingAll8 = EdgeInsets.all(8.0);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(12.0);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(16.0);
  static const EdgeInsets paddingAll20 = EdgeInsets.all(20.0);
  static const EdgeInsets paddingHorizontal16Vertical8 = EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
  static const EdgeInsets paddingHorizontal20Vertical10 = EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0);
  static const EdgeInsets paddingHorizontal20Vertical12 = EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0);
  static const EdgeInsets paddingHorizontal32Vertical12 = EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0);
  
  /// Border widths
  static const double borderWidth1 = 1.0;
  static const double borderWidth2 = 2.0;
  
  /// Border radius values
  static const double borderRadius8 = 8.0;
  static const double borderRadius12 = 12.0;
  static const double borderRadius16 = 16.0;
  static const double borderRadius20 = 20.0;
  
  /// Font sizes for various UI elements
  static const double fontSize10 = 10.0;
  static const double fontSize12 = 12.0;
  static const double fontSize13 = 13.0;
  static const double fontSize14 = 14.0;
  static const double fontSize16 = 16.0;
  static const double fontSize18 = 18.0;
  static const double fontSize20 = 20.0;
  static const double fontSize22 = 22.0;
  static const double fontSize24 = 24.0;
  static const double fontSize28 = 28.0;
  
  /// Icon sizes
  static const double iconSize14 = 14.0;
  static const double iconSize20 = 20.0;
  
  /// Container/Widget sizes
  static const double containerWidth280 = 280.0;
  static const double leaderboardRankWidth = 48.0;
  
  // ============================================================================
  // GAME CONFIGURATION
  // ============================================================================
  
  /// Grid sizes
  static const int defaultGridSize = 8;
  static const int largeGridSize = 10;
  
  /// Hand piece count
  static const int defaultHandSize = 3;
  static const int challengeHandSize = 2;
  
  /// Scoring
  static const int pointsPerBlock = 1;
  static const int pointsPerLine = 10;
  static const int comboMultiplier = 2;
  
  /// Power-up costs (in coins)
  static const int bombCost = 50;
  static const int wildPieceCost = 30;
  static const int lineClearCost = 40;
  static const int colorBombCost = 60;
  static const int shuffleCost = 35;
  
  /// Daily challenge
  static const int dailyChallengeReward = 100; // coins
  static const int dailyChallengeStars = 3;
  
  // ============================================================================
  // ANIMATION & EFFECTS CONFIGURATION
  // ============================================================================
  
  /// Animation durations (in milliseconds)
  static const int lineClearAnimationDuration = 300;
  static const int piecePlaceAnimationDuration = 150;
  static const int gameOverAnimationDuration = 500;
  static const int particleLifetime = 1000;
  
  /// Haptic feedback
  static const int shortVibrationDuration = 30;
  static const int longVibrationDuration = 100;
  static const int errorVibrationAmplitude = 255;
  
  /// Screen shake
  static const double screenShakeIntensity = 5.0;
  static const int screenShakeDuration = 200;
  
  // ============================================================================
  // COLORS & THEME
  // ============================================================================
  
  /// Primary colors
  static const Color primaryPurple = Color(0xFF9d4edd);
  static const Color goldColor = Color(0xFFFFD700);
  static const Color orangeGradientStart = Color(0xFFffd700);
  static const Color orangeGradientEnd = Color(0xFFffa500);
  
  /// Background colors
  static const Color backgroundColor = Colors.black;
  static const Color overlayColorLight = Color(0x4D000000); // 30% opacity
  static const Color overlayColorDark = Color(0x33512DA8); // purple 20% opacity
  static const Color gameBackgroundTop = Color(0xFF0f0f1a);
  static Color gameBackgroundMiddle = Colors.purple.shade900.withValues(alpha: 0.3);
  static const Color gameBackgroundBottom = Color(0xFF1a0a2e);
  
  /// Block colors (for different block types)
  static const Color filledBlockColor = Colors.blue;
  static const Color wildBlockColor = Color(0xFFFFD700);
  static const Color hoverBlockColor = Colors.greenAccent;
  static const Color breakBlockColor = Colors.red;
  
  /// UI element colors
  static const Color containerLightBackground = Color(0x1AFFFFFF); // 10% white
  static const Color containerBorderColor = Color(0x33FFFFFF); // 20% white
  
  /// Convenience aliases for common UI colors
  static const Color primaryColor = primaryPurple;
  static const Color accentColor = goldColor;
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xB3FFFFFF); // white70
  static const Color cardBackground = containerLightBackground;
  static const Color cardBorder = containerBorderColor;
  static const Color coinGradientEnd = orangeGradientEnd;
  static Color backgroundOverlay1 = Colors.black.withValues(alpha: 0.3);
  static Color backgroundOverlay2 = Colors.purple.shade900.withValues(alpha: 0.2);
  
  /// Achievement and dialog colors
  static Color achievementGradientStart = Colors.purple.shade700;
  static Color achievementGradientEnd = Colors.purple.shade900;
  static const Color achievementBorder = Color(0xFFFFE66D);
  static const Color achievementGlow = Color(0x80a855f7); // purple with opacity
  static const Color dialogBackground = Color(0xFF1a1a2e);
  static const Color gameOverColor = Color(0xFFFF6B6B);

  // ============================================================================
  // DATABASE CONFIGURATION
  // ============================================================================
  
  /// SQLite database settings
  static const String databaseName = 'blockerino_v2.db';
  static const int databaseVersion = 1;
  
  /// SharedPreferences migration flag
  static const String migrationFlag = 'migrated_to_sqlite';
  
  // ============================================================================
  // AUTHENTICATION & CLOUD SYNC
  // ============================================================================
  
  /// Cloud sync intervals (in seconds)
  static const int autoSyncInterval = 300; // 5 minutes
  static const int manualSyncCooldown = 10; // 10 seconds
  
  /// Guest player defaults
  static const String guestPlayerDisplayName = 'Guest Player';
  static const String guestPlayerPrompt = 'Tap to sign in';
  
  // ============================================================================
  // STORE & ECONOMY
  // ============================================================================
  
  /// Starting coins for new players
  static const int startingCoins = 100;
  
  /// Coin rewards
  static const int coinRewardPerLevel = 50;
  static const int coinRewardPerStar = 25;
  static const int coinRewardDailyChallenge = 100;
  
  /// Theme unlock costs
  static const int themeCostClassic = 0; // Free
  static const int themeCostNeon = 200;
  static const int themeCostNature = 300;
  static const int themeCostGalaxy = 500;
  
  // ============================================================================
  // ANALYTICS EVENT NAMES
  // ============================================================================
  
  /// Custom analytics events (non-reserved names)
  static const String eventGameStart = 'game_start';
  static const String eventGameEnd = 'game_end';
  static const String eventGameComplete = 'game_complete';
  static const String eventLevelComplete = 'level_complete';
  static const String eventStorePurchase = 'store_purchase'; // Changed from in_app_purchase
  static const String eventPowerUpUsed = 'power_up_used';
  static const String eventScreenView = 'screen_view';
  
  // ============================================================================
  // HELPER METHODS - Board Sizing
  // ============================================================================
  
  /// Calculate the board size based on screen dimensions
  /// This ensures the board fits properly and maintains aspect ratio
  static double getSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxWidth = screenWidth * boardWidthMultiplier;
    final maxHeight = screenHeight * boardHeightMultiplier;
    return maxWidth < maxHeight ? maxWidth : maxHeight;
  }
  
  /// Calculate the effective size (accounting for padding and borders)
  static double getEffectiveSize(BuildContext context) {
    final boardSize = getSize(context);
    return boardSize - (boardContainerPadding * 2) - (boardBorderWidth * 2);
  }
  
  /// Calculate block size for a given board size (8x8 or 10x10)
  static double getBlockSize(BuildContext context, int gridSize) {
    final effectiveSize = getEffectiveSize(context);
    return effectiveSize / gridSize;
  }
  
  // Deprecated aliases for backward compatibility (use getSize, getEffectiveSize instead)
  @Deprecated('Use getSize() instead')
  static double getBoardSize(BuildContext context) => getSize(context);
  
  @Deprecated('Use getEffectiveSize() instead')
  static double getEffectiveBoardSize(BuildContext context) => getEffectiveSize(context);
  
  /// Get power-up cost by type name
  static int getPowerUpCost(String powerUpType) {
    switch (powerUpType.toLowerCase()) {
      case 'bomb':
        return bombCost;
      case 'wildpiece':
      case 'wild_piece':
        return wildPieceCost;
      case 'lineclear':
      case 'line_clear':
        return lineClearCost;
      case 'colorbomb':
      case 'color_bomb':
        return colorBombCost;
      case 'shuffle':
        return shuffleCost;
      default:
        return 50; // Default cost
    }
  }
  
  /// Get theme cost by name
  static int getThemeCost(String themeName) {
    switch (themeName.toLowerCase()) {
      case 'classic':
        return themeCostClassic;
      case 'neon':
        return themeCostNeon;
      case 'nature':
        return themeCostNature;
      case 'galaxy':
        return themeCostGalaxy;
      default:
        return 100; // Default cost
    }
  }
}
