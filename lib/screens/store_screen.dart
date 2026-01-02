import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../config/app_config.dart';
import '../models/power_up.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';
import '../widgets/common_card_widget.dart';
import '../widgets/shared_ui_components.dart';

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
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_analyticsLogged) {
      _analyticsLogged = true;
      final settings = context.read<SettingsCubit>();
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
          ],
          indicatorColor: AppConfig.primaryColor,
        ),
      ),
      body: GameGradientBackground(
        child: Column(
          children: [
            _buildCoinDisplay(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPowerUpsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinDisplay() {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return Container(
          margin: const EdgeInsets.all(16),
          child: CoinDisplay(coins: state.coins),
        );
      },
    );
  }

  Widget _buildPowerUpsTab() {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final settings = context.read<SettingsCubit>();
        // Responsive grid: 2 columns on phones, 3 on tablets
        final screenWidth = MediaQuery.of(context).size.width;
        final crossAxisCount = screenWidth > 600 ? 3 : 2;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: PowerUp.allPowerUps.length,
          itemBuilder: (context, index) {
            final powerUp = PowerUp.allPowerUps[index];
            final count = state.powerUpInventory[powerUp.type] ?? 0;
            
            return _buildPowerUpCard(powerUp, count, settings);
          },
        );
      },
    );
  }

  Widget _buildPowerUpCard(PowerUp powerUp, int count, SettingsCubit settings) {
    return GradientCard(
      gradientColors: const [
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
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
                style: const TextStyle(color: AppConfig.textPrimary, fontWeight: FontWeight.bold),
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
                
                SharedSnackBars.showSuccess(context, '${powerUp.name} purchased!');
              } else {
                SharedSnackBars.showNotEnoughCoins(context);
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
                const Text('🪙', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 2),
                Text(
                    '${powerUp.cost}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
