import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_mode.dart';
import '../providers/game_state_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/animated_background_widget.dart';
import 'game_screen.dart';
import 'story_mode_screen.dart';
import 'daily_challenge_screen.dart';
import 'store_screen.dart';
import 'leaderboard_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _analyticsLogged = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_analyticsLogged) {
      _analyticsLogged = true;
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      settings.analyticsService.logScreenView('main_menu');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          const Positioned.fill(
            child: AnimatedBackgroundWidget(),
          ),
          
          // Main content
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.purple.shade900.withOpacity(0.2),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                // User Profile Section
                _buildProfileSection(context, settings),
                
                if (!settings.authService.isAnonymous) const SizedBox(height: 20),
                
                // Title
                Text(
                  'BLOCKERINO',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '8x8 grid, break lines!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: 12),
                
                // Coins Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFffd700), Color(0xFFffa500)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFffd700).withValues(alpha: 0.3),
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
                        '${settings.coins}',
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
                
                // High Score Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'HIGH SCORE',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${settings.highScore}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: const Color(0xFFFFD700),
                              fontSize: 24,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Story Mode Button (NEW!)
                _MenuButton(
                  text: '📖 STORY MODE',
                  subtitle: 'Journey Through Challenges',
                  color: const Color(0xFF9d4edd),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StoryModeScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                
                // Daily Challenge Button (NEW!)
                _MenuButton(
                  text: '⭐ DAILY CHALLENGE',
                  subtitle: 'Complete Today\'s Quest',
                  color: const Color(0xFFffd700),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DailyChallengeScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                
                // Classic Mode Button
                _MenuButton(
                  text: 'CLASSIC MODE',
                  subtitle: '8x8 Grid • 3 Pieces',
                  color: const Color(0xFF4ECDC4),
                  onPressed: () {
                    _startGame(context, GameMode.classic);
                  },
                ),
                const SizedBox(height: 12),
                
                // Chaos Mode Button
                _MenuButton(
                  text: 'CHAOS MODE',
                  subtitle: '10x10 Grid • 5 Pieces',
                  color: const Color(0xFFFF6B6B),
                  onPressed: () {
                    _startGame(context, GameMode.chaos);
                  },
                ),
                const SizedBox(height: 12),
                
                // Store Button (NEW!)
                _MenuButton(
                  text: '🏪 STORE',
                  subtitle: 'Power-Ups & Themes',
                  color: const Color(0xFF06b6d4),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StoreScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                
                // High Scores Button
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                    );
                  },
                  child: Text(
                    'LEADERBOARD',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ), // Column
          ), // Padding
        ), // SingleChildScrollView
      ), // SafeArea
    ), // Container
        ], // Stack children
      ), // Stack
    ); // Scaffold
  }

  void _startGame(BuildContext context, GameMode mode) {
    final gameState = Provider.of<GameStateProvider>(context, listen: false);
    gameState.startGame(mode);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GameScreen()),
    );
  }

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
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF9d4edd),
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
                  style: const TextStyle(
                    color: Colors.white,
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
                    color: Colors.white.withValues(alpha: 0.7),
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
                backgroundColor: const Color(0xFF9d4edd),
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
          children: [
            Text(
              text,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
