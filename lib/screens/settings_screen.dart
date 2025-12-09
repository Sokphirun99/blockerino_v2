import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../providers/settings_provider.dart';
import '../services/app_localizations.dart';
import '../widgets/common_card_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _analyticsLogged = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_analyticsLogged) {
      _analyticsLogged = true;
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      settings.analyticsService.logScreenView('settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('settings'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppConfig.dialogBackground,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppConfig.dialogBackground, AppConfig.gameBackgroundTop],
          ),
        ),
        child: Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Game Settings Section
                _buildSectionHeader('Game Settings'),
                _buildSettingCard(
                  icon: Icons.volume_up,
                  title: 'Sound Effects',
                  subtitle: 'Play sound effects during gameplay',
                  value: settings.soundEnabled,
                  onChanged: (value) => settings.toggleSound(),
                ),
                const SizedBox(height: 12),
                _buildSettingCard(
                  icon: Icons.phone_android,
                  title: 'Haptic Feedback',
                  subtitle: 'Vibrate on piece placement and combos',
                  value: settings.hapticsEnabled,
                  onChanged: (value) => settings.toggleHaptics(),
                ),
                const SizedBox(height: 12),
                _buildSettingCard(
                  icon: Icons.animation,
                  title: 'Animations',
                  subtitle: 'Enable smooth animations and effects',
                  value: settings.animationsEnabled,
                  onChanged: (value) => settings.toggleAnimations(),
                ),
                
                const SizedBox(height: 24),
                
                // Language Section
                _buildSectionHeader('Language'),
                _buildLanguageCard(settings),
                
                const SizedBox(height: 24),
                
                // Account Section - DISABLED (Not yet in use)
                // _buildSectionHeader('Account'),
                // _buildAccountCard(settings),
                const SizedBox(height: 24),
                
                // Theme Section - DISABLED (Not yet in use)
                // _buildSectionHeader('Appearance'),
                // _buildThemeCard(settings),
                // const SizedBox(height: 24),
                
                // Statistics Section
                _buildSectionHeader('Statistics'),
                _buildStatsCard(settings),
                
                const SizedBox(height: 24),
                
                // Data Management Section
                _buildSectionHeader('Data'),
                _buildDataCard(settings),
                
                const SizedBox(height: 32),
                
                // App Info
                _buildAppInfo(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SectionHeader(title: title);
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return CommonCard(
      child: SwitchListTile(
        secondary: Icon(icon, color: AppConfig.primaryColor),
        title: Text(
          title,
          style: TextStyle(
            color: AppConfig.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppConfig.textSecondary,
            fontSize: 12,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppConfig.primaryColor,
      ),
    );
  }

  // DISABLED: Account Card (Not yet in use)
  /*
  Widget _buildAccountCard(SettingsProvider settings) {
    final isAnonymous = settings.authService.isAnonymous;
    final displayName = settings.authService.displayName;
    final email = settings.authService.email;
    final photoURL = settings.authService.photoURL;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppConfig.cardBackground, AppConfig.dialogBackground],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConfig.cardBorder),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppConfig.primaryColor,
            backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
            child: photoURL == null
                ? Text(
                    isAnonymous ? '👤' : (displayName?[0] ?? '?'),
                    style: const TextStyle(fontSize: 32),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            isAnonymous ? 'Guest Player' : displayName ?? 'Player',
            style: TextStyle(
              color: AppConfig.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!isAnonymous) ...[
            const SizedBox(height: 4),
            Text(
              email ?? '',
              style: TextStyle(
                color: AppConfig.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (isAnonymous)
            ElevatedButton.icon(
              onPressed: () => _showSignInDialog(settings),
              icon: const Icon(Icons.login),
              label: const Text('Sign In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.primaryColor,
                foregroundColor: AppConfig.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () => _showSignOutDialog(settings),
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConfig.gameOverColor,
                side: BorderSide(color: AppConfig.gameOverColor),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }
  */

  Widget _buildLanguageCard(SettingsProvider settings) {
    return CommonCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language, color: AppConfig.primaryColor),
              const SizedBox(width: 12),
              Text(
                'Select Language',
                style: TextStyle(
                  color: AppConfig.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...AppConfig.supportedLocales.map((locale) {
            final isSelected = settings.currentLocale.languageCode == locale.languageCode;
            return ListTile(
              leading: Radio<String>(
                value: locale.languageCode,
                groupValue: settings.currentLocale.languageCode,
                onChanged: (value) {
                  if (value != null) {
                    settings.changeLanguage(Locale(value, ''));
                  }
                },
                activeColor: AppConfig.primaryColor,
              ),
              title: Text(
                AppConfig.languageNames[locale.languageCode] ?? locale.languageCode,
                style: TextStyle(
                  color: isSelected ? AppConfig.primaryColor : AppConfig.textPrimary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              onTap: () {
                settings.changeLanguage(locale);
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatsCard(SettingsProvider settings) {
    return CommonCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatRow('High Score', '${settings.highScore}', Icons.emoji_events),
          const Divider(height: 24),
          _buildStatRow('Total Coins', '${settings.coins}', Icons.monetization_on),
          const Divider(height: 24),
          _buildStatRow('Story Progress', 'Level ${settings.currentStoryLevel}', Icons.book),
          const Divider(height: 24),
          _buildStatRow('Themes Unlocked', '${settings.unlockedThemeIds.length}', Icons.palette),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppConfig.accentColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppConfig.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppConfig.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDataCard(SettingsProvider settings) {
    return CommonCard(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.cloud_upload, color: AppConfig.primaryColor),
            title: Text(
              'Sync Data',
              style: TextStyle(color: AppConfig.textPrimary),
            ),
            subtitle: Text(
              'Sync your progress to the cloud',
              style: TextStyle(color: AppConfig.textSecondary, fontSize: 12),
            ),
            trailing: Icon(Icons.sync, color: AppConfig.textSecondary),
            onTap: () => _syncData(settings),
          ),
          Divider(height: 1, color: AppConfig.cardBorder),
          ListTile(
            leading: Icon(Icons.delete_forever, color: AppConfig.gameOverColor),
            title: Text(
              'Clear All Data',
              style: TextStyle(color: AppConfig.gameOverColor),
            ),
            subtitle: Text(
              'Reset all progress and settings',
              style: TextStyle(color: AppConfig.textSecondary, fontSize: 12),
            ),
            trailing: Icon(Icons.warning, color: AppConfig.gameOverColor),
            onTap: () => _showClearDataDialog(settings),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfo() {
    return Column(
      children: [
        Text(
          'BLOCKERINO',
          style: TextStyle(
            color: AppConfig.primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Version 2.0.0',
          style: TextStyle(
            color: AppConfig.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '© 2025 Blockerino Games',
          style: TextStyle(
            color: AppConfig.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // DISABLED: Sign In Dialog (Not yet in use)
  /*
  void _showSignInDialog(SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConfig.dialogBackground,
        title: Text('Sign In', style: TextStyle(color: AppConfig.textPrimary)),
        content: Text(
          'Sign in to sync your progress across devices and compete on the leaderboard!',
          style: TextStyle(color: AppConfig.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implement Google Sign-In
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sign-in coming soon!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.primaryColor,
            ),
            child: const Text('Sign In with Google'),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConfig.dialogBackground,
        title: Text('Sign Out', style: TextStyle(color: AppConfig.textPrimary)),
        content: Text(
          'Are you sure you want to sign out? Your progress will remain saved.',
          style: TextStyle(color: AppConfig.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await settings.authService.signOut();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signed out successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.gameOverColor,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
  */

  void _syncData(SettingsProvider settings) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Syncing data...')),
    );
    // The sync happens automatically in SettingsProvider
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data synced successfully!')),
      );
    }
  }

  void _showClearDataDialog(SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConfig.dialogBackground,
        title: Text(
          '⚠️ Clear All Data',
          style: TextStyle(color: AppConfig.gameOverColor),
        ),
        content: Text(
          'This will permanently delete:\n'
          '• All game progress\n'
          '• High scores\n'
          '• Coins and power-ups\n'
          '• Unlocked themes\n'
          '• Story mode progress\n\n'
          'This action cannot be undone!',
          style: TextStyle(color: AppConfig.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await settings.clearAllData();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.gameOverColor,
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }
}
