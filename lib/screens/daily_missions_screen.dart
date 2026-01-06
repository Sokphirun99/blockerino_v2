import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/daily_mission.dart';
import '../services/mission_service.dart';
import '../cubits/settings/settings_cubit.dart';
import '../widgets/mission_card.dart';
import '../widgets/shared_ui_components.dart';

/// Screen to display and manage daily missions
class DailyMissionsScreen extends StatefulWidget {
  const DailyMissionsScreen({super.key});

  @override
  State<DailyMissionsScreen> createState() => _DailyMissionsScreenState();
}

class _DailyMissionsScreenState extends State<DailyMissionsScreen>
    with WidgetsBindingObserver {
  final MissionService _missionService = MissionService();
  List<DailyMission> _missions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload missions when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _loadMissions();
    }
  }

  /// Called when screen becomes visible again (e.g., returning from game)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload missions every time screen dependencies change
    // This helps catch navigation-based returns
  }

  /// Refresh missions - called when navigating back to this screen
  void refreshMissions() {
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    setState(() {
      _loading = true;
    });

    final missions = await _missionService.getDailyMissions();

    if (mounted) {
      setState(() {
        _missions = missions;
        _loading = false;
      });
    }
  }

  Future<void> _handleClaim(DailyMission mission) async {
    final reward = await _missionService.claimReward(mission.id);

    if (reward > 0 && mounted) {
      // Mission completed - no coins, just completion
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Mission Completed! 🎉'),
          backgroundColor: const Color(0xFF4ade80),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Reload missions
      await _loadMissions();
    }
  }

  String _getTimeUntilRefresh() {
    if (_missions.isEmpty) return '';

    final expiresAt = _missions.first.expiresAt;
    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.isNegative) {
      return 'Refreshing soon...';
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    if (hours > 0) {
      return 'Refreshes in ${hours}h ${minutes}m';
    } else {
      return 'Refreshes in ${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtil(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Daily Missions',
          style: TextStyle(fontSize: responsive.fontSize(18, 22, 26)),
        ),
        backgroundColor: const Color(0xFF1a1a2e),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f0f23),
            ],
          ),
        ),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFFD700),
                ),
              )
            : Column(
                children: [
                  // Header section
                  Padding(
                    padding: EdgeInsets.all(responsive.value(20, tablet: 32)),
                    child: Column(
                      children: [
                        // Title
                        Text(
                          '🎯 DAILY MISSIONS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: responsive.fontSize(28, 36, 44),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: responsive.value(8, tablet: 12)),

                        // Subtitle
                        Text(
                          'Complete missions to earn coins!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: responsive.fontSize(14, 18, 20),
                          ),
                        ),
                        SizedBox(height: responsive.value(12, tablet: 18)),

                        // Time until refresh
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.value(16, tablet: 24),
                            vertical: responsive.value(8, tablet: 12),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer_outlined,
                                color: Color(0xFFFFD700),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getTimeUntilRefresh(),
                                style: const TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Missions list
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadMissions,
                      color: const Color(0xFFFFD700),
                      backgroundColor: const Color(0xFF1a1a2e),
                      child: _missions.isEmpty
                          ? ListView(
                              // Need ListView for RefreshIndicator to work
                              children: [
                                SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: Text(
                                      'No missions available\nPull to refresh',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.5),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _missions.length,
                              itemBuilder: (context, index) {
                                final mission = _missions[index];
                                return MissionCard(
                                  mission: mission,
                                  onClaim: _handleClaim,
                                );
                              },
                            ),
                    ),
                  ),

                  // Bottom padding for safe area
                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }
}
