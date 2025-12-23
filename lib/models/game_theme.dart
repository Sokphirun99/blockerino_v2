import 'package:flutter/material.dart';

/// Premium visual theme for the game
/// Each theme defines block colors, background, and visual style
class GameTheme {
  final String id;
  final String name;
  final String description;
  final List<Color> blockColors;
  final Color backgroundColor;
  final Color boardColor;
  final Color emptyBlockColor;
  final int cost; // 0 = free
  final bool hasPatterns; // For accessibility (colorblind mode)
  final GradientStyle gradientStyle;

  const GameTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.blockColors,
    required this.backgroundColor,
    required this.boardColor,
    required this.emptyBlockColor,
    this.cost = 0,
    this.hasPatterns = false,
    this.gradientStyle = GradientStyle.jewel,
  });

  /// Get a gradient for a block color
  LinearGradient getBlockGradient(Color color) {
    switch (gradientStyle) {
      case GradientStyle.jewel:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _lighten(color, 0.3),
            color,
            _darken(color, 0.25),
          ],
          stops: const [0.0, 0.45, 1.0],
        );
      case GradientStyle.neon:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _lighten(color, 0.4),
            color,
            _darken(color, 0.1),
          ],
          stops: const [0.0, 0.5, 1.0],
        );
      case GradientStyle.soft:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _lighten(color, 0.15),
            color,
            _darken(color, 0.1),
          ],
          stops: const [0.0, 0.5, 1.0],
        );
      case GradientStyle.flat:
        return LinearGradient(
          colors: [color, color],
        );
    }
  }

  /// Get glow shadow for placed blocks
  List<BoxShadow> getBlockGlow(Color color, {double intensity = 1.0}) {
    return [
      // Bottom shadow for depth
      BoxShadow(
        color: _darken(color, 0.4).withValues(alpha: 0.6 * intensity),
        offset: const Offset(0, 2),
        blurRadius: 3,
      ),
      // Top highlight
      BoxShadow(
        color: _lighten(color, 0.4).withValues(alpha: 0.3 * intensity),
        offset: const Offset(0, -1),
        blurRadius: 2,
      ),
    ];
  }

  /// Get neon glow for combo/special effects
  List<BoxShadow> getNeonGlow(Color color, {double intensity = 1.0}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.8 * intensity),
        blurRadius: 12,
        spreadRadius: 2,
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.4 * intensity),
        blurRadius: 6,
        spreadRadius: 1,
      ),
    ];
  }

  /// Get background gradient
  LinearGradient getBackgroundGradient() {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        backgroundColor,
        _darken(backgroundColor, 0.2),
        boardColor.withValues(alpha: 0.3),
        _darken(backgroundColor, 0.3),
      ],
      stops: const [0.0, 0.3, 0.6, 1.0],
    );
  }

  Color _lighten(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  // ============================================================================
  // PREDEFINED THEMES
  // ============================================================================

  /// Classic theme - Original vibrant colors
  static const GameTheme classic = GameTheme(
    id: 'classic',
    name: 'Classic',
    description: 'The original vibrant block colors',
    blockColors: [
      Color(0xFFFF4757), // Vibrant Red
      Color(0xFF1E90FF), // Dodger Blue
      Color(0xFF2ED573), // Bright Green
      Color(0xFFFFD700), // Gold
      Color(0xFFFF6348), // Coral Orange
      Color(0xFF9B59B6), // Royal Purple
      Color(0xFF00D2D3), // Cyan
      Color(0xFFFF69B4), // Hot Pink
    ],
    backgroundColor: Color(0xFF0f0f1a),
    boardColor: Color(0xFF1a1a2e),
    emptyBlockColor: Color(0xFF0f0f1e),
    cost: 0,
    gradientStyle: GradientStyle.jewel,
  );

  /// Neon Cyberpunk - Hot Pink, Cyan, Lime on Dark Purple
  static const GameTheme neonCyberpunk = GameTheme(
    id: 'neon_cyberpunk',
    name: 'Neon Cyberpunk',
    description: 'Electric neon lights on dark purple',
    blockColors: [
      Color(0xFFFF1493), // Hot Pink / Deep Pink
      Color(0xFF00FFFF), // Cyan
      Color(0xFF39FF14), // Neon Green / Lime
      Color(0xFFFFFF00), // Bright Yellow
      Color(0xFFFF6B00), // Neon Orange
      Color(0xFFBF00FF), // Electric Purple
      Color(0xFF00FF7F), // Spring Green
      Color(0xFFFF0080), // Magenta
    ],
    backgroundColor: Color(0xFF0D0221), // Deep purple-black
    boardColor: Color(0xFF1A0533), // Dark purple
    emptyBlockColor: Color(0xFF0A0118), // Near black with purple tint
    cost: 200,
    gradientStyle: GradientStyle.neon,
  );

  /// Pastel Zen - Soft calming colors on cream
  static const GameTheme pastelZen = GameTheme(
    id: 'pastel_zen',
    name: 'Pastel Zen',
    description: 'Soft, calming pastel tones',
    blockColors: [
      Color(0xFFFFB5BA), // Soft Peach/Pink
      Color(0xFF98D8AA), // Mint Green
      Color(0xFFE5B8F4), // Lavender
      Color(0xFF87CEEB), // Sky Blue
      Color(0xFFFFE5B4), // Peach
      Color(0xFFB5D8EB), // Powder Blue
      Color(0xFFFFC0CB), // Pink
      Color(0xFFB8E986), // Light Lime
    ],
    backgroundColor: Color(0xFF2D2A32), // Warm dark gray
    boardColor: Color(0xFF3D3A42), // Lighter warm gray
    emptyBlockColor: Color(0xFF252228), // Darker warm gray
    cost: 300,
    gradientStyle: GradientStyle.soft,
  );

  /// Galaxy - Cosmic deep space colors
  static const GameTheme galaxy = GameTheme(
    id: 'galaxy',
    name: 'Galaxy',
    description: 'Deep space cosmic colors',
    blockColors: [
      Color(0xFF9D4EDD), // Vivid Purple
      Color(0xFF00B4D8), // Cosmic Blue
      Color(0xFFFF006E), // Nebula Pink
      Color(0xFF8338EC), // Electric Indigo
      Color(0xFF3A86FF), // Bright Blue
      Color(0xFFFFBE0B), // Star Yellow
      Color(0xFFFB5607), // Supernova Orange
      Color(0xFF06D6A0), // Aurora Teal
    ],
    backgroundColor: Color(0xFF0B0B1A), // Deep space black
    boardColor: Color(0xFF12122B), // Dark space blue
    emptyBlockColor: Color(0xFF080814), // Pure black with blue tint
    cost: 500,
    gradientStyle: GradientStyle.jewel,
  );

  /// High Contrast - For colorblind accessibility
  static const GameTheme highContrast = GameTheme(
    id: 'high_contrast',
    name: 'High Contrast',
    description: 'Maximum visibility with patterns',
    blockColors: [
      Color(0xFFFFFFFF), // Pure White
      Color(0xFFFFFF00), // Yellow
      Color(0xFF00FFFF), // Cyan
      Color(0xFFFF00FF), // Magenta
      Color(0xFFFF8000), // Orange
      Color(0xFF00FF00), // Lime
      Color(0xFFFF0000), // Red
      Color(0xFF0080FF), // Blue
    ],
    backgroundColor: Color(0xFF000000), // Pure black
    boardColor: Color(0xFF1a1a1a), // Dark gray
    emptyBlockColor: Color(0xFF0a0a0a), // Near black
    cost: 0, // Free for accessibility
    hasPatterns: true,
    gradientStyle: GradientStyle.flat, // Flat for maximum clarity
  );

  /// Ocean Depths - Deep sea blues and teals
  static const GameTheme oceanDepths = GameTheme(
    id: 'ocean_depths',
    name: 'Ocean Depths',
    description: 'Deep sea blues and aquatic teals',
    blockColors: [
      Color(0xFF0077B6), // Ocean Blue
      Color(0xFF00B4D8), // Light Sea Blue
      Color(0xFF90E0EF), // Pale Cyan
      Color(0xFF48CAE4), // Sky Blue
      Color(0xFF023E8A), // Deep Navy
      Color(0xFF03045E), // Midnight Blue
      Color(0xFF00F5D4), // Turquoise
      Color(0xFF00A896), // Teal
    ],
    backgroundColor: Color(0xFF03071E), // Abyss black-blue
    boardColor: Color(0xFF0A1128), // Deep ocean
    emptyBlockColor: Color(0xFF02040F), // Darkest depths
    cost: 350,
    gradientStyle: GradientStyle.jewel,
  );

  /// Sunset Blaze - Warm sunset gradient colors
  static const GameTheme sunsetBlaze = GameTheme(
    id: 'sunset_blaze',
    name: 'Sunset Blaze',
    description: 'Warm sunset and fire tones',
    blockColors: [
      Color(0xFFFF4500), // Orange Red
      Color(0xFFFF6B35), // Tangerine
      Color(0xFFFFD700), // Gold
      Color(0xFFFFA500), // Orange
      Color(0xFFFF1493), // Deep Pink
      Color(0xFFDC143C), // Crimson
      Color(0xFFFF8C00), // Dark Orange
      Color(0xFFFFE4B5), // Moccasin/Light Gold
    ],
    backgroundColor: Color(0xFF1A0A0A), // Dark warm black
    boardColor: Color(0xFF2D1515), // Dark brown-red
    emptyBlockColor: Color(0xFF120808), // Near black warm
    cost: 400,
    gradientStyle: GradientStyle.jewel,
  );

  /// Forest - Natural greens and earth tones
  static const GameTheme forest = GameTheme(
    id: 'forest',
    name: 'Forest',
    description: 'Natural greens and earth tones',
    blockColors: [
      Color(0xFF228B22), // Forest Green
      Color(0xFF32CD32), // Lime Green
      Color(0xFF8B4513), // Saddle Brown
      Color(0xFFA0522D), // Sienna
      Color(0xFF6B8E23), // Olive Drab
      Color(0xFF556B2F), // Dark Olive
      Color(0xFF2E8B57), // Sea Green
      Color(0xFFDAA520), // Goldenrod
    ],
    backgroundColor: Color(0xFF0A1408), // Deep forest black
    boardColor: Color(0xFF152210), // Dark forest green
    emptyBlockColor: Color(0xFF060A04), // Near black green
    cost: 300,
    gradientStyle: GradientStyle.soft,
  );

  /// All available themes
  static const List<GameTheme> allThemes = [
    classic,
    neonCyberpunk,
    pastelZen,
    galaxy,
    highContrast,
    oceanDepths,
    sunsetBlaze,
    forest,
  ];

  /// Get theme by ID
  static GameTheme getThemeById(String id) {
    return allThemes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => classic,
    );
  }
}

/// Visual gradient style for blocks
enum GradientStyle {
  jewel, // 3D jewel-like appearance (default)
  neon, // Glowing neon effect
  soft, // Subtle soft gradients
  flat, // No gradient (for accessibility)
}

/// Pattern type for high contrast / accessibility mode
enum BlockPattern {
  none,
  stripes,
  dots,
  crosshatch,
  diagonal,
  grid,
  chevron,
  diamond,
}

/// Extension to get pattern for colorblind mode
extension BlockPatternExtension on int {
  BlockPattern get accessibilityPattern {
    switch (this % 8) {
      case 0:
        return BlockPattern.stripes;
      case 1:
        return BlockPattern.dots;
      case 2:
        return BlockPattern.crosshatch;
      case 3:
        return BlockPattern.diagonal;
      case 4:
        return BlockPattern.grid;
      case 5:
        return BlockPattern.chevron;
      case 6:
        return BlockPattern.diamond;
      case 7:
        return BlockPattern.none;
      default:
        return BlockPattern.none;
    }
  }
}

