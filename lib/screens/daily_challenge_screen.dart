import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../models/daily_challenge.dart';
import '../models/game_mode.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';
import 'game_screen.dart';
import '../widgets/common_card_widget.dart';
import '../widgets/shared_ui_components.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  bool _analyticsLogged = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_analyticsLogged) {
      _analyticsLogged = true;
      final settings = context.read<SettingsCubit>();
      settings.analyticsService.logScreenView('daily_challenge');
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayChallenge = DailyChallenge.generateForDate(today);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Challenge',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1a1a2e),
      ),
      body: GameGradientBackground(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            final settings = context.read<SettingsCubit>();
            final isCompleted =
                settings.isChallengeCompleted(todayChallenge.id);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Timer countdown to next challenge
                  _buildCountdownTimer(today),
                  const Gap(24),

                  // Today's challenge card
                  _buildChallengeCard(
                      context, todayChallenge, isCompleted, settings),

                  const Gap(24),

                  // Previous challenges (last 3 days)
                  _buildPreviousChallenges(context, today, settings),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCountdownTimer(DateTime today) {
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final timeUntil = tomorrow.difference(today);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9d4edd), Color(0xFF7b2cbf)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9d4edd).withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.timer, size: 48, color: Colors.white),
          const Gap(8),
          const Text(
            'New Challenge In',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(4),
          AutoSizeText(
            '${timeUntil.inHours}h ${timeUntil.inMinutes % 60}m',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(BuildContext context, DailyChallenge challenge,
      bool isCompleted, SettingsCubit settings) {
    return GradientCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      gradientColors: isCompleted
          ? [
              const Color(0xFF52b788).withValues(alpha: 0.3),
              const Color(0xFF40916c).withValues(alpha: 0.3)
            ]
          : [
              const Color(0xFF2d2d44).withValues(alpha: 0.8),
              const Color(0xFF1a1a2e).withValues(alpha: 0.9)
            ],
      borderColor:
          isCompleted ? const Color(0xFF52b788) : const Color(0xFF9d4edd),
      borderWidth: 2,
      boxShadow: [
        BoxShadow(
          color:
              (isCompleted ? const Color(0xFF52b788) : const Color(0xFF9d4edd))
                  .withValues(alpha: 0.3),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AutoSizeText(
                  challenge.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                ),
              ),
              if (isCompleted)
                const Icon(Icons.check_circle,
                    color: Color(0xFF52b788), size: 32),
            ],
          ),
          const Gap(12),
          Text(
            challenge.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const Gap(16),
          _buildChallengeInfo('Mode',
              challenge.gameMode == GameMode.classic ? 'Classic' : 'Chaos'),
          _buildChallengeInfo('Target', _getTargetText(challenge)),
          const Gap(16),
          Row(
            children: [
              const Text('🪙', style: TextStyle(fontSize: 14)),
              const Gap(2),
              AutoSizeText(
                '${challenge.rewardCoins}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFffd700),
                ),
              ),
              const Spacer(),
              if (!isCompleted)
                Builder(
                  builder: (context) {
                    final responsive = ResponsiveUtil(context);
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GameScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9d4edd),
                        foregroundColor: Colors.white,
                        padding: responsive.horizontalPadding(mobile: 16),
                        minimumSize: Size(
                          responsive.isMobile
                              ? 60
                              : responsive.isTablet
                                  ? 80
                                  : 100,
                          responsive.isMobile
                              ? 30
                              : responsive.isTablet
                                  ? 36
                                  : 42,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        'START',
                        style: TextStyle(
                          fontSize: responsive.fontSize(12, 14, 16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              if (isCompleted)
                Builder(
                  builder: (context) {
                    final responsive = ResponsiveUtil(context);
                    return Container(
                      padding: responsive.horizontalPadding(mobile: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF52b788),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'COMPLETED',
                        style: TextStyle(
                          fontSize: responsive.fontSize(12, 14, 16),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          Expanded(
            child: AutoSizeText(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              minFontSize: 10,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getTargetText(DailyChallenge challenge) {
    switch (challenge.type) {
      case ChallengeType.clearLines:
        return 'Clear ${challenge.targetValue} lines';
      case ChallengeType.reachScore:
        return 'Score ${challenge.targetValue} points';
      case ChallengeType.useNoPowerUps:
        return 'No power-ups allowed';
      case ChallengeType.timeTrial:
        return 'Complete in ${challenge.targetValue}s';
      case ChallengeType.perfectStreak:
        return '${challenge.targetValue} perfect lines';
      case ChallengeType.comboChain:
        return 'x${challenge.targetValue} combo';
    }
  }

  Widget _buildPreviousChallenges(
      BuildContext context, DateTime today, SettingsCubit settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Previous Challenges',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(3, (index) {
          final date = today.subtract(Duration(days: index + 1));
          final challenge = DailyChallenge.generateForDate(date);
          final isCompleted = settings.isChallengeCompleted(challenge.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSmallChallengeCard(challenge, isCompleted, date),
          );
        }),
      ],
    );
  }

  Widget _buildSmallChallengeCard(
      DailyChallenge challenge, bool isCompleted, DateTime date) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2d2d44).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF52b788).withValues(alpha: 0.3)
              : const Color(0xFF9d4edd).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${date.month}/${date.day}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const Gap(4),
              Text(
                challenge.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isCompleted)
            const Icon(Icons.check_circle, color: Color(0xFF52b788), size: 24)
          else
            Icon(Icons.lock,
                color: Colors.white.withValues(alpha: 0.3), size: 24),
        ],
      ),
    );
  }
}
