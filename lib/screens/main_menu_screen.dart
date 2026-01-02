import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../config/app_config.dart';
import '../models/game_mode.dart';
import '../cubits/game/game_cubit.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';
import '../services/app_localizations.dart';
import '../widgets/animated_background_widget.dart';
import '../widgets/banner_ad_widget.dart';
import '../services/admob_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'game_screen.dart';
import 'daily_missions_screen.dart';
// DISABLED: Hidden features
// import 'story_mode_screen.dart';
// import 'daily_challenge_screen.dart';
// import 'leaderboard_screen.dart';
// import 'store_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _analyticsLogged = false;
  final AdMobService _adService = AdMobService();

  @override
  void dispose() {
    _adService.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_analyticsLogged) {
      _analyticsLogged = true;
      final settingsCubit = context.read<SettingsCubit>();
      settingsCubit.analyticsService.logScreenView('main_menu');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppConfig
          .backgroundOverlay2, // Set scaffold background to match gradient end color
      body: Stack(
        children: [
          // Animated background
          const Positioned.fill(
            child: AnimatedBackgroundWidget(),
          ),

          // Main content with gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppConfig.backgroundOverlay1,
                    AppConfig.backgroundOverlay2,
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Scrollable content
                    Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom -
                                  (AppConfig.mainMenuVerticalPadding * 2) -
                                  AdSize.banner.height
                                      .toDouble() - // Reserve space for ad
                                  16, // Padding
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppConfig.mainMenuVerticalPadding),
                        child: BlocBuilder<SettingsCubit, SettingsState>(
                          builder: (context, settingsState) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                              children: [
                                // Title
                                Text(
                                  localizations.appName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayMedium
                                      ?.copyWith(
                                        color: AppConfig.textPrimary,
                                        fontSize: 32,
                                        letterSpacing: 2,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  localizations.appTagline,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppConfig.textSecondary,
                                        fontSize: 12,
                                      ),
                                ),
                                const SizedBox(height: 32),

                                // DISABLED: Coins Display
                                /*
                                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppConfig.accentColor, AppConfig.coinGradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppConfig.accentColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        '${settingsState.coins}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                */

                                // High Score Display
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppConfig.cardBackground,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: AppConfig.cardBorder),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                              localizations
                                                  .translate('high_score'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                    color:
                                                        AppConfig.textSecondary,
                                              fontSize: 10,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${settingsState.highScore}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                                    color:
                                                        AppConfig.accentColor,
                                              fontSize: 24,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 40),

                                // DISABLED: Story Mode Button
                                /*
                                _MenuButton(
                  text: '📖 ${localizations.translate('story_mode')}',
                  subtitle: localizations.translate('story_subtitle'),
                  color: const Color(0xFF9d4edd),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StoryModeScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                */

                                // DISABLED: Daily Challenge Button
                                /*
                                _MenuButton(
                  text: '⭐ ${localizations.translate('daily_challenge')}',
                  subtitle: localizations.translate('daily_subtitle'),
                  color: const Color(0xFFffd700),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DailyChallengeScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                */

                                // Classic Mode Button
                                _MenuButton(
                                  text: localizations.classicMode,
                                  subtitle: localizations
                                      .translate('classic_subtitle'),
                                  color: const Color(0xFF4ECDC4),
                                  onPressed: () {
                                    _startGame(context, GameMode.classic);
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Chaos Mode Button
                                _MenuButton(
                                  text: localizations.chaosMode,
                                        subtitle: localizations
                                            .translate('chaos_subtitle'),
                                  color: const Color(0xFFFF6B6B),
                                  onPressed: () {
                                    _startGame(context, GameMode.chaos);
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Daily Missions Button
                                _MenuButton(
                                  text: '🎯 ${localizations.translate('daily_missions')}',
                                  subtitle: localizations.translate('daily_missions_subtitle'),
                                  color: const Color(0xFFFFD700),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const DailyMissionsScreen()),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),

                                // DISABLED: Store Button
                                /*
                                _MenuButton(
                  text: '🏪 ${localizations.translate('store')}',
                  subtitle: localizations.translate('store_subtitle'),
                  color: const Color(0xFF06b6d4),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StoreScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                */

                                // DISABLED: Leaderboard Button
                                /*
                                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                    );
                  },
                  child: Text(
                    localizations.translate('leaderboard'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppConfig.textSecondary,
                          fontSize: 12,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                */

                                // DISABLED: Settings button (not yet ready for use)
                                /*
                                _MenuButton(
                  text: localizations.translate('settings'),
                  icon: Icons.settings,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                  gradient: LinearGradient(
                    colors: [
                      AppConfig.cardBackground.withOpacity(0.3),
                      AppConfig.cardBackground.withOpacity(0.1),
                    ],
                  ),
                ),
                */

                                const SizedBox(height: 40),
                              ],
                            ); // Column
                          }, // BlocBuilder builder
                        ), // BlocBuilder
                      ), // Container
                    ), // ConstrainedBox
                  ), // SingleChildScrollView
                ), // Center
                    ), // Expanded

                    // Banner ad at the bottom (always visible)
                    // ✅ Use responsive sizing - BannerAdWidget handles its own height
                    BannerAdWidget(
                      adService: _adService,
                      adSize: AdSize.banner, // Standard banner, but widget will make it responsive
                    ),
                  ],
                ), // Column
              ), // SafeArea
            ), // Container
          ), // Positioned.fill
        ], // Stack children
      ), // Stack
    ); // Scaffold
  }

  void _startGame(BuildContext context, GameMode mode) {
    final gameCubit = context.read<GameCubit>();

    // Always call startGame - it will auto-resume if there's a saved game for this mode
    gameCubit.startGame(mode);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GameScreen()),
    );
  }

  // DISABLED: Guest Player Profile Section (Not yet in use)
  /*
  Widget _buildProfileSection(BuildContext context, SettingsProvider settings) {
    final authService = settings.authService;
    final isAnonymous = authService.isAnonymous;
    final displayName = authService.displayName;
    final photoURL = authService.photoURL;

    // // Hide profile section for guest players
    // if (isAnonymous) {
    //   return const SizedBox.shrink();
    // }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConfig.cardBackground,
        borderRadius: BorderRadius.circular(AppConfig.profileCardRadius),
        border: Border.all(color: AppConfig.cardBorder),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AppConfig.primaryColor,
            backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
            child: photoURL == null
                ? Text(
                    isAnonymous ? '👤' : (displayName?[0] ?? '?'),
                    style: const TextStyle(fontSize: 20),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAnonymous ? 'Guest Player' : displayName ?? 'Player',
                  style: TextStyle(
                    color: AppConfig.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  isAnonymous ? 'Tap to sign in' : authService.email ?? '',
                  style: TextStyle(
                    color: AppConfig.textSecondary,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          // Sign In/Out Button
          if (isAnonymous)
            ElevatedButton(
              onPressed: () => _showSignInDialog(context, settings),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Sign In', style: TextStyle(fontSize: 12)),
            )
          else
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
              onPressed: () => _showSignOutDialog(context, settings),
            ),
        ],
      ),
    );
  }
  */

  // DISABLED: Sign In Dialog (Not yet in use)
  /*
  void _showSignInDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'Sign In',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sign in to sync your progress across devices and compete on the global leaderboard!',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final success = await settings.authService.linkAnonymousWithGoogle();
                if (context.mounted) {
                  if (success != null) {
                    settings.analyticsService.logSignIn('google');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Successfully signed in with Google!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sign in cancelled'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.login, size: 20),
              label: const Text('Sign in with Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }
  */

  // DISABLED: Sign Out Dialog (Not yet in use)
  /*
  void _showSignOutDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to sign out? Your progress is synced to the cloud.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await settings.authService.signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Signed out successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
  */
}

class _MenuButton extends StatelessWidget {
  final String text;
  final String subtitle;
  final Color color;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.text,
    required this.subtitle,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              text,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
