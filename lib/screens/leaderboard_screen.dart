import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/leaderboard.dart';
import '../providers/settings_provider.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
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
      settings.analyticsService.logScreenView('leaderboard');
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
        title: const Text('Leaderboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1a1a2e),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.view_module), text: 'Classic'),
            Tab(icon: Icon(Icons.blur_on), text: 'Chaos'),
          ],
          indicatorColor: const Color(0xFF9d4edd),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a2e), Color(0xFF0f0f1e)],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildLeaderboardList('classic'),
            _buildLeaderboardList('chaos'),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardList(String gameMode) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    return StreamBuilder(
      stream: settings.firestoreService.getLeaderboard(
        gameMode: gameMode,
        limit: 100,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFF9d4edd),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading leaderboard...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading leaderboard',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.leaderboard,
                  size: 64,
                  color: Color(0xFF9d4edd),
                ),
                const SizedBox(height: 16),
                Text(
                  'No scores yet',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to set a high score!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }
        
        final docs = snapshot.data!.docs;
        final entries = docs.asMap().entries.map((entry) {
          final data = entry.value.data() as Map<String, dynamic>;
          return LeaderboardEntry(
            rank: entry.key + 1,
            playerId: data['playerId'] ?? entry.value.id,
            playerName: data['playerName'] ?? 'Anonymous',
            score: data['score'] ?? 0,
            timestamp: (data['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
            gameMode: gameMode,
          );
        }).toList();
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length + 1, // +1 for header
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildHeader();
            }
            
            final entry = entries[index - 1];
            return _buildLeaderboardCard(entry, index - 1);
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
      child: const Column(
        children: [
          Icon(Icons.emoji_events, size: 48, color: Color(0xFFffd700)),
          SizedBox(height: 8),
          Text(
            'Top Players',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Compete for the top spot!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardCard(LeaderboardEntry entry, int index) {
    final isTopThree = entry.rank <= 3;
    Color rankColor;
    IconData? medal;
    
    if (entry.rank == 1) {
      rankColor = const Color(0xFFffd700); // Gold
      medal = Icons.emoji_events;
    } else if (entry.rank == 2) {
      rankColor = const Color(0xFFc0c0c0); // Silver
      medal = Icons.military_tech;
    } else if (entry.rank == 3) {
      rankColor = const Color(0xFFcd7f32); // Bronze
      medal = Icons.workspace_premium;
    } else {
      rankColor = const Color(0xFF9d4edd);
      medal = null;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isTopThree
              ? [rankColor.withValues(alpha: 0.3), rankColor.withValues(alpha: 0.1)]
              : [const Color(0xFF2d2d44).withValues(alpha: 0.5), const Color(0xFF1a1a2e).withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTopThree ? rankColor : const Color(0xFF9d4edd).withValues(alpha: 0.3),
          width: isTopThree ? 2 : 1,
        ),
        boxShadow: isTopThree
            ? [
                BoxShadow(
                  color: rankColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: rankColor, width: 2),
            ),
            child: Center(
              child: medal != null
                  ? Icon(medal, color: rankColor, size: 24)
                  : Text(
                      '${entry.rank}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: rankColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.playerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getTimeAgo(entry.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF9d4edd).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${entry.score}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
