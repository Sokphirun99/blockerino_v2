import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../models/power_up.dart';
import '../models/theme.dart';
import '../providers/settings_provider.dart';
import '../widgets/common_card_widget.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _analyticsLogged = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_analyticsLogged) {
      _analyticsLogged = true;
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      settings.analyticsService.logScreenView('store');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppConfig.dialogBackground,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.flash_on), text: 'Power-Ups'),
            Tab(icon: Icon(Icons.palette), text: 'Themes'),
          ],
          indicatorColor: AppConfig.primaryColor,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppConfig.dialogBackground, AppConfig.gameBackgroundTop],
          ),
        ),
        child: Column(
          children: [
            _buildCoinDisplay(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPowerUpsTab(),
                  _buildThemesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinDisplay() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppConfig.accentColor, AppConfig.coinGradientEnd],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppConfig.accentColor.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🪙', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                '${settings.coins}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPowerUpsTab() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: PowerUp.allPowerUps.length,
          itemBuilder: (context, index) {
            final powerUp = PowerUp.allPowerUps[index];
            final count = settings.getPowerUpCount(powerUp.type);
            
            return _buildPowerUpCard(powerUp, count, settings);
          },
        );
      },
    );
  }

  Widget _buildPowerUpCard(PowerUp powerUp, int count, SettingsProvider settings) {
    return GradientCard(
      gradientColors: [
        AppConfig.cardBackground,
        AppConfig.dialogBackground,
      ],
      borderColor: AppConfig.primaryColor.withValues(alpha: 0.3),
      boxShadow: [
        BoxShadow(
          color: AppConfig.primaryColor.withValues(alpha: 0.2),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(powerUp.icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(
            powerUp.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            powerUp.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF9d4edd).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Owned: $count',
                style: TextStyle(color: AppConfig.textPrimary, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              final success = await settings.buyPowerUp(powerUp.type);
              if (!mounted) return;
              
              if (success) {
                // Track purchase analytics
                settings.analyticsService.logPurchase(
                  itemName: powerUp.name,
                  coinCost: powerUp.cost,
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${powerUp.name} purchased!'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Not enough coins!'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.primaryColor,
              foregroundColor: AppConfig.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text('${powerUp.cost}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemesTab() {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: GameTheme.allThemes.length,
          itemBuilder: (context, index) {
            final theme = GameTheme.allThemes[index];
            final isUnlocked = settings.isThemeUnlocked(theme.id);
            final isCurrent = settings.currentThemeId == theme.id;
            
            return _buildThemeCard(theme, isUnlocked, isCurrent, settings);
          },
        );
      },
    );
  }

  Widget _buildThemeCard(GameTheme theme, bool isUnlocked, bool isCurrent, SettingsProvider settings) {
    return GestureDetector(
      onTap: () async {
        if (isCurrent) return;
        
        if (isUnlocked) {
          await settings.setTheme(theme.id);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Theme "${theme.name}" activated!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          final success = await settings.unlockTheme(theme.id);
          if (!mounted) return;
          
          if (success) {
            await settings.setTheme(theme.id);
            
            // Track theme purchase analytics
            settings.analyticsService.logPurchase(
              itemName: 'Theme: ${theme.name}',
              coinCost: theme.unlockCost,
            );
            
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Theme "${theme.name}" unlocked!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Not enough coins!'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: GradientCard(
        gradientColors: [
          theme.primaryColor.withValues(alpha: 0.3),
          theme.secondaryColor.withValues(alpha: 0.3),
        ],
        borderColor: isCurrent ? theme.primaryColor : theme.primaryColor.withValues(alpha: 0.3),
        borderWidth: isCurrent ? 3 : 1,
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(theme.emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text(
                  theme.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  theme.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                if (!isUnlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFffd700).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          '${theme.unlockCost}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            if (!isUnlocked)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(Icons.lock, size: 40, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
