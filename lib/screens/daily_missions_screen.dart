import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/daily_mission.dart';
import '../services/mission_service.dart';
import '../cubits/settings/settings_cubit.dart';
import '../widgets/mission_card.dart';

/// Screen to display and manage daily missions
class DailyMissionsScreen extends StatefulWidget {
  const DailyMissionsScreen({super.key});

  @override
  State<DailyMissionsScreen> createState() => _DailyMissionsScreenState();
}

class _DailyMissionsScreenState extends State<DailyMissionsScreen> {
  final MissionService _missionService = MissionService();
  List<DailyMission> _missions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
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
      // Add coins to user
      context.read<SettingsCubit>().addCoins(reward);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Claimed $reward coins! 🎉'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Missions'),
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
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Title
                        const Text(
                          '🎯 DAILY MISSIONS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          'Complete missions to earn coins!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Time until refresh
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
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
                    child: _missions.isEmpty
                        ? Center(
                            child: Text(
                              'No missions available',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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

                  // Bottom padding for safe area
                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }
}
